# Content Authoring

arata's content is currently authored as Gleam constants in `src/data/sample_content.gleam`. A future build pipeline (ROADMAP Phase 17+) will read markdown files from a `content/` directory; for now, posts/projects/talks/pages are Gleam records with pre-rendered HTML bodies.

## Posts

```gleam
Post(
  slug: "my-post",
  title: "My Post",
  date: "2025-01-15",
  updated: Some("2025-01-20"),     // optional
  description: "A short description for the post list and SEO.",
  body: "<p>The rendered HTML body.</p>",
  toc: [
    TocEntry(id: "section-1", title: "Section 1", children: []),
  ],
  tags: ["gleam", "lustre"],
  draft: False,
  tldr: Some("A one-line summary."),  // optional
  word_count: 250,
  reading_time: 2,
)
```

- `slug` is the URL path (`/posts/{slug}`).
- `body` is pre-rendered HTML (the markdown pipeline arrives in Phase 17).
- `toc` entries must match `<h2 id="...">` elements in the body.
- `draft: True` shows a `DRAFT` badge.
- `word_count` and `reading_time` are shown in the meta row when non-zero.

## Projects

```gleam
Project(
  slug: "my-project",
  title: "My Project",
  description: "What it does.",
  link_to: Some("https://github.com/me/project"),  // external link, or None
  image: None,                                      // or Some("/path/to/image.png")
  github: Some("https://github.com/me/project"),
  demo: Some("https://example.com"),
  tags: ["gleam", "tool"],
)
```

Projects render in a column-balanced card grid at `/projects`.

## Talks

```gleam
Talk(
  slug: "my-talk",
  title: "My Talk",
  description: "What the talk is about.",
  date: "2025-03-01",
  thumbnail: None,                                    // or Some("/path/to/thumb.jpg")
  video_link: Some("https://youtube.com/watch?v=..."),
  organizer: Some(#("Conf Name", "https://conf.example.com")),
  slides: Some("https://example.com/slides.pdf"),
  code: Some("https://github.com/me/talk-demo"),
)
```

Talks render in a responsive card grid at `/talks`.

## Pages

```gleam
Page(
  slug: "about",
  title: "About",
  body: "<p>About this site.</p>",
  subtitle: None,   // or Some("A tagline under the title")
)
```

Standalone pages are accessible at `/{slug}` (e.g. `/about`).

## Homepage

The homepage is a special `Page` returned by `sample_content.homepage()`. It renders at `/` with a hero section and a wavy boundary divider before the body content.
