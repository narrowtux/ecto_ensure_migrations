defmodule EctoEnsureMigrations do
  @path "/repo/ensure_migrations"
  alias EctoEnsureMigrations.StatementSplitter

  def run(otp_app, repo) do
    otp_app
    |> :code.priv_dir()
    |> Path.join(@path)
    |> run_for_dir(repo)
  end

  def run_for_dir(path, repo) do
    statements = load_dir(path)

    repo.transaction(fn ->
      with {:ok, _} <- drop(statements, repo),
           {:ok, _} <- create(statements, repo) do
        :ok
      end
    end)
  end

  def load_dir(path) do
    path
    |> find_sql_files()
    |> load()
    |> split_statements()
    |> order_statements()
  end

  @spec find_sql_files(binary) :: [binary]
  def find_sql_files(path) do
    path
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".sql"))
    |> Enum.map(&Path.join(path, &1))
  end

  @spec load([binary]) :: [{file :: binary, ddl :: binary}]
  def load(files) do
    Enum.map(files, fn file ->
      {file, File.read!(file)}
    end)
  end

  @spec split_statements([{binary, binary}]) :: [__MODULE__.Statement.t()]
  def split_statements(files_with_content) do
    Enum.flat_map(files_with_content, fn {file, content} ->
      content
      |> StatementSplitter.split_statements()
      |> Enum.map(fn statement ->
        type = __MODULE__.Statement.guess_type(statement)

        ident =
          case __MODULE__.Statement.guess_identifier(type, statement) do
            {:ok, ident} -> ident
            :error -> throw("no identifier found for ddl\b#{statement}+")
          end

        %__MODULE__.Statement{
          file: file,
          ddl: statement,
          type: type,
          identifier: ident
        }
      end)
    end)
  end

  def order_statements(statements) do
    Enum.sort_by(statements, fn %{type: type} ->
      case type do
        :create_function -> 0
        :create_cast -> 1
        :create_operator -> 2
      end
    end)
  end

  def drop(statements, repo) do
    OK.map_all(statements, &drop_statement(&1, repo))
  end

  def create(statements, repo) do
    OK.map_all(statements, &create_statement(&1, repo))
  end

  def drop_statement(stm, repo) do
    drop_stm =
      case stm.type do
        :create_function -> "DROP FUNCTION IF EXISTS #{stm.identifier} CASCADE;"
        :create_cast -> "DROP CAST IF EXISTS #{stm.identifier} CASCADE;"
      end

    repo.query(drop_stm)
  end

  def create_statement(stm, repo) do
    repo.query(stm.ddl)
  end
end
