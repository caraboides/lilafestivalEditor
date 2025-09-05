import gleam/bool
import gleam/dict
import gleam/dynamic/decode
import gleam/json

import config
import gleam/hackney
import gleam/http.{Get}
import gleam/http/request
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import model
import nakai/attr
import nakai/html

fn form_group(label: String, name: String, value: String) -> html.Node {
  html.div([attr.class("form-group row")], [
    html.label_text(
      [attr.for(name <> "input"), attr.class("col-sm-2 col-form-label")],
      label,
    ),
    html.div([attr.class("col-sm-10")], [
      html.input([
        attr.name(name),
        attr.class("form-control"),
        attr.id(name <> "input"),
        attr.value(value),
      ]),
    ]),
  ])
}

pub fn edit_bands(festival: String, year: String) {
  let config = config.get_config()

  case
    fetch_data(
      config.username,
      config.password,
      "bands",
      festival <> "_" <> year,
    )
  {
    Ok(data) -> {
      data
      |> dict.to_list
      |> list.sort(fn(a, b) {
        let #(aa, _) = a
        let #(bb, _) = b
        string.compare(aa, bb)
      })
      |> list.map(fn(entry) {
        let #(key, band) = entry
        html.form(
          [
            attr.class("container"),
            attr.Attr("hx-post", "/update/band/entry"),
            attr.Attr("hx-target", "#globalfeedback"),
          ],
          [
            // start:, end:, band:, stage:
            html.input([attr.type_("hidden"), attr.name("id"), attr.value(key)]),
            html.input([
              attr.type_("hidden"),
              attr.name("festival"),
              attr.value(festival),
            ]),
            html.input([
              attr.type_("hidden"),
              attr.name("year"),
              attr.value(year),
            ]),
            html.h6_text([], key),
            form_group("Image", "img", band.img),
            form_group("Logo", "logo", band.logo),
            form_group("Roots", "roots", band.roots),
            form_group("Style", "style", band.style),
            form_group("Origin", "origin", band.origin),
            form_group("Spotify", "spotify", band.spotify),
            form_group("Image Data Hash", "img_data_hash", band.img_data.hash),
            form_group(
              "Image Data Width",
              "img_data_width",
              int.to_string(band.img_data.width),
            ),
            form_group(
              "Image Data Height",
              "img_data_height",
              int.to_string(band.img_data.height),
            ),
            form_group("Logo Data Hash", "logo_data_hash", band.logo_data.hash),
            form_group(
              "Logo Data Width",
              "logo_data_width",
              int.to_string(band.logo_data.width),
            ),
            form_group(
              "Logo Data Height",
              "logo_data_height",
              int.to_string(band.logo_data.height),
            ),
            form_group("Cancelled", "cancelled", bool.to_string(band.cancelled)),
            form_group("Description", "description", band.description),
            form_group(
              "Description (English)",
              "description_en",
              band.description_en,
            ),
            html.button_text(
              [attr.type_("submit"), attr.class("btn btn-info")],
              "Speichern",
            ),
          ],
        )
      })
      |> list.prepend(html.div_text(
        [
          attr.class("alert alert-info"),
          attr.role("alert"),
          attr.id("globalfeedback"),
        ],
        "",
      ))
    }
    Error(reson) -> {
      [html.p_text([], reson)]
    }
  }
}

fn fetch_data(
  username: String,
  password: String,
  enti: String,
  festival: String,
) -> Result(dict.Dict(String, model.Band), String) {
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
      let bands = model.bands_from_json(response.body)
      case bands {
        Ok(bands) -> {
          io.println("Loaded: " <> int.to_string(dict.size(bands)))
          Ok(bands)
        }
        Error(err) -> {
          io.print_error(
            "Fehler beim Parsen der Band-Daten: " <> json_error_to_string(err),
          )
          Error("Nil")
        }
      }
    }
    _err -> {
      io.print_error("Fehler beim hackney.send")
      Error("Nil")
    }
  }
}

pub fn json_error_to_string(error: json.DecodeError) -> String {
  case error {
    json.UnexpectedEndOfInput -> "Unexpected end of input"
    json.UnexpectedByte(field) -> "UnexpectedByte: " <> field
    json.UnexpectedSequence(seq) -> "Unexpected sequence: " <> seq
    json.UnableToDecode(decode_errors) -> {
      decode_errors
      |> list.flat_map(fn(decode_error) {
        case decode_error {
          decode.DecodeError(expect, found, path) -> [
            expect <> ": " <> found <> " at " <> string.join(path, "."),
          ]
        }
      })
      |> string.join(", ")
    }
  }
}
