//// Content model for a single post, mirroring apollo's TOML frontmatter.
////
//// Scaffold stub. The full frontmatter schema and markdown parsing pipeline
//// are tracked in `ROADMAP.md` (Phase 4).

/// A blog post, parsed from markdown + TOML frontmatter.
pub type Post {
  Post(
    slug: String,
    title: String,
    /// ISO-8601 publication date string.
    date: String,
    description: String,
    /// Rendered HTML body.
    body: String,
    tags: List(String),
    draft: Bool,
  )
}
