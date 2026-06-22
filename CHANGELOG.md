# Changelog

All notable changes to arata are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] — 2025-06-22

The initial release of arata — a faithful reimplementation of the apollo blog theme using Gleam and Lustre.

### Added

- **Routing** (Phase 2): client-side routing via modem with 9 route variants (Home, Posts, Post, Projects, Talks, Tags, Tag, Page, NotFound) and paginated post index (`/posts/page/{n}`).
- **Design system** (Phase 1): the complete apollo visual design system ported from SCSS to plain CSS (2,135 lines) — colour palette, fonts, typography scale, 3-column layout, all component styles, syntax highlighting, 9 responsive breakpoints.
- **Post list** (Phase 5): paginated post list with Prev/Next pagination, draft labels, and active-nav highlighting.
- **Single post** (Phases 5-6): full article rendering with `.page-header` title, meta row (date, updated, word count, reading time), optional `tl;dr` box, body via `unsafe_raw_html`, tags, and a scroll-driven table of contents with IntersectionObserver active highlighting.
- **Projects** (Phase 7): column-balanced card grid with GitHub/Demo icon-buttons and `#tag` chips.
- **Talks** (Phase 7): responsive talk card grid with video thumbnails, play-button overlay, and meta row icon-buttons.
- **Taxonomy** (Phase 8): `/tags` index with post counts and `/tags/<tag>` single-tag pages.
- **Homepage** (Phase 9): custom landing page with hero section.
- **Standalone pages** (Phase 9): `/{slug}` pages (e.g. `/about`).
- **404** (Phase 9): apollo-style 404 page.
- **Theme system** (Phase 10): 3-state theme toggle (Light → Dark → Auto) with `localStorage` persistence and `matchMedia` reactivity.
- **Fancy code blocks** (Phase 11): copy-to-clipboard button and coloured language label on every `<pre><code>` block.
- **Search** (Phase 12): Cmd/Ctrl+K search modal with keyboard navigation (↑/↓ to navigate, Enter to follow, Esc to close).
- **Shortcodes** (Phase 13): note (static + dynamic), character, image, and mermaid shortcodes.
- **MathJax + Mermaid** (Phase 14): lazy-loaded MathJax typesetting and mermaid diagram rendering with theme-aware re-rendering.
- **SEO** (Phase 15): `<title>`, `<meta>` description, OpenGraph tags, Fediverse creator meta.
- **Feeds** (Phase 15): Atom 1.0 and RSS 2.0 feeds.
- **Sitemap** (Phase 15): `sitemap.xml` with all post + page URLs.
- **Analytics** (Phase 15): GoatCounter, Umami, and Google Analytics providers.
- **Comments** (Phase 15): Giscus and Utterances comment sections.
- **Wavy boundary** (Phase 16): a soft, SVG-based section divider (arata-original, not in apollo).
- **Build pipeline** (Phase 17): `gleam run -m build/pipeline` produces a complete static site in `dist/`.
- **Tests** (Phase 18): 57 unit tests covering routing, card reordering, tag index, search, and feed generation.
- **Accessibility** (Phase 18): `:focus-visible` styles for keyboard navigation.
- **Documentation** (Phase 19): configuration, content authoring, shortcode reference, and deployment guides.

### FFI modules

- `ffi/theme.ffi.mjs` — localStorage + matchMedia (theme toggle)
- `ffi/observer.ffi.mjs` — IntersectionObserver (TOC active highlighting)
- `ffi/codeblock.ffi.mjs` — code block enhancement (copy button + language label)
- `ffi/search.ffi.mjs` — global keydown listener (search shortcuts)
- `ffi/note.ffi.mjs` — note toggle (expand/collapse)
- `ffi/script.ffi.mjs` — MathJax + Mermaid loading and rendering
- `ffi/analytics.ffi.mjs` — analytics script injection

### Tech stack

- Gleam 1.14
- Lustre 5.7 (The Elm Architecture)
- modem 2.1 (client-side routing)
- gleam_json 3.1 (content index serialization)
- simplifile 2.4 (build pipeline file I/O)
- lustre_dev_tools 2.3 (dev server + bundling)
