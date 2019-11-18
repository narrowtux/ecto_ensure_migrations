defmodule EctoEnsureMigrations.LoadTest do
  use ExUnit.Case

  test "load files from a folder" do
    statements = EctoEnsureMigrations.load_dir("./test/sql")

    assert [
             %{
               type: :create_function,
               identifier: "split_string(source text, delimiter text)"
             },
             %{
               type: :create_cast,
               identifier: "(integer AS jsonb)"
             }
           ] = statements
  end
end
