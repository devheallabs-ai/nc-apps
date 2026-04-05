# NeuralEdge Stock App

This app includes:

- `backend/stock_service.nc` — NC backend on port `8000`
- `ui/stock_dashboard.ncui` — NC UI dashboard on port `9001`
- `start.sh` — launcher for backend, UI, or both

## Start

From [nc-apps/stock-market](nc-apps/stock-market):

```bash
./start.sh check
./start.sh backend
./start.sh ui
./start.sh all
```

## Build UI

```bash
./start.sh build-ui
```

This writes `ui/stock_dashboard.html`.
