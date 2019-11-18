defmodule EctoEnsureMigrations.StatementSplitter do
  defmodule Stacks do
    @type t :: %__MODULE__{
            dollar: boolean,
            parantheses: non_neg_integer,
            brackets: non_neg_integer,
            braces: non_neg_integer,
            quote: nil | binary,
            escape: boolean
          }
    defstruct dollar: false,
              parantheses: 0,
              brackets: 0,
              braces: 0,
              quote: nil,
              escape: false
  end

  @doc """
  Splits a string that contains multiple statements into a list of strings that only contain one statement each.

  ### Examples

  iex> EctoEnsureMigrations.StatementSplitter.split_statements("A; B")
  ["A;", "B"]
  """
  @spec split_statements(
          input :: binary,
          stm_acc :: binary,
          res_acc :: list(binary),
          stacks :: __MODULE__.Stacks.t()
        ) :: list(binary)
  def split_statements(input, stm_acc \\ "", res_acc \\ [], stacks \\ %__MODULE__.Stacks{})

  def split_statements("\\" <> rest, stm_acc, res_acc, %{escape: false} = stacks) do
    stm_acc = stm_acc <> "\\"
    stacks = %{stacks | escape: true}
    split_statements(rest, stm_acc, res_acc, stacks)
  end

  def split_statements("'" <> rest, stm_acc, res_acc, %{quote: nil} = stacks) do
    stm_acc = stm_acc <> "'"
    stacks = %{stacks | quote: "'"}
    split_statements(rest, stm_acc, res_acc, stacks)
  end

  def split_statements("\"" <> rest, stm_acc, res_acc, %{quote: nil} = stacks) do
    stm_acc = stm_acc <> "\""
    stacks = %{stacks | quote: "\""}
    split_statements(rest, stm_acc, res_acc, stacks)
  end

  def split_statements("'" <> rest, stm_acc, res_acc, %{quote: "'"} = stacks) do
    stm_acc = stm_acc <> "'"
    stacks = %{stacks | quote: nil}
    split_statements(rest, stm_acc, res_acc, stacks)
  end

  def split_statements("\"" <> rest, stm_acc, res_acc, %{quote: "\""} = stacks) do
    stm_acc = stm_acc <> "\""
    stacks = %{stacks | quote: nil}
    split_statements(rest, stm_acc, res_acc, stacks)
  end

  def split_statements("$$" <> rest, stm_acc, res_acc, stacks) do
    stm_acc = stm_acc <> "$$"
    stacks = Map.update!(stacks, :dollar, &Kernel.not/1)
    split_statements(rest, stm_acc, res_acc, stacks)
  end

  def split_statements("[" <> rest, stm_acc, res_acc, %{quote: nil} = stacks) do
    stm_acc = stm_acc <> "["
    stacks = Map.update!(stacks, :brackets, &(&1 + 1))
    split_statements(rest, stm_acc, res_acc, stacks)
  end

  def split_statements("(" <> rest, stm_acc, res_acc, %{quote: nil} = stacks) do
    stm_acc = stm_acc <> "("
    stacks = Map.update!(stacks, :parantheses, &(&1 + 1))
    split_statements(rest, stm_acc, res_acc, stacks)
  end

  def split_statements("{" <> rest, stm_acc, res_acc, %{quote: nil} = stacks) do
    stm_acc = stm_acc <> "{"
    stacks = Map.update!(stacks, :braces, &(&1 + 1))
    split_statements(rest, stm_acc, res_acc, stacks)
  end

  def split_statements(")" <> rest, stm_acc, res_acc, %{quote: nil} = stacks) do
    stm_acc = stm_acc <> ")"
    stacks = Map.update!(stacks, :parantheses, &(&1 - 1))
    split_statements(rest, stm_acc, res_acc, stacks)
  end

  def split_statements("]" <> rest, stm_acc, res_acc, %{quote: nil} = stacks) do
    stm_acc = stm_acc <> "]"
    stacks = Map.update!(stacks, :brackets, &(&1 - 1))
    split_statements(rest, stm_acc, res_acc, stacks)
  end

  def split_statements("}" <> rest, stm_acc, res_acc, %{quote: nil} = stacks) do
    stm_acc = stm_acc <> "}"
    stacks = Map.update!(stacks, :braces, &(&1 - 1))
    split_statements(rest, stm_acc, res_acc, stacks)
  end

  def split_statements(
        <<char::binary-1, rest::binary>>,
        stm_acc,
        res_acc,
        %{escape: true} = stacks
      ) do
    stm_acc = stm_acc <> char
    stacks = %{stacks | escape: false}
    split_statements(rest, stm_acc, res_acc, stacks)
  end

  def split_statements(
        ";" <> rest,
        stm_acc,
        res_acc,
        %{quote: nil, escape: false, parantheses: 0, brackets: 0, braces: 0, dollar: false} =
          stacks
      ) do
    res_acc = [stm_acc <> ";" | res_acc]
    split_statements(rest, "", res_acc, stacks)
  end

  def split_statements(<<letter::binary-size(1), rest::binary>>, stm_acc, res_acc, stacks) do
    split_statements(rest, stm_acc <> letter, res_acc, stacks)
  end

  def split_statements("", stm_acc, acc, _) do
    [stm_acc | acc]
    |> Enum.reverse()
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end
end
