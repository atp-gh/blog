+++
title = "Configuration"
date = "2026-01-01"
description = "Comprehensive configuration guide for arata."
tags = ["guide", "config"]
+++

# Configuration

arata is configured through two Gleam modules whose types mirror the
`[extra]` block of apollo's `config.toml`:

- **`src/config.gleam`** — the `Config` type: title, description, navigation
  menu, socials, logo, fonts, RSS toggle, search toggle, and analytics.
- **`src/data/site.gleam`** — the `SiteMeta` type: `base_url`, SEO metadata,
  analytics, comments, Fediverse handle, and RSS toggle.

For now these are Gleam constants (`default/0` in each module). A future
phase will replace them with a `config.toml` loader, but the shape of the
types will not change — every field documented here will keep its name and
semantics.

## Site Configuration (`config.gleam`)

The `Config` type drives the header view, the nav menu, the socials row, the
font overrides injected into `:root`, and the search and RSS toggles.

```gleam
Config(
  title: "arata",
  description: "A blog built with Gleam and Lustre.",
  menu: [
    MenuItem(name: "posts", url: "/posts"),
    MenuItem(name: "projects", url: "/projects"),
    MenuItem(name: "links", url: "/links"),
    MenuItem(name: "about", url: "/about"),
  ],
  socials: [
    Social(name: "RSS", url: "./atom.xml", icon: "rss"),
    Social(name: "GitHub", url: "https://github.com/yonzilch/arata", icon: "github"),
  ],
  logo: None,                 // or Some("/images/logo.png")
  rss_enabled: True,          // set False to skip feeds + hide RSS social
  fonts: Fonts(
    text: "\"ZedTextFtl\"",
    header: "\"ZedDisplayFtl\", \"Space Grotesk\", sans-serif",
    code: "\"Jetbrains Mono\"",
  ),
  search_enabled: True,       // set False to hide the search button + modal
  analytics: AnalyticsDisabled,
)
```

### `title` and `description`

Site-wide title and description. `title` appears in the header (unless a
`logo` is set) and is used as the site `<title>` fallback. `description` is
emitted as the `<meta name="description">` tag on the index page.

### `menu` — navigation menu items

A list of `MenuItem(name, url)` rendered in the header. The convention is:

- `name` is the lowercase label **without** a leading slash — e.g. `"posts"`,
  `"about"`. The header renders it as-is.
- `url` is the route **with** a leading slash — e.g. `"/posts"`, `"/about"`.

```gleam
MenuItem(name: "posts", url: "/posts"),
```

### `socials` — social links

A list of `Social(name, url, icon)` rendered as icon links in the header,
to the right of the menu. Each field:

| Field  | Meaning |
|--------|---------|
| `name` | Accessible label / tooltip text — e.g. `"GitHub"`, `"RSS"`. |
| `url`  | Link target. Use `./atom.xml` (relative) for the RSS feed so it resolves correctly under subdirectory hosting; use absolute `https://…` URLs for external socials. |
| `icon` | Filename (without extension) of an SVG in `static/icons/social/`. `icon: "github"` resolves to `/icons/social/github.svg`. |

arata ships a set of Font-Academy-style social SVGs (GitHub, RSS, X,
Mastodon, etc.). Drop new SVGs into `static/icons/social/` and reference
them by filename.

> **Note on the RSS social:** the `default_socials/1` helper in
> `config.gleam` prepends the RSS link **only when** `rss_enabled` is `True`,
> so the RSS icon appears at the leftmost position of the socials row
> whenever feeds are enabled. Set `rss_enabled: False` to drop it.

### `logo` — optional logo path

An `Option(String)` containing a path relative to `/` — for example
`Some("/images/logo.png")`. When `None`, the site title is rendered as a
text link in the nav; when `Some`, the logo image is rendered instead.

### `fonts` — custom font families

A `Fonts(text, header, code)` record whose fields are CSS `font-family`
declarations. They are injected as a `:root` CSS override (an inline
`<style>` rule) at boot, so the rest of `arata.css` resolves them through
the `--text-font`, `--header-font`, and `--code-font` custom properties.

```gleam
Fonts(
  text: "\"ZedTextFtl\"",
  header: "\"ZedDisplayFtl\", \"Space Grotesk\", sans-serif",
  code: "\"Jetbrains Mono\"",
)
```

To use a web font, ship the font files in `static/fonts/` and add the
`@font-face` declarations to your CSS before referencing them here.

### `rss_enabled` — enable/disable RSS feeds

A `Bool`. When `True` (the default):

- The build pipeline writes `dist/atom.xml` and `dist/rss.xml`.
- `<link rel="alternate">` feed tags are emitted in `index.html`.
- The RSS social link is added to the header (leftmost position).

When `False`, all three are suppressed — no feed files, no `<link>` tags,
and no RSS icon. This mirrors blogatto's opt-out feed model.

### `search_enabled` — enable/disable search

A `Bool`. When `True` (the default):

- The search button is rendered in the header.
- The search modal is mounted and the `Cmd/Ctrl+K` keyboard shortcut is
  subscribed to.
- A `search_index.json` is written to `dist/`.

When `False`, the search button, the modal, and the keyboard shortcut are
all omitted.

### `analytics` — analytics provider

Configurable from the `Config` type (mirrors `SiteMeta.analytics`). One of:

| Provider        | Config                                                          | Behaviour |
|-----------------|-----------------------------------------------------------------|-----------|
| GoatCounter     | `GoatCounter(user: "your-user", host: "goatcounter.com")`       | Loads GoatCounter's `count.js` with `data-goatcounter`. |
| Umami           | `Umami(website_id: "xxx", host_url: "https://api.umami.dev/")`  | Loads Umami's script with `data-website-id`. |
| Disabled        | `AnalyticsDisabled`                                             | No analytics script injected. |

> **Note:** Google Analytics is intentionally **not** supported.

## Site Metadata (`data/site.gleam`)

The `SiteMeta` type is consumed by the head builder, the analytics FFI, and
the comments view. It overlaps with `Config` for `analytics` and
`rss_enabled` so both code paths can read them.

```gleam
SiteMeta(
  base_url: "https://arata.example.com",
  title: "arata",
  description: "A modern and minimalistic blog theme powered by Gleam and Lustre.",
  analytics: AnalyticsDisabled,
  comments: CommentsDisabled,
  fediverse_creator: None,
  rss_enabled: True,
)
```

### `base_url`, `title`, `description`

- `base_url` — the canonical origin of the deployed site. Used to build
  absolute URLs in the RSS feed, the sitemap, and `<link rel="canonical">`.
- `title` — site title used in SEO tags and the feed.
- `description` — site description emitted as `<meta name="description">`.

### `analytics`

Same `Analytics` type as in `Config` — `GoatCounter`, `Umami`, or
`AnalyticsDisabled`. Set it in whichever module your integration reads;
both paths honor it.

### `comments` — comment provider

A `CommentsConfig` controlling the per-page comments section. One of:

| Provider   | Config                                                                   | Behaviour |
|------------|--------------------------------------------------------------------------|-----------|
| Giscus     | `Giscus(repo: "user/repo", repo_id: "...", category: "...", category_id: "...")` | Loads the Giscus client. |
| Utterances | `Utterances(repo: "user/repo")`                                          | Loads the utteranc.es client. |
| Disabled   | `CommentsDisabled`                                                       | No comments section rendered. |

### `fediverse_creator` — optional Fediverse handle

An `Option(String)`. When `Some("@you@example.social")`, arata emits a
`<meta name="fediverse:creator" content="@you@example.social">` tag so
Mastodon and other ActivityPub clients can attribute link previews to you.
Leave it `None` to omit the tag.

### `rss_enabled`

A `Bool`. The build pipeline reads this field on `SiteMeta` (because the
pipeline operates on `SiteMeta`, not on `Config`). Keep it in sync with
`Config.rss_enabled` — when `False`, no `atom.xml` / `rss.xml` are written
and no feed `<link>` tags are emitted.

## Content Authoring

All content lives under `content/` in four subdirectories. Each Markdown
file uses **TOML frontmatter** delimited by `+++ … +++`:

```
+++
title = "My Post"
date = "2026-02-01"
description = "A short summary."
tags = ["gleam", "lustre"]
+++

Body in Markdown…
```

### Posts — `content/posts/*.md`

Blog posts. Supported frontmatter:

```toml
+++
title = "Hello, arata"
date = "2026-01-15"
updated = "2026-01-18"          # optional
description = "Introducing arata."
tags = ["gleam", "lustre"]
draft = false                    # optional, default false
tldr = "One-line summary."       # optional, shown above the body
+++
```

Posts appear on the `/posts` list page (with the date on the left and the
title on the right), in the RSS feed, in the search index, and in the
sitemap.

### Pages — `content/pages/*.md`

Standalone pages such as `/about` and `/home`. Minimal frontmatter:

```toml
+++
title = "About"
+++
```

Pages are reachable from the nav menu but are not listed on `/posts` and are
not included in the RSS feed.

### Links — `content/links/*.md`

External link cards shown on the `/links` page. Frontmatter:

```toml
+++
title = "Gleam"
url = "https://gleam.run"
description = "A typed, functional language that compiles to JS and Erlang."
+++
```

Body content (if any) is rendered as the card's expanded description.

### Projects — `content/projects/*.md`

Project showcase cards shown on the `/projects` page. Frontmatter:

```toml
+++
title = "arata"
description = "A faithful reimplementation of the apollo blog theme in Gleam and Lustre."
link_to = "https://github.com/yonzilch/arata"      # "Visit" link
github = "https://github.com/yonzilch/arata"       # GitHub icon link
tags = ["gleam", "lustre", "blog"]
+++
```

### Frontmatter format

arata uses **TOML** frontmatter exclusively, delimited by `+++` on its own
line at the very top of the file:

```
+++
key = "value"
array = ["a", "b"]
boolean = true
date = "2026-01-15"
+++
```

YAML (`---`) and JSON (`;;;`) delimiters are not supported.

## Theme

### Light / Dark / Auto toggle

The theme toggle cycles **Light → Dark → Auto → Light** (apollo's
`toggle-auto` mode). The choice is persisted to
`localStorage["theme-storage"]`. When `Auto` is selected, arata respects
the system preference via `prefers-color-scheme` and updates live when the
OS theme changes.

### Custom accent color

The accent color is a single CSS custom property defined in `src/arata.css`:

```css
:root {
  --primary-color: #3555b3;
}
```

Change the hex value to recolor every accent surface — links, the active
nav item, the search button, tag pills, and heading anchor links all
resolve through `var(--primary-color)`. The dark theme keeps the same hue
(commented in the stylesheet) so a single edit covers both modes.

## Build

### Build command

From the project root:

```bash
gleam run -m build/pipeline
```

This runs the full build pipeline (`src/build/pipeline.gleam`):
content loading → rendering → feeds → sitemap → search index → static
assets.

### Output directory structure

The build writes to `dist/`:

```
dist/
├── index.html              # SPA shell with <link> tags for feeds
├── app.mjs                 # compiled Lustre SPA bundle
├── arata.css               # compiled stylesheet
├── 404.html                # not-found page
├── atom.xml                # Atom feed (when rss_enabled = True)
├── rss.xml                 # RSS 2.0 feed (when rss_enabled = True)
├── sitemap.xml             # sitemap
├── content_index.json      # content manifest for the SPA
├── search_index.json       # search corpus (when search_enabled = True)
├── css/                    # theme stylesheets (giallo-light, giallo-dark)
├── fonts/                  # font files
├── icons/                  # social + UI icons
└── images/                 # static images
```

Serve `dist/` with any static file server (e.g. `python -m http.server
--directory dist`) and open the URL in a browser.
