+++
title = "Deployment"
date = "2026-01-04"
description = "Building and deploying arata to GitHub Pages, Cloudflare Pages, or any static host."
tags = ["docs", "deployment"]
+++

# Deployment

arata builds to a static site in `dist/` that can be deployed to any static host (GitHub Pages, Cloudflare Pages, Netlify, etc.).

## Build

```sh
# Build the complete static site in one command:
gleam run -m build/pipeline
```

This produces everything in `dist/`:
- `index.html` — the SPA shell with FOUC prevention
- `404.html` — redirect shim for deep links
- `app.mjs` — the minified SPA JavaScript bundle (bundled via `bun build`)
- `arata.css` — the design system (copied from `src/`)
- `content_index.json` — the content tree
- `search_index.json` — the search index
- `atom.xml` / `rss.xml` — feeds
- `sitemap.xml` — sitemap
- `fonts/`, `icons/`, `images/`, `css/` — static assets (copied from `static/`)

### What the pipeline does

1. Emits the JSON content index, search index, feeds, sitemap, `index.html`, and `404.html`.
2. Copies `src/arata.css` to `dist/arata.css`.
3. Copies all static assets from `static/` to `dist/`.
4. Compiles the Gleam JavaScript and bundles it into `dist/app.mjs` via `bun build` (replacing `lustre/dev build`, which requires Erlang/OTP).

### Prerequisites

- **Gleam** >= 1.14.0
- **Bun** >= 1.0 (for the SPA bundle step)
- **Erlang/OTP** is NOT required — the pipeline uses `bun build` instead of `lustre/dev build`

## GitHub Pages

1. Push the repo to GitHub.
2. Set up a GitHub Action that runs `gleam run -m build/pipeline` and publishes `dist/` to GitHub Pages.
3. The `404.html` shim handles deep links (it redirects to the SPA with the path preserved).

## Cloudflare Pages

1. Connect the repo to Cloudflare Pages.
2. Set the build command to `gleam run -m build/pipeline`.
3. Set the output directory to `dist/`.
4. Cloudflare Pages automatically serves `404.html` for unknown paths, so deep links work out of the box.

## Custom domain

Set `base_url` in `src/data/site.gleam` to your domain before building — this is used in the feeds, sitemap, and OpenGraph meta tags.

## Environment requirements

- **Gleam** >= 1.14.0
- **Bun** >= 1.0 (for the SPA bundle)
