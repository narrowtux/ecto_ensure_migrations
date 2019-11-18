defmodule EctoEnsureMigrations.StatementSplitterTest do
  use ExUnit.Case
  doctest EctoEnsureMigrations.StatementSplitter
  import EctoEnsureMigrations.StatementSplitter

  test "quotes" do
    result = split_statements(~S{SELECT "abc;def" FROM foobar; SELECT 2;})

    assert result == [
             ~S{SELECT "abc;def" FROM foobar;},
             ~S{SELECT 2;}
           ]

    result = split_statements(~S{SELECT '"";""' FROM abc; SELECT (1 + 1);})

    assert result == [
             ~S{SELECT '"";""' FROM abc;},
             ~S{SELECT (1 + 1);}
           ]
  end

  test "$$ function code" do
    function_a = ~S{
      CREATE OR REPLACE FUNCTION foo_bar(foo int)
      RETURNS float
      AS $$
      BEGIN
        RETURN foo * 1.3
      END
      $$;
    }

    function_b = ~S{
      CREATE OR REPLACE FUNCTION bar()
      RETURNS boolean
      AS $$
      BEGIN
        RETURN false
      END
      $$;
    }

    result = split_statements(function_a <> function_b)

    assert result == [String.trim(function_a), String.trim(function_b)]
  end
end
