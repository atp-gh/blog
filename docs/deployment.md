# Deployment

arata builds to a static site in `dist/` that can be deployed to any static host (GitHub Pages, Cloudflare Pages, Netlify, etc.).

## Build

```sh
# 1. Build the static assets (content index, feeds, sitemap, index.html, 404.html)
gleam run -m build/pipeline

# 2. Build the SPA JavaScript bundle (requires Erlang/OTP for lustre_dev_tools)
gleam run -m lustre/dev build --minify --outdir=dist

# 3. Copy static assets (fonts, icons, images, CSS) to dist/
cp -r static/* dist/
```

After these steps, `dist/` contains:
- `index.html` — the SPA shell with FOUC prevention
- `404.html` — redirect shim for deep links
- `app.mjs` — the minified SPA bundle
- `arata.css` — the design system
- `content_index.json` — the content tree
- `search_index.json` — the search index
- `atom.xml` / `rss.xml` — feeds
- `sitemap.xml` — sitemap
- `fonts/`, `icons/`, `images/` — static assets

## GitHub Pages

1. Push the repo to GitHub.
2. Set up a GitHub Action that runs the build steps above and publishes `dist/` to GitHub Pages.
3. The `404.html` shim handles deep links (it redirects to the SPA with the path preserved).

## Cloudflare Pages

1. Connect the repo to Cloudflare Pages.
2. Set the build command to the build steps above.
3. Set the output directory to `dist/`.
4. Cloudflare Pages automatically serves `404.html` for unknown paths, so deep links work out of the box.

## Custom domain

Set `base_url` in `src/data/site.gleam` to your domain before building — this is used in the feeds, sitemap, and OpenGraph meta tags.

## Environment requirements

- **Gleam** >= 1.14.0
- **Erlang/OTP** (required by `lustre_dev_tools` for the dev server and bundling)
- **Node.js** (JavaScript runtime for the bundler)

The build pipeline (`gleam run -m build/pipeline`) itself does NOT require Erlang — it runs on the JavaScript target. Erlang is only needed for `lustre/dev build`.
