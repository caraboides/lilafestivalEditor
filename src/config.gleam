import envoy
import gleam/io

pub type Config {
  Config(username: String, password: String)
}

fn read_env(name: String) -> Result(String, Nil) {
  envoy.get(name)
}

pub fn get_config() -> Config {
  let username = case read_env("USERNAME") {
    Ok(username) -> username
    Error(_) -> {
      io.print_error("USERNAME environment variable not set")
      panic
    }
  }

  let password = case read_env("PASSWORD") {
    Ok(password) -> password
    Error(_) -> {
      io.print_error("PASSWORD environment variable not set")
      panic
    }
  }

  Config(username: username, password: password)
}
