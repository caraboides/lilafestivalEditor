import gleam/list
import model.{festivals}
import nakai/attr
import nakai/html

pub fn festival_picker() {
  let options =
    festivals
    |> list.map(fn(festival) {
      html.option_text([attr.value(festival.id)], festival.name)
    })
    |> list.append([
      html.option_text(
        [attr.disabled(), attr.selected()],
        " -- select an option -- ",
      ),
    ])
  html.div([], [
    html.form(
      [
        attr.Attr("hx-get", "/components/edit"),
        attr.Attr("hx-target", "#edit"),
        attr.class("container"),
      ],
      [
        html.div([attr.class("row")], [
          html.div_text(
            [attr.id("select-festival"), attr.class("col-auto")],
            "You have to select a festival",
          ),
          html.select(
            [
              attr.class("form-select col-auto"),
              attr.name("festival"),
              attr.Attr("hx-get", "/partials/festival_years"),
              attr.Attr("hx-target", "#years"),
            ],
            options,
          ),
          html.label_text([attr.class("col-auto")], "Year"),
          html.select(
            [
              attr.id("years"),
              attr.class("form-select col-auto"),
              attr.name("year"),
            ],
            [],
          ),
          html.label_text([attr.class("col-auto")], "Edit"),
          html.select([attr.name("type"), attr.class("form-select col-auto")], [
            html.option_text([attr.value("schedules")], "schedules"),
            html.option_text([attr.value("bands")], "bands"),
          ]),
          html.button_text(
            [attr.type_("submit"), attr.class("btn btn-primary")],
            "Laden",
          ),
        ]),
      ],
    ),
    html.div([attr.id("edit")], []),
  ])
}
