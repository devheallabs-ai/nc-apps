// playground-server API — written in NC to document the interface.
// Actual execution is handled by server.py (Python + subprocess).
// This file shows the API surface in NC notation.
//
// Deploy: Railway / Render / Fly.io using the Dockerfile in this folder.
// Endpoint: https://play-api.nc-lang.dev
//
// Copyright (c) 2025-2026 Nuckala Sai Narender / DevHeal Labs
// Licensed under Apache 2.0

service "nc-playground"
version "1.0.0"

configure:
    port is 8080
    timeout is 10
    max_code_length is 8192
    max_output_length is 16384

middleware:
    cors allow all origins
    rate_limit 60 per minute per ip

// ── POST /run ──────────────────────────────────────────────────────────
// Accepts NC source code, executes it with a 10-second timeout,
// returns output and error as JSON.
//
// Request:  { "code": "show \"hello\"" }
// Response: { "output": "hello\n", "error": "", "elapsed_ms": 12 }
//
to run_code with request:
    purpose: "Execute NC source code safely in a sandboxed subprocess"

    set code to request.code
    if code is empty:
        respond with {output: "", error: "No code provided", elapsed_ms: 0}

    if length(code) is above 8192:
        respond with {output: "", error: "Code too long (max 8192 characters)", elapsed_ms: 0}

    set result to execute code with timeout 10
    respond with {
        output: result.stdout,
        error: result.stderr,
        elapsed_ms: result.duration
    }

// ── GET /health ───────────────────────────────────────────────────────
to health_check:
    purpose: "Service health check for load balancers and monitoring"
    respond with {
        status: "ok",
        service: "nc-playground",
        version: "1.0.0"
    }

api:
    POST /run     runs run_code
    GET  /health  runs health_check
