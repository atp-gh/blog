//// Site metadata: SEO, analytics, and comments configuration, mirroring
//// apollo's `config.toml` `[extra]` block.
////
//// This extends the basic `config.Config` with the site-wide settings that
//// the head builder, analytics FFI, and comments view consume. The values
//// are normally loaded from `config.toml`; here they are hardcoded defaults
//// (Phase 17 replaces them with JSON loading).

import gleam/option.{type Option, None}

/// Analytics provider configuration.
pub type Analytics {
  GoatCounter(user: String, host: String)
  Umami(website_id: String, host_url: String)
  Google(tracking_id: String)
  AnalyticsDisabled
}

/// Comments provider configuration (per-page, controlled by frontmatter).
pub type CommentsConfig {
  /// Giscus: repo, repo-id, category, category-id.
  Giscus(repo: String, repo_id: String, category: String, category_id: String)
  /// Utterances: repo.
  Utterances(repo: String)
  CommentsDisabled
}

/// Site-level metadata for SEO and integrations.
pub type SiteMeta {
  SiteMeta(
    base_url: String,
    title: String,
    description: String,
    analytics: Analytics,
    comments: CommentsConfig,
    fediverse_creator: Option(String),
  )
}

/// Hardcoded default site metadata. Phase 17 replaces this with JSON loading.
pub fn default() -> SiteMeta {
  SiteMeta(
    base_url: "https://arata.example.com",
    title: "arata",
    description: "A modern and minimalistic blog theme powered by Gleam and Lustre.",
    analytics: AnalyticsDisabled,
    comments: CommentsDisabled,
    fediverse_creator: None,
  )
}
