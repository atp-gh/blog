+++
title = "Content Authoring"
date = "2026-01-02"
description = "How to author posts, projects, talks, and pages as markdown with TOML frontmatter."
tags = ["docs", "content"]
+++

# Content Authoring

arata's content is authored as markdown files with TOML frontmatter in `content/posts/`, `content/pages/`, `content/projects/`, and `content/links/`. At build time, `content/loader.gleam` reads each file, parses the frontmatter, renders the markdown body via `mork`, and serialises the result to `content_index.json` for the SPA to fetch.

## Posts

```markdown
+++
title = "My Post"
date = "2026-01-15"
updated = "2026-01-20"          # optional
description = "A short description for the post list and SEO."
tags = ["gleam", "lustre"]
draft = false
tldr = "A one-line summary."    # optional
+++

Your markdown body here.
```

- `slug` is derived from the filename (the URL is `/posts/{slug}`).
- `body` is rendered to HTML by the markdown pipeline (`data/markdown.gleam` via `mork`).
- `toc` entries are extracted from `## ` headings in the body.
- `draft = true` shows a `DRAFT` badge and excludes the post from feeds.
- `word_count` and `reading_time` are computed automatically and shown in the meta row.

## Projects

```markdown
+++
title = "My Project"
description = "What it does."
link_to = "https://github.com/me/project"   # optional external link
image = "/path/to/image.png"                # optional
github = "https://github.com/me/project"    # optional
demo = "https://example.com"                # optional
tags = ["gleam", "tool"]
+++
```

Projects render in a column-balanced card grid at `/projects`. They have no markdown body — just frontmatter.

## Pages

```markdown
+++
title = "About"
subtitle = "A tagline under the title"   # optional
+++

Your markdown body here.
```

Standalone pages are accessible at `/{slug}` (e.g. `/about`).

## Links

```markdown
+++
title = "Friend Blog"
url = "https://friend.example.com"
description = "A short description."
+++
```

Friend links render in an alphabetical list at `/links`. They have no markdown body — just frontmatter.

## Homepage

The homepage is a special `Page` stored at `content/pages/home.md`. It renders at `/` with a hero section and a wavy boundary divider before the body content.
