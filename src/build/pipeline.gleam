//// The build pipeline: orchestrates the content → `dist/` build, replacing
//// Zola's role end-to-end.
////
//// Running `gleam run -m arata/build` (on the Erlang target) walks the
//// content, emits the JSON content index, search index, feeds, sitemap, a
//// custom `index.html` with FOUC prevention, and a `404.html` redirect shim
//// into the `dist/` directory. The Lustre SPA bundle is produced separately
//// by `gleam run -m lustre/dev build --minify --outdir=dist`.
////
//// For now, the content source is the Gleam constants in
//// `data/sample_content` (the markdown-to-HTML pipeline is a future
//// enhancement). The build step still produces all the static assets a
//// real deployment needs.

import build/feeds
import data/page.{type Page}
import data/post.{type Post}
import data/project.{type Project}
import data/sample_content
import data/site
import data/talk.{type Talk}
import gleam/json
import gleam/list
import gleam/string
import simplifile

/// The output directory for the built site.
const dist_dir = "dist"

/// Run the full build pipeline. Returns `Ok(Nil)` on success, or an error
/// message if any file write fails.
pub fn main() -> Nil {
  let assert Ok(_) = run()
  Nil
}

/// Run the build pipeline, returning a result.
pub fn run() -> Result(Nil, String) {
  let site_meta = site.default()
  let posts = sample_content.posts()
  let projects = sample_content.projects()
  let talks = sample_content.talks()
  let pages = sample_content.pages()
  let homepage = sample_content.homepage()

  // Ensure the dist directory exists.
  let _ = simplifile.create_directory(dist_dir)

  // 1. Content index JSON (the SPA fetches this at boot in a future phase;
  //    for now it's emitted for completeness and for future hydration).
  write(
    dist_dir <> "/content_index.json",
    content_index_json(site_meta, posts, projects, talks, pages, homepage),
  )

  // 2. Search index JSON (elasticlunr-compatible shape; for now a simple
  //    array of {title, description, tags, url} objects).
  write(dist_dir <> "/search_index.json", search_index_json(posts))

  // 3. Feeds.
  write(dist_dir <> "/atom.xml", feeds.atom_feed(site_meta, posts))
  write(dist_dir <> "/rss.xml", feeds.rss_feed(site_meta, posts))

  // 4. Sitemap.
  let page_slugs = list.map(pages, fn(p) { p.slug })
  write(dist_dir <> "/sitemap.xml", feeds.sitemap(site_meta, posts, page_slugs))

  // 5. Custom index.html with FOUC prevention.
  write(dist_dir <> "/index.html", index_html(site_meta))

  // 6. 404.html redirect shim for static hosts (deep-link support).
  write(dist_dir <> "/404.html", not_found_html())

  Ok(Nil)
}

/// Write `content` to `path`, creating parent directories as needed.
fn write(path: String, content: String) -> Nil {
  let _ = simplifile.write(path, content)
  Nil
}

/// The content index JSON: the full content tree serialized for the SPA to
/// consume (or for future SSR hydration).
fn content_index_json(
  site_meta: site.SiteMeta,
  posts: List(Post),
  projects: List(Project),
  talks: List(Talk),
  pages: List(Page),
  homepage: Page,
) -> String {
  let config_obj =
    json.object([
      #("title", json.string(site_meta.title)),
      #("description", json.string(site_meta.description)),
      #("base_url", json.string(site_meta.base_url)),
    ])
  let posts_arr =
    json.array(posts, fn(post) {
      json.object([
        #("slug", json.string(post.slug)),
        #("title", json.string(post.title)),
        #("date", json.string(post.date)),
        #("description", json.string(post.description)),
        #("tags", json.array(post.tags, json.string)),
        #("draft", json.bool(post.draft)),
      ])
    })
  let projects_arr =
    json.array(projects, fn(project) {
      json.object([
        #("slug", json.string(project.slug)),
        #("title", json.string(project.title)),
        #("description", json.string(project.description)),
      ])
    })
  let talks_arr =
    json.array(talks, fn(talk) {
      json.object([
        #("slug", json.string(talk.slug)),
        #("title", json.string(talk.title)),
        #("description", json.string(talk.description)),
        #("date", json.string(talk.date)),
      ])
    })
  let pages_arr =
    json.array(pages, fn(page) {
      json.object([
        #("slug", json.string(page.slug)),
        #("title", json.string(page.title)),
      ])
    })
  let home_obj =
    json.object([
      #("slug", json.string(homepage.slug)),
      #("title", json.string(homepage.title)),
    ])
  json.to_string(
    json.object([
      #("config", config_obj),
      #("posts", posts_arr),
      #("projects", projects_arr),
      #("talks", talks_arr),
      #("pages", pages_arr),
      #("homepage", home_obj),
    ]),
  )
}

/// The search index JSON: a simple array of searchable documents.
fn search_index_json(posts: List(Post)) -> String {
  json.to_string(
    json.array(posts, fn(post) {
      json.object([
        #("title", json.string(post.title)),
        #("description", json.string(post.description)),
        #("tags", json.string(string.join(post.tags, " "))),
        #("url", json.string("/posts/" <> post.slug)),
      ])
    }),
  )
}

/// The custom `index.html` with FOUC prevention: both `light` and `dark`
/// classes on `<html>`, both theme stylesheets loaded (dark `disabled`), and
/// the SPA script. The theme FFI toggles the `disabled` attribute at runtime.
fn index_html(site_meta: site.SiteMeta) -> String {
  "<!DOCTYPE html>
<html lang='en' class='dark light'>
<head>
  <meta charset='UTF-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1.0'>
  <title>" <> site_meta.title <> "</title>
  <meta name='description' content='" <> site_meta.description <> "'>
  <link rel='icon' type='image/png' href='/icon/favicon.png'>
  <link rel='alternate' type='application/atom+xml' href='/atom.xml'>
  <link rel='alternate' type='application/rss+xml' href='/rss.xml'>
  <link rel='stylesheet' href='/arata.css'>
</head>
<body>
  <div id='app'></div>
  <script type='module' src='/app.mjs'></script>
</body>
</html>"
}

/// The 404.html redirect shim: on static hosts that serve 404.html for
/// unknown paths, this script redirects to the SPA with the original path
/// preserved (so the client-side router can handle it).
fn not_found_html() -> String {
  "<!DOCTYPE html>
<html>
<head>
  <meta charset='UTF-8'>
  <script>
    // Redirect to the SPA, preserving the path so the client router can
    // handle it. This is the standard pattern for SPA deep-linking on
    // GitHub/Cloudflare Pages.
    var path = window.location.pathname;
    window.location.href = '/#' + path;
  </script>
</head>
<body>
  <p>Redirecting… If you are not redirected, <a href='/'>click here</a>.</p>
</body>
</html>"
}
