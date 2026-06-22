//// arata — a faithful reimplementation of the apollo blog theme using Gleam
//// and the Lustre framework.
////
//// This module is the application entry point. It boots a minimal Lustre app
//// that renders a scaffold placeholder page. The apollo feature set is built
//// up phase by phase as described in `ROADMAP.md`.
////
//// At this stage no feature is implemented: routing, theming, content
//// loading, search, and the apollo visual design are all tracked in the
//// roadmap.

import lustre
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

// MAIN ------------------------------------------------------------------------

/// Boot the Lustre application and mount it onto the `#app` element rendered
/// by the Lustre HTML tool's generated `index.html`.
pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

// MODEL -----------------------------------------------------------------------

/// The application model. Deliberately empty for the scaffold; subsequent
/// phases add route, theme, content, and search state.
type Model {
  Model
}

fn init(_flags: Nil) -> Model {
  Model
}

// UPDATE ----------------------------------------------------------------------

/// The application has no messages yet, so the message type is `Nil`. A real
/// `Msg` type is introduced in Phase 2 of the roadmap once routing and
/// interaction land.
fn update(model: Model, _msg: Nil) -> Model {
  model
}

// VIEW ------------------------------------------------------------------------

fn view(_model: Model) -> Element(Nil) {
  html.div([attribute.class("arata-scaffold")], [
    html.h1([], [html.text("arata")]),
    html.p([], [
      html.text(
        "Project scaffolded with Gleam + Lustre. The apollo theme will be "
        <> "reproduced phase by phase — see ROADMAP.md.",
      ),
    ]),
  ])
}
