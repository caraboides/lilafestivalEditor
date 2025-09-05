import nakai/attr
import nakai/html

pub fn hello() {
  html.div([], [
    html.p_text([attr.id("hello-text")], "Select festival"),
    html.button_text(
      [
        attr.Attr("hx-get", "/partials/demo"),
        attr.Attr("hx-target", "#hello-text"),
      ],
      "Click Me!",
    ),
  ])
}
