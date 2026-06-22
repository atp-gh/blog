//// Routing: maps browser URLs to arata's internal `Route` type and back.
////
//// This is a scaffold stub. The full implementation — covering every apollo
//// page (home, posts, single post, projects, talks, tags, single tag, static
//// page, 404) — is tracked in `ROADMAP.md` (Phase 2).
////
//// Patterned after the `01-routing` Lustre example, using `modem` for
//// client-side navigation over the History API.

import gleam/uri.{type Uri}
import lustre/attribute.{type Attribute}

/// The set of pages arata can render. One variant per apollo page template.
pub type Route {
  Home
  Posts
  Post(slug: String)
  Projects
  Talks
  Tags
  Tag(name: String)
  Page(slug: String)
  /// A URI we could not match. Kept so we can log it or hint at a typo.
  NotFound(uri: Uri)
}

/// Parse a browser URI into a `Route`. Not yet implemented.
pub fn parse_route(_uri: Uri) -> Route {
  todo as "parse_route: map URI path segments to Route variants (ROADMAP Phase 2)"
}

/// Serialise a `Route` back into an `href` attribute for `<a>` elements.
/// Must stay in sync with `parse_route`. Not yet implemented.
pub fn href(_route: Route) -> Attribute(message) {
  todo as "href: serialise Route to a URL string (ROADMAP Phase 2)"
}
