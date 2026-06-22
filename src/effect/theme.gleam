//// Theme management (light / dark / auto) via FFI: localStorage persistence
//// and a `prefers-color-scheme` media-query subscription.
////
//// Scaffold stub; see `ROADMAP.md` (Phase 5). Mirrors apollo's
//// `themetoggle.js` behaviour, including FOUC prevention and system-preference
//// reactivity.

import lustre/effect.{type Effect}

/// The app's theme model.
pub type Theme {
  Light
  Dark
  Auto
}

/// Messages emitted by theme effects.
pub type ThemeMsg {
  ThemeLoaded(Theme)
  SystemPrefersDark(Bool)
}

/// Read the persisted/system theme at startup. Not yet implemented.
pub fn init_theme() -> Effect(ThemeMsg) {
  todo as "effect.theme.init_theme: read localStorage + matchMedia (ROADMAP Phase 5)"
}
