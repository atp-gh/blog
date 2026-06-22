# Configuration

arata's configuration lives in `src/data/site.gleam` (the `SiteMeta` type) and `src/config.gleam` (the `Config` type). In a future build pipeline (Phase 17+), these will be loaded from a `config.toml` file; for now they are Gleam constants.

## Site metadata (`data/site.gleam`)

```gleam
SiteMeta(
  base_url: "https://your-domain.com",
  title: "Your Site Title",
  description: "Your site description.",
  analytics: AnalyticsDisabled,       // or GoatCounter, Umami, Google
  comments: CommentsDisabled,         // or Giscus, Utterances
  fediverse_creator: None,            // or Some("@you@instance")
)
```

### Analytics providers

| Provider | Config | Behaviour |
|---|---|---|
| GoatCounter | `GoatCounter(user: "your-user", host: "goatcounter.com")` | Loads `/js/count.js` with `data-goatcounter`. |
| Umami | `Umami(website_id: "xxx", host_url: "https://api.umami.dev/")` | Loads `/js/imamu.js` with `data-website-id`. |
| Google | `Google(tracking_id: "G-XXXXXXX")` | Loads `gtag.js` from googletagmanager.com. |
| Disabled | `AnalyticsDisabled` | No analytics. |

### Comments providers

| Provider | Config | Behaviour |
|---|---|---|
| Giscus | `Giscus(repo: "user/repo", repo_id: "...", category: "...", category_id: "...")` | Loads the giscus client script. |
| Utterances | `Utterances(repo: "user/repo")` | Loads the utteranc.es client script. |
| Disabled | `CommentsDisabled` | No comments section. |

## Nav config (`config.gleam`)

```gleam
Config(
  title: "arata",
  description: "A blog built with Gleam and Lustre.",
  menu: [
    MenuItem(name: "/posts", url: "/posts"),
    MenuItem(name: "/projects", url: "/projects"),
    MenuItem(name: "/talks", url: "/talks"),
    MenuItem(name: "/about", url: "/about"),
  ],
  socials: [
    Social(name: "GitHub", url: "https://github.com/you/repo", icon: "github"),
    Social(name: "RSS", url: "/atom.xml", icon: "rss"),
  ],
  logo: None,   // or Some("/path/to/logo.png")
)
```

The `Social.icon` field is the filename (without extension) of an SVG in `static/icons/social/`. arata ships 44 social icons (Font Awesome Pro style).

## Theme

The theme toggle cycles Light → Dark → Auto → Light (apollo's `toggle-auto` mode). The choice is persisted to `localStorage["theme-storage"]` and the system preference is respected when `Auto` is selected.
