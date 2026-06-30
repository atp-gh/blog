//// Analytics effect: dynamically injects the analytics provider's script
//// into the document head, mirroring apollo's `partials/header.html`
//// analytics section.
////
//// Because arata doesn't yet have a custom `index.html` (Phase 17), the
//// script is injected dynamically on first load via the FFI. The provider is
//// selected by the `data/site.Analytics` config type:
////   - GoatCounter: loads `/js/count.js` with `data-goatcounter`.
////   - Umami: loads `/js/imamu.js` with `data-website-id`.
////
//// The FFI lives in `src/ffi/analytics.ffi.mjs`. The `@external` declaration
//// has a no-op Gleam fallback so the project builds on Erlang.

import data/site
import lustre/effect

/// Inject the analytics script for the configured provider. No-op when
/// `analytics` is `AnalyticsDisabled`.
pub fn inject(analytics: site.Analytics) -> effect.Effect(Nil) {
  use _ <- effect.from

  case analytics {
    site.AnalyticsDisabled -> Nil

    site.Umami(src, website_id) -> {
      inject_umami(website_id: website_id, src: src)

      Nil
    }

    site.GoatCounter(data_goatcounter, src) -> {
      inject_goatcounter(data_goatcounter: data_goatcounter, src: src)

      Nil
    }
  }
}

@external(javascript, "../ffi/analytics.ffi.mjs", "inject_umami")
fn inject_umami(website_id website_id: String, src src: String) -> Nil

@external(javascript, "../ffi/analytics.ffi.mjs", "inject_goatcounter")
fn inject_goatcounter(
  data_goatcounter data_goatcounter: String,
  src src: String,
) -> Nil
