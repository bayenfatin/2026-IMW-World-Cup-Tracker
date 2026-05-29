# 2026 IMW World Cup Tracker

Office pool web app for the IMW EEC **2026 FIFA World Cup** — currently focused on **group stage ranking predictions**.

**Live site:** https://garyghagimw.github.io/2026-IMW-World-Cup-Tracker/

Branded for [IMW Industries](https://www.imw.ca) — *Driven by knowledge, fueled by Experience*.

## Current phase: Group stage

Players rank all 48 teams across 12 groups (1st–4th). Submissions go to a **SharePoint List** on your Microsoft 365 tenant.

| Rule | Points |
|------|--------|
| Correct position (each of 4 spots) | 1 pt |
| Correct group winner (bonus) | 1 pt |
| **Group stage maximum** | **60 pts** |

**Submission window:** June 1 – June 10, 2026

Knockout bracket picks will be enabled after the group stage window closes.

## SharePoint setup (recommended)

Entries are stored in SharePoint — not as files on your PC. A minimal 3-step Power Automate flow acts as an HTTP gateway (optional glue only).

**Full instructions:** [docs/sharepoint-setup.md](docs/sharepoint-setup.md)

Quick steps:

1. Create SharePoint list `World Cup 2026 Entries`
2. Create Power Automate flow: **HTTP trigger → Create SharePoint item**
3. Paste the HTTP POST URL into `src/data/config.js` → `sharepoint.webhookUrl`

## Admin

- **PIN:** configured in `src/data/config.js` (`adminPin`)
- Unlock via **Admin** tab (session-only — re-enter PIN after closing browser)
- Enter official group results to score the leaderboard
- Import JSON backups from SharePoint exports

## Local development

```bash
npm install
npm run dev
```

## Deploy

Push to `main` — GitHub Actions builds and deploys to Pages.

Enable Pages: **Settings → Pages → GitHub Actions**

## Assets

- IMW logo: `public/assets/imw-logo.png` (from [imw.ca](https://imw.ca))

## Project structure

```
src/
├── main.js                 # UI (group stage focus)
├── data/config.js          # Scoring, dates, SharePoint URL, admin PIN
├── data/groups.js          # Official FIFA 2026 draw
├── lib/sharepoint.js       # Submit entries to SharePoint
├── lib/admin.js            # PIN gate
├── lib/scoring.js          # Group-stage scoring
└── styles/main.css         # IMW-branded light theme
docs/sharepoint-setup.md    # SharePoint + flow guide
```

## License

Internal IMW / EEC use.
