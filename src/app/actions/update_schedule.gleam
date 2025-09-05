import config
import gleam/dict
import gleam/hackney
import gleam/http.{Get, Post}
import gleam/http/request
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/result
import model
import wisp

pub fn update_schedule(req: wisp.Request) {
  let config = config.get_config()

  // This middleware parses a `wisp.FormData` from the request body.
  // It returns an error response if the body is not valid form data, or
  // if the content-type is not `application/x-www-form-urlencoded` or
  // `multipart/form-data`, or if the body is too large.
  use formdata <- wisp.require_form(req)

  // The list and result module are used here to extract the values from the
  // form data.
  // Alternatively you could also pattern match on the list of values (they are
  // sorted into alphabetical order), or use a HTML form library.
  let result = {
    use id <- result.try(list.key_find(formdata.values, "id"))
    use festival <- result.try(list.key_find(formdata.values, "festival"))
    use year <- result.try(list.key_find(formdata.values, "year"))
    use start <- result.try(list.key_find(formdata.values, "start"))
    use end <- result.try(list.key_find(formdata.values, "end"))
    use band <- result.try(list.key_find(formdata.values, "band"))
    use stage <- result.try(list.key_find(formdata.values, "stage"))

    update_data(
      config.username,
      config.password,
      "schedule",
      festival <> "_" <> year,
      model.Event(start:, end:, band:, stage:),
      id,
    )
  }
  case result {
    Ok(_) -> {
      wisp.ok()
      |> wisp.string_body("Saved")
    }
    Error(_) -> {
      wisp.internal_server_error()
      |> wisp.string_body("Failed")
    }
  }
}

fn update_data(
  username: String,
  password: String,
  enti: String,
  festival: String,
  event: model.Event,
  id: String,
) -> Result(dict.Dict(String, model.Event), Nil) {
  let assert Ok(request) =
    request.to(
      "https://lilafestivalhub.herokuapp.com/"
      <> enti
      <> "?festival="
      <> festival,
    )
  let response =
    request
    |> request.set_method(Get)
    |> request.prepend_header("accept", "application/json")
    |> request.prepend_header(
      "Authorization",
      model.encode64_auth(username, password),
    )
    |> hackney.send
  case response {
    Ok(response) -> {
      io.println(festival <> ":" <> int.to_string(response.status))
      let assert Ok(schedule) = model.schedules_from_json(response.body)
      post_data(
        username,
        password,
        "schedule",
        festival,
        dict.upsert(schedule, id, fn(_) { event }),
      )
    }
    _err -> {
      io.print_error("Fehler beim hackney.send")
      Error(Nil)
    }
  }
}

fn post_data(
  username: String,
  password: String,
  enti: String,
  festival: String,
  data: dict.Dict(String, model.Event),
) {
  let assert Ok(request) =
    request.to(
      "https://lilafestivalhub.herokuapp.com/"
      <> enti
      <> "?festival="
      <> festival,
    )
  let response =
    request
    |> request.set_method(Post)
    |> request.prepend_header("Content-Type", "application/json")
    |> request.prepend_header(
      "Authorization",
      "Basic " <> model.encode64_auth(username, password),
    )
    |> request.set_body(model.dict_to_json(data) |> json.to_string)
    |> hackney.send
  case response {
    Ok(response) -> {
      io.println(festival <> ":" <> int.to_string(response.status))
      let assert Ok(schedule) = model.schedules_from_json(response.body)
      Ok(schedule)
    }
    _err -> {
      io.print_error("Fehler beim hackney.send")
      Error(Nil)
    }
  }
}
