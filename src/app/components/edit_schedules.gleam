import gleam/dict

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

pub fn edit_schedules(festival: String, year: String) {
  let config = config.get_config()

  case
    fetch_data(
      config.username,
      config.password,
      "schedule",
      festival <> "_" <> year,
    )
  {
    Ok(data) -> {
      let stageoptins_orig =
        data
        |> dict.to_list
        |> list.map(fn(entry) {
          let #(_, schedule) = entry
          schedule.stage
        })
        |> list.unique
      data
      |> dict.to_list
      |> list.sort(fn(a, b) {
        let #(_, aa) = a
        let #(_, bb) = b
        string.compare(aa.start, bb.start)
      })
      |> list.map(fn(entry) {
        let #(key, schedule) = entry
        let stageoptins =
          stageoptins_orig
          |> list.map(fn(stage) {
            case stage == schedule.stage {
              True ->
                html.option_text([attr.value(stage), attr.selected()], stage)
              False -> html.option_text([attr.value(stage)], stage)
            }
          })
        html.form(
          [
            attr.class("container"),
            attr.Attr("hx-post", "/update/schedule/entry"),
            attr.Attr("hx-target", "#globalfeedback"),
          ],
          [
            html.div([attr.class("row ")], [
              // start:, end:, band:, stage:
              html.input([
                attr.type_("hidden"),
                attr.name("id"),
                attr.value(key),
              ]),
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
              html.div([attr.class("col-12")], [
                html.label_text(
                  [attr.for("band"), attr.class("col-form-label")],
                  schedule.band,
                ),
              ]),
              html.input([
                attr.type_("hidden"),
                attr.name("band"),
                attr.value(schedule.band),
              ]),
              html.div([attr.class("col-6")], [
                html.input([
                  attr.type_("input"),
                  attr.class("timestamp"),
                  attr.name("start"),
                  attr.value(schedule.start),
                ]),
              ]),
              html.div([attr.class("col-6")], [
                html.input([
                  attr.type_("input"),
                  attr.class("timestamp"),
                  attr.name("end"),
                  attr.value(schedule.end),
                ]),
              ]),
              html.div([attr.class("col-6")], [
                html.select(
                  [attr.name("stage"), attr.class("form-select")],
                  stageoptins,
                ),
              ]),
              html.div([attr.class("col-6")], [
                html.button_text(
                  [attr.type_("submit"), attr.class("btn btn-info")],
                  "Speichern",
                ),
              ]),
            ]),
          ],
        )
      })
      |> list.append([
        // 
        html.Script(
          [],
          "flatpickr(\".timestamp\",{enableTime: true, dateFormat: \"Z\" ,time_24hr: true, altInput: true, altFormat: \"F j, Y H:i\"})
",
        ),
      ])
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
) -> Result(dict.Dict(String, model.Event), String) {
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
      Ok(schedule)
    }
    _err -> {
      io.print_error("Fehler beim hackney.send")
      Error("Nil")
    }
  }
}
