import config
import gleam/dict
import gleam/hackney
import gleam/http.{Get, Post}
import gleam/http/request
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import model
import wisp

pub fn extract_string(
  formdata: wisp.FormData,
  key: String,
  default: String,
) -> String {
  case list.key_find(formdata.values, key) {
    Ok(value) -> value
    Error(_) -> default
  }
}

pub fn update_band(req: wisp.Request) {
  let config = config.get_config()

  use formdata <- wisp.require_form(req)
  io.println("Update band with formdata#1#1")
  let update_result = {
    let id = extract_string(formdata, "id", "")
    let festival = extract_string(formdata, "festival", "")
    let year = extract_string(formdata, "year", "")
    let img_data_hash = extract_string(formdata, "img_data_hash", "")
    let img_data_width = extract_string(formdata, "img_data_width", "0")
    let img_data_height = extract_string(formdata, "img_data_height", "0")
    let logo_data_width = extract_string(formdata, "logo_data_width", "0")
    let logo_data_height = extract_string(formdata, "logo_data_height", "0")
    let img_data =
      model.Image(
        hash: img_data_hash,
        width: parse_int(img_data_width),
        height: parse_int(img_data_height),
      )
    let logo_data =
      model.Image(
        hash: "",
        width: parse_int(logo_data_width),
        height: parse_int(logo_data_height),
      )
    let img = extract_string(formdata, "img", "")
    let logo = extract_string(formdata, "logo", "")
    let roots = extract_string(formdata, "roots", "")
    let style = extract_string(formdata, "style", "")
    let origin = extract_string(formdata, "origin", "")
    let spotify = extract_string(formdata, "spotify", "")
    let cancelled = extract_string(formdata, "cancelled", "")
    let description = extract_string(formdata, "description", "")
    let description_en = extract_string(formdata, "description_en", "")
    io.println(
      "Update band " <> id <> " for festival " <> festival <> "_" <> year,
    )
    update_data(
      config.username,
      config.password,
      "bands",
      festival <> "_" <> year,
      model.Band(
        img:,
        logo:,
        roots:,
        style:,
        origin:,
        spotify:,
        img_data:,
        logo_data:,
        cancelled: parse_bool(cancelled),
        description:,
        description_en:,
      ),
      id,
    )
  }
  case update_result {
    Ok(_body) -> {
      wisp.ok()
      |> wisp.string_body("Saved")
    }
    Error(_) -> {
      wisp.internal_server_error()
      |> wisp.string_body("Failed")
    }
  }
}

fn parse_int(value: String) -> Int {
  case int.parse(value) {
    Ok(i) -> i
    Error(_) -> 0
  }
}

fn parse_bool(value: String) -> Bool {
  case value {
    "True" -> True
    _ -> False
  }
}

fn update_data(
  username: String,
  password: String,
  enti: String,
  festival: String,
  band: model.Band,
  id: String,
) -> Result(dict.Dict(String, model.Band), Nil) {
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
      let assert Ok(bands) = model.bands_from_json(response.body)
      post_data(
        username,
        password,
        enti,
        festival,
        dict.upsert(bands, id, fn(_) { band }),
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
  data: dict.Dict(String, model.Band),
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
    |> request.set_body(model.bands_to_json(data) |> json.to_string)
    |> hackney.send
  case response {
    Ok(response) -> {
      io.println(festival <> ":" <> int.to_string(response.status))
      let assert Ok(bands) = model.bands_from_json(response.body)
      Ok(bands)
    }
    _err -> {
      io.print_error("Fehler beim hackney.send")
      Error(Nil)
    }
  }
}
