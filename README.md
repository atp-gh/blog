# arata

A faithful reimplementation of the [apollo](https://github.com/not-matthias/apollo) blog theme, built with [Gleam](https://gleam.run) and the [Lustre](https://hexdocs.pm/lustre) framework.

> **Status:** v0.1.0. All 19 roadmap phases are complete — the full apollo feature set is implemented and the test suite (57 tests) is green.

## Stack

- **Language:** Gleam 1.14
- **Framework:** Lustre 5.7 (The Elm Architecture, client-side SPA)
- **Routing:** modem 2.1 (History API)
- **Build/dev:** lustre_dev_tools 2.3 (JavaScript target)
- **Tests:** gleeunit (57 passing)

## Features

- **9 routes**: homepage, paginated post list, single post, projects grid, talks grid, tags index, single tag, standalone pages, 404
- **3-state theme toggle** (Light/Dark/Auto) with localStorage + matchMedia
- **Cmd/Ctrl+K search** modal with keyboard navigation
- **Table of contents** with scroll-driven IntersectionObserver highlighting
- **Fancy code blocks** with copy button + language label
- **4 shortcodes**: note (static/dynamic), character, image, mermaid
- **MathJax + Mermaid** rendering with theme-aware re-rendering
- **SEO** meta, OpenGraph, Atom/RSS feeds, sitemap
- **Analytics**: GoatCounter, Umami, Google
- **Comments**: Giscus, Utterances
- **Wavy section boundary** (arata-original, not in apollo)
- **Build pipeline**: `gleam run -m build/pipeline` → complete static site in `dist/`

## Quick start

```sh
gleam build                    # type-check + compile
gleam test                     # run 57 tests
gleam run -m build/pipeline    # build static site into dist/
gleam run -m lustre/dev start  # dev server (requires Erlang/OTP)
```

## Project layout

```
arata/
├── src/
│   ├── arata.gleam          # entry point (boots Lustre)
│   ├── arata.css            # design system (2,135 lines)
│   ├── route.gleam          # URL <-> Route mapping
│   ├── data/                # content models + site config
│   ├── view/                # page + component views
│   ├── effect/              # managed side effects (FFI)
│   ├── ffi/                 # JavaScript FFI (7 modules)
│   ├── shortcodes/          # note, character, image, mermaid
│   └── build/               # content → dist/ pipeline + feeds
├── test/                    # 57 unit tests
├── docs/                    # configuration, content, shortcodes, deployment
├── static/                  # fonts, icons, images
├── ROADMAP.md               # phased implementation plan
├── CHANGELOG.md             # release history
└── gleam.toml
```

## Documentation

- [Configuration](./docs/configuration.md)
- [Content Authoring](./docs/content.md)
- [Shortcode Reference](./docs/shortcodes.md)
- [Deployment](./docs/deployment.md)
- [ROADMAP](./ROADMAP.md) — full phased implementation history

## Origin

`arata` reproduces the design and feature set of the `apollo` Zola theme. See [`ROADMAP.md`](./ROADMAP.md) for the full mapping from apollo's templates and features to Lustre's Model-View-Update architecture.

## License

MIT
