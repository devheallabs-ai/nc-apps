# HiveANT Dashboard

**Autonomous incident response dashboard — built with NC UI.**

## Overview

HiveANT is an AI-powered autonomous incident response platform. This dashboard provides real-time visibility into active incidents, swarm agent status (12 AI agents), active investigations, and continuous learning metrics.

## Features

- Live incident feed with 3 severity levels
- 12 AI swarm agents: Detection, Investigation, Root Cause, Fix Generation, Validation, Deployment, Learning, Prediction, Architect, Developer, Testing, Reviewer
- Mean Time to Resolve (MTTR) tracking
- Active investigation details with root cause analysis
- Continuous learning section

## Structure

```
hiveant-dashboard/
└── ui/
    ├── hiveant_dashboard.ncui   # NC UI component definition
    ├── hiveant_dashboard.html   # Compiled HTML output
    ├── hiveant_dashboard.css    # Styles
    ├── hiveant_dashboard.js     # Interactive behavior
    └── vercel.json              # Deployment config
```

## Quick Start

Open `ui/hiveant_dashboard.html` in a browser, or deploy to any static hosting platform.

## License

Apache 2.0 — see [LICENSE](LICENSE).
