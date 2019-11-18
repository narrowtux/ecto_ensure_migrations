# EctoEnsureMigrations

A way to keep all your SQL function, cast and operator definitions in actual .sql files instead of migrations.

## The problem

Once you go more in depth with database features such as stored procedures (aka functions), user-defined casts, or operators, 
you'll get to a point where you have to maintain more than just a few functions while still using migrations. 

Using migrations with the `execute/1` function works at first, since it's simple to write, but as your project grows, some problems
might arise:

 * To find the most current definitition of a function, you have to search for `CREATE FUNCTION xyz` in your IDE and then look for the youngest migration
 * It's hard to get an overwiew of which functions you've already defined. If you work in a team this might lead to the same function being implemented twice.
 * If you want to write documentation for a SQL function, it's unclear where to do it. Documentation might end up in a file where you won't find it again.

## Trying to solve these problems

With EctoEnsureMigrations, you write all your `CREATE FUNCTION`, `CREATE CAST` and `CREATE OPERATOR` statements into normal `.sql` files in the folder `priv/repo/ensure_migrations`.

The definitions can be split into multiple files.

To run your definition statements, call `EctoEnsureMigrations.run(:my_app, MyApp.Repo)`.

This will run the following steps in a transaction:

 1. Drop all defined functions with `CASCADE` modifier so all casts depending on these will be dropped too
 2. Drop all defined casts (also with `CASCADE`)
 3. Drop all definied operators (also with `CASCADE`)
 4. Execute all `CREATE FUNCTION` statements
 5. Execute all `CREATE CAST` statements
 6. Execute all `CREATE OPERATOR` statements

## Caveats

 * Not tested with other SQL Databases than PostgreSQL.
 * A transaction is used to drop old versions of all definitions, and then recreate them. For other connections, this will look like all definitions are swapped out at once. The other advantage is that if something is wrong with your code, the transaction is simply rolled back and the definitions return to their old state. Since MySQL doesn't support transactions for schema mutations, this might lead to inconsistent states during development.
 * If you drop a function, cast or operator later during development, this library won't notice. If you do, you should also add a migration that drops it.

## Installation

The package can be installed by adding `ecto_ensure_migrations` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_ensure_migrations, "~> 0.1.0"}
  ]
end
```

<!-- Documentation can be found at [https://hexdocs.pm/ecto_ensure_migrations](https://hexdocs.pm/ecto_ensure_migrations). -->

## TODO list

 - [x] support for functions
 - [x] support for casts
 - [ ] support for operators
 - [ ] better logging
 - [ ] support subdirectories in `priv/repo/ensure_migrations`