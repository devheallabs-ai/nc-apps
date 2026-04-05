#!/usr/bin/env bash
# NeuralEdge Stock App Launcher
# Usage:
#   ./start.sh backend   # start NC backend on :8000
#   ./start.sh ui        # start NC UI dev server on :9001
#   ./start.sh all       # start backend + UI together
#   ./start.sh build-ui  # compile UI to stock_dashboard.html
#   ./start.sh check     # validate backend + UI syntax

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BACKEND_FILE="$SCRIPT_DIR/backend/stock_service.nc"
UI_FILE="$SCRIPT_DIR/ui/stock_dashboard.ncui"
UI_HTML="$SCRIPT_DIR/ui/stock_dashboard.html"
BACKEND_PORT="${BACKEND_PORT:-8000}"
UI_PORT="${UI_PORT:-9001}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

info() { echo -e "${CYAN}[INFO]${RESET}  $*"; }
ok()   { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn() { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
fail() { echo -e "${RED}[ERROR]${RESET} $*"; exit 1; }

find_nc() {
    if [ -x "$ROOT_DIR/nc-lang/engine/build/nc" ]; then
        NC_BIN="$ROOT_DIR/nc-lang/engine/build/nc"
    elif command -v nc >/dev/null 2>&1; then
        NC_BIN="$(command -v nc)"
    else
        fail "NC binary not found. Build nc-lang first."
    fi
}

find_node() {
    if command -v node >/dev/null 2>&1; then
        NODE_BIN="$(command -v node)"
    else
        fail "Node.js is required to serve the NC UI."
    fi
}

port_in_use() {
    local port="$1"
    if command -v lsof >/dev/null 2>&1; then
        lsof -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1
    else
        return 1
    fi
}

check_all() {
    find_nc
    find_node
    info "Validating backend..."
    "$NC_BIN" validate "$BACKEND_FILE"
    info "Validating UI..."
    "$NODE_BIN" "$ROOT_DIR/nc-ui/cli.js" check "$UI_FILE"
    ok "Backend and UI validated"
}

start_backend() {
    find_nc
    if port_in_use "$BACKEND_PORT"; then
        warn "Port ${BACKEND_PORT} is already in use. Set BACKEND_PORT to override."
        return 0
    fi
    info "Starting backend on http://localhost:${BACKEND_PORT}"
    NC_ALLOW_EXEC=1 NC_ALLOW_FILE_WRITE=1 NC_ACCEPT_LICENSE=1 \
    NEURALEDGE_STOCK_PORT="$BACKEND_PORT" \
        "$NC_BIN" serve "$BACKEND_FILE"
}

start_ui() {
    find_node
    if port_in_use "$UI_PORT"; then
        warn "Port ${UI_PORT} is already in use. Set UI_PORT to override."
        return 0
    fi
    info "Starting UI on http://localhost:${UI_PORT}"
    "$NODE_BIN" "$ROOT_DIR/nc-ui/cli.js" serve "$UI_FILE" --port "$UI_PORT"
}

build_ui() {
    find_node
    info "Building UI to $UI_HTML"
    "$NODE_BIN" "$ROOT_DIR/nc-ui/cli.js" build "$UI_FILE"
    ok "Built $UI_HTML"
}

start_all() {
    find_nc
    find_node
    BACKEND_PID=""
    if port_in_use "$BACKEND_PORT"; then
        warn "Port ${BACKEND_PORT} is already in use. Reusing the existing backend listener."
    else
        info "Starting backend on http://localhost:${BACKEND_PORT}"
        NC_ALLOW_EXEC=1 NC_ALLOW_FILE_WRITE=1 NC_ACCEPT_LICENSE=1 \
        NEURALEDGE_STOCK_PORT="$BACKEND_PORT" \
            "$NC_BIN" serve "$BACKEND_FILE" &
        BACKEND_PID=$!
    fi

    cleanup() {
        if [ -n "${BACKEND_PID:-}" ]; then kill "$BACKEND_PID" 2>/dev/null || true; fi
    }
    trap cleanup INT TERM EXIT

    if port_in_use "$UI_PORT"; then
        warn "Port ${UI_PORT} is already in use. Set UI_PORT to override."
        return 0
    fi
    info "Starting UI on http://localhost:${UI_PORT}"
    "$NODE_BIN" "$ROOT_DIR/nc-ui/cli.js" serve "$UI_FILE" --port "$UI_PORT"
}

case "${1:-all}" in
    backend) start_backend ;;
    ui) start_ui ;;
    all) start_all ;;
    build-ui) build_ui ;;
    check) check_all ;;
    *)
        echo "Usage: ./start.sh [backend|ui|all|build-ui|check]"
        exit 1
        ;;
esac
