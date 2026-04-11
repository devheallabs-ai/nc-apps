# NC Apps — Reference Applications

A collection of full-stack applications built with **NC** (backend) and **NC UI** (frontend), demonstrating real-world patterns for building production-grade software.

## Applications

| App | Description |
|-----|-------------|
| **stock-market** | Real-time stock market dashboard with live data feeds |
| **devheal-portal** | Developer portal with documentation and API playground |
| **enterprise-ops-dashboard** | Enterprise operations monitoring and management |
| **hiveant-dashboard** | HiveAnt swarm intelligence visualization dashboard |
| **swarmops-dashboard** | SwarmOps distributed operations control center |
| **world-model** | World model simulation and visualization platform |

## Structure

Each app follows the same layout:

```
app-name/
├-- backend/          # NC service files (.nc)
├-- ui/               # NC UI frontend files (.ncui / .html)
├-- start.sh          # Launch script
├-- README.md         # App-specific docs
└-- LICENSE           # Apache 2.0
```

## Getting Started

1. Install the [NC language](https://github.com/devheallabs-ai/nc)
2. Navigate to any app directory
3. Run `bash start.sh` (or `nc serve backend/service.nc`)

## Links

- **NC Language**: [github.com/devheallabs-ai/nc](https://github.com/devheallabs-ai/nc)
- **NC UI**: [github.com/devheallabs-ai/nc-ui](https://github.com/devheallabs-ai/nc-ui)
- **NC AI SDK**: [github.com/devheallabs-ai/nc-ai](https://github.com/devheallabs-ai/nc-ai)
- **Website**: [devheallabs.in](https://devheallabs.in)
- **Contact**: support@devheallabs.in

## License

Apache License 2.0 — see [LICENSE](LICENSE).
