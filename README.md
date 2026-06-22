# arata

A faithful reimplementation of the [apollo](https://github.com/not-matthias/apollo) blog theme, built with [Gleam](https://gleam.run) and the [Lustre](https://hexdocs.pm/lustre) framework.

> **Status:** scaffold. The project structure and tooling are in place; the apollo feature set is implemented phase by phase as described in [`ROADMAP.md`](./ROADMAP.md).

## Stack

- **Language:** Gleam 1.14
- **Framework:** Lustre 5 (The Elm Architecture, client-side SPA)
- **Routing:** modem (History API)
- **Build/dev:** lustre_dev_tools (JavaScript target)

## Project layout

```
arata/
├── gleam.toml            # project + Lustre HTML tool config
├── ROADMAP.md            # phased implementation plan
├── src/
│   ├── arata.gleam       # application entry point (boots Lustre)
│   ├── arata.css         # stylesheet entry (ported apollo design system)
│   ├── route.gleam       # URL <-> Route mapping
│   ├── data/             # content models (posts, projects, talks)
│   ├── view/             # page + component view functions
│   └── effect/           # managed side effects (theme, search, ...)
└── static/               # fonts, icons, vendored CSS
```

## Prerequisites

- [Gleam](https://gleam.run) >= 1.14.0
- [Erlang/OTP](https://www.erlang.org) (only required to run the `lustre/dev` dev server)
- [Node.js](https://nodejs.org) (JavaScript runtime / bundler)

## Development

```sh
gleam build                    # type-check + compile to JavaScript
gleam run -m lustre/dev start  # dev server with hot reload (http://localhost:1234)
gleam test                     # run the test suite
```

## Origin

`arata` reproduces the design and feature set of the `apollo` Zola theme. See
[`ROADMAP.md`](./ROADMAP.md) for the full mapping from apollo's templates and
features to Lustre's Model-View-Update architecture.
