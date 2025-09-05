import app/actions/update_band.{update_band}
import app/actions/update_schedule.{update_schedule}
import app/components/edit_bands.{edit_bands}
import app/components/edit_schedules.{edit_schedules}
import app/layout
import app/pages/festival_picker.{festival_picker}
import app/partials/festival_years.{years}
import gleam/io
import gleam/list
import wisp.{type Request, type Response}

pub fn handle_request(req: Request) -> Response {
  case wisp.path_segments(req) {
    [] -> layout.render_page(festival_picker())
    ["partials", "festival_years"] ->
      layout.render_partial(years(load_param(req, "festival")))
    ["components", "edit"] -> {
      case load_param(req, "type") {
        "schedules" ->
          layout.render_partial(edit_schedules(
            load_param(req, "festival"),
            load_param(req, "year"),
          ))
        "bands" ->
          layout.render_partial(edit_bands(
            load_param(req, "festival"),
            load_param(req, "year"),
          ))
        _ -> wisp.not_found()
      }
    }
    ["update", "schedule", "entry"] -> update_schedule(req)
    ["update", "band", "entry"] -> update_band(req)
    ["reload"] -> reload()
    _ -> wisp.not_found()
  }
}

fn reload() -> wisp.Response {
  wisp.no_content()
}

fn load_param(request: Request, name: String) -> String {
  case
    request
    |> wisp.get_query
    |> list.find(fn(q) {
      let #(a, _) = q
      a == name
    })
  {
    Ok(q) -> {
      let #(_, b) = q
      b
    }
    _ -> {
      io.println("PAram " <> name <> " not found")
      "notFound"
    }
  }
}
