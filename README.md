# Monadic Validation in Gleam!

You might currently be defaulting on a form of validation that isn't giving you
every error. Let's take for example, loading environment variables.

We might start with some types defined to load our Env into.

```gleam
import gleam/erlang/os

pub type DbUser {
  DbUser(value: String)
}

pub type DbPassword {
  DbPassword(value: String)
}

pub type Env {
  Env(db_user: DbUser, db_password: DbPassword)
}
```

And define a useful helper to give us a a precise error message when we can't find an env variable.

```gleam
fn get_env_var(var_name: String) -> Result(String, String) {
  case os.get_env(var_name) {
    Ok(var) -> Ok(var)
    Error(_) -> Error("Could not find env variable:" <> var_name)
  }
}
```

But the typical way of composing this will only yield a single error message
, even if both variables are missing

```gleam
pub fn load_env () -> Result(String, String) {
  use db_user <- result.try(
    get_env_var("DB_USER")
    |> result.map(DbUser)
  )

  use db_password <- result.try(
     get_env_var("DB_PASSWORD")
     |> result.map(DbPassword)
  )

  Env(
    db_user: db_user,
    db_password: db_password,
  )
  |> Ok
}
```

Suppose we try starting the app without "DB_USER".
We will see an error that it is missing, correct
the error, then attempt to start the app only to
recieve the next error in line! We should have returned
them both the first time.

With `validate_monadic`, this is a small rewrite to fix. First
the utility function must be adjusted.

```gleam
import validate_monadic.{type Validation} as validate

fn get_env_var(var_name: String) -> Validation(String, String) {
  case os.get_env(var_name) {
    Ok(var) -> validate.succeed(var)
    Error(_) -> validate.error("Failed to find env variable: " <> var_name)
  }
}
```

Now we can write an improved `load_env` function

````gleam
import validate_monadic.{type Validation} as validate
import gleam/function

pub fn load_env () -> Validation(Env, String) {
  let db_user =
    get_env_var("db_user")
    |> validate.map(DbUser)

  let db_password =
    get_env_var("db_password")
    |> validate.map(DbPassword)

  Env
  |> function.curry2
  |> validate.map(db_user, _)
  |> validate.and_map(db_password)
}

# Installation

```sh
gleam add validate_monadic
````

```gleam
import validate_monadic as validate
```

# Usage

This module is the minimal set of functions around a single type alias for `Result` so it may
be used as a "validation monad".

The `/examples` folder contains two examples for full usage of this module, using
every method contained in it.

[Checkout out the examples here](https://github.com/abradley2/gleam-validate/tree/master/examples/src)

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```
