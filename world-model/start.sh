#!/bin/bash
# World Model AI — Full Stack Launcher
# Backend: NC (port 8080) | Frontend: NC UI (port 9001)
# Zero cost. Zero cloud. Zero GPU.

set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
NC="$DIR/../../nc-lang/engine/build/nc"
NCUI="$DIR/../../nc-ui/cli.js"

case "${1:-all}" in
  backend)
    echo "Starting World Model API on port 8080..."
    "$NC" serve "$DIR/backend/world_model.nc"
    ;;
  ui)
    echo "Starting Dashboard UI on port 9001..."
    node "$NCUI" serve "$DIR/ui/dashboard.ncui" 9001
    ;;
  build-ui)
    echo "Building dashboard..."
    node "$NCUI" build "$DIR/ui/dashboard.ncui"
    ;;
  check)
    echo "=== Validating Backend ==="
    "$NC" run "$DIR/backend/world_model.nc"
    echo ""
    echo "=== Validating Frontend ==="
    node "$NCUI" check "$DIR/ui/dashboard.ncui"
    echo ""
    echo "=== All checks passed ==="
    ;;
  benchmark)
    echo "Running NC AI benchmark..."
    "$NC" ai benchmark
    ;;
  all)
    echo "=== World Model AI ==="
    echo "Starting backend on :8080 and UI on :9001"
    "$NC" serve "$DIR/backend/world_model.nc" &
    sleep 1
    node "$NCUI" serve "$DIR/ui/dashboard.ncui" 9001
    ;;
  *)
    echo "Usage: ./start.sh [backend|ui|build-ui|check|benchmark|all]"
    ;;
esac
