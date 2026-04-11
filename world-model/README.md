# World Model Dashboard

**Analytics and world model visualization dashboard — built with NC UI.**

## Overview

The World Model dashboard provides a comprehensive analytics view with user metrics, revenue tracking, page views, session duration, deployment counts, and uptime monitoring.

## Features

- Overview metrics: Users, Revenue, Page Views, Avg Session Duration
- Performance tracking: Conversion rates, Team Activity
- Monthly highlights: Deployments, Uptime, NPS scores
- Settings configuration panel

## Structure

```
world-model/
├── start.sh                    # Launcher script
└── ui/
    ├── dashboard.ncui          # NC UI component definition
    ├── dashboard.html          # Compiled HTML output
    ├── dashboard.css           # Styles
    ├── dashboard.js            # Interactive behavior
    └── vercel.json             # Deployment config
```

## Quick Start

```bash
bash start.sh
```

Or open `ui/dashboard.html` directly in a browser.

## License

Apache 2.0 — see [LICENSE](LICENSE).
