# DevHeal Portal

**Developer portal for DevHeal Labs AI products — built with NC UI.**

## Overview

The DevHeal Portal is a single-page developer portal showcasing all DevHeal Labs AI products: NC Language, NC UI, NC AI, HiveANT, SwarmOps, and NeuralEdge. It includes live code examples, product cards, and quick-start guides.

## Structure

```
devheal-portal/
└── ui/
    ├── portal.ncui          # NC UI component definition
    ├── portal.html          # Compiled HTML output
    ├── portal.css           # Styles
    ├── portal.js            # Interactive behavior
    └── vercel.json          # Deployment config
```

## Quick Start

Open `ui/portal.html` in a browser, or deploy to any static hosting platform.

## Deployment

Deployment configs are included for:
- **Vercel** — `vercel.json`
- **Azure Static Web Apps** — `staticwebapp.config.json`

Security headers are defined in `portal.security-headers.json`.

## License

Apache 2.0 — see [LICENSE](LICENSE).
