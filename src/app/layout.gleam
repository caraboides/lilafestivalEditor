import app/hot_reloading
import gleam/list
import gleam/string_tree.{type StringTree}
import nakai
import nakai/attr
import nakai/html
import wisp

pub fn layout(page: html.Node) {
  let hot_reloading_scripts = hot_reloading.add_hot_reloading()
  let layout =
    html.Html([], [
      html.Doctype("html"),
      html.Head([
        html.meta([attr.charset("UTF-8")]),
        html.meta([
          attr.name("viewport"),
          attr.content("width=device-width, initial-scale=1.0"),
        ]),
        html.title("FestivalHubEditor"),
        html.link([
          attr.rel("stylesheet"),
          attr.href(
            "https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css",
          ),
          attr.crossorigin("anonymous"),
        ]),
        html.link([
          attr.rel("stylesheet"),
          attr.href(
            "https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css",
          ),
          attr.crossorigin("anonymous"),
        ]),
        html.Script(
          [
            attr.src(
              "https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/js/bootstrap.bundle.min.js",
            ),
          ],
          "",
        ),
        html.Script([attr.src("https://cdn.jsdelivr.net/npm/flatpickr")], ""),
      ]),
      html.Body([], [page, ..hot_reloading_scripts]),
    ])
  layout
}

pub fn render_page(page: html.Node) {
  let content =
    page
    |> layout
    |> nakai.to_inline_string_tree
    |> inject_script_src
  wisp.ok()
  |> wisp.html_body(content)
}

pub fn render_partial(partial: List(html.Node)) {
  let content =
    partial
    |> list.map(fn(a) { nakai.to_inline_string_tree(a) })
    |> list.fold(string_tree.new(), string_tree.append_tree)

  wisp.ok()
  |> wisp.html_body(content)
}

// ugly hack to inject the htmx script tag into the html since nakai does not
fn inject_script_src(html: StringTree) -> StringTree {
  html
  |> string_tree.replace(
    "</head>",
    "<script src='https://unpkg.com/htmx.org@1.9.10'></script></head>",
  )
}
