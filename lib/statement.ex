defmodule EctoEnsureMigrations.Statement do
  @type statement_type ::
          :create_function
          | :create_cast
          | :create_operator

  @type t :: %__MODULE__{
          type: statement_type,
          ddl: binary,
          file: binary,
          identifier: binary
        }

  defstruct [
    :type,
    :ddl,
    :file,
    :identifier
  ]

  @function_head ~r/CREATE\s+(OR\s+REPLACE)?\s*FUNCTION\s+(([a-z_0-9])+\([^)]+\))/i
  @cast_head ~r/CREATE\s+CAST\s+(\([^\)]+\))/i

  @spec guess_type(binary) :: statement_type | nil
  def guess_type("CREATE OR REPLACE FUNCTION" <> _), do: :create_function
  def guess_type("CREATE FUNCTION" <> _), do: :create_function
  def guess_type("CREATE OR REPLACE CAST" <> _), do: :create_cast
  def guess_type("CREATE CAST" <> _), do: :create_cast
  def guess_type("CREATE OR REPLACE OPERATOR" <> _), do: :create_operator
  def guess_type("CREATE OPERATOR" <> _), do: :create_operator
  def guess_type(_), do: :create_function

  @spec guess_identifier(statement_type, binary) :: {:ok, binary} | :error
  def guess_identifier(:create_function, stm) do
    case Regex.run(@function_head, stm) do
      [_all, _g1, function_head, _g3] -> {:ok, function_head}
      _ -> :error
    end
  end

  def guess_identifier(:create_cast, stm) do
    case Regex.run(@cast_head, stm) do
      [_all, g1] -> {:ok, g1}
      _ -> :error
    end
  end

  def guess_identifier(:create_operator, stm) do
    :error
  end
end
