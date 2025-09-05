import gleam/int
import gleam/io
import gleam/list
import model.{festivals}
import nakai/attr
import nakai/html

pub fn years(festival_id: String) {
  let festival =
    festivals
    |> list.find(fn(festival) { festival.id == festival_id })
  let options = case festival {
    Ok(item) -> {
      item.years
      |> list.map(fn(y) {
        html.option_text([attr.value(int.to_string(y))], int.to_string(y))
      })
      |> list.append([
        html.option_text(
          [attr.disabled(), attr.selected()],
          " -- select an option -- ",
        ),
      ])
    }
    _ -> {
      io.println("Festival not found" <> festival_id)
      []
    }
  }
  options
}
