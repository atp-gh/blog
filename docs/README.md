# arata — Documentation

arata is a faithful reimplementation of the [apollo](https://github.com/not-matthias/apollo) blog theme, built with [Gleam](https://gleam.run) and the [Lustre](https://hexdocs.pm/lustre) framework.

## Guides

- [Configuration](./configuration.md) — site config, menu, socials, analytics, comments.
- [Content Authoring](./content.md) — how to write posts, projects, talks, and pages.
- [Shortcode Reference](./shortcodes.md) — note, character, image, and mermaid shortcodes.
- [Deployment](./deployment.md) — building and deploying to GitHub/Cloudflare Pages.

## Quick start

```sh
gleam run -m build/pipeline      # build the static site into dist/
gleam run -m lustre/dev start    # dev server (requires Erlang/OTP)
gleam test                       # run the test suite (57 tests)
```

## Architecture

arata follows The Elm Architecture (Model-View-Update) with managed effects:

- **Model**: a single immutable record holding the route, config, content, theme, and search state.
- **Update**: pure transitions; side effects are returned as `Effect(Msg)` values.
- **View**: pure virtual-DOM render dispatching on the current route.

Client-side routing uses [modem](https://hexdocs.pm/modem) over the History API. Theme switching, TOC highlighting, code-block enhancement, search, note toggling, MathJax/Mermaid rendering, and analytics injection are all handled via FFI effects that run after each view render.

See the [ROADMAP](../ROADMAP.md) for the full phased implementation history.
