"""
NC Playground API Server
POST /run  — execute NC code safely, return {output, error}
GET  /health — uptime check

Deploy to Railway / Render / Fly.io with Docker.
Requires the `nc` binary on PATH (built from nc-lang/).
"""

import os
import sys
import uuid
import time
import signal
import subprocess
import tempfile
import textwrap
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel

# ── Config ────────────────────────────────────────────────────────────
NC_BINARY   = os.environ.get("NC_BINARY", "nc")      # path to `nc` binary
TIMEOUT_SEC = int(os.environ.get("NC_TIMEOUT", "10")) # max execution time
MAX_CODE_LEN = int(os.environ.get("MAX_CODE_LEN", "8192"))  # max code bytes
MAX_OUTPUT   = int(os.environ.get("MAX_OUTPUT", "16384"))   # max output bytes

# Blocked keywords — prevent syscall abuse in the sandbox
BLOCKED_PATTERNS = [
    "import os", "import sys", "import subprocess",
    "__import__", "open(",
]

# NC keywords that could do dangerous things in a public sandbox
NC_BLOCKED = [
    "shell(",     # if we ever add it
    "exec(",
    "system(",
]

# ── Sandboxing ────────────────────────────────────────────────────────
def is_safe(code: str) -> tuple[bool, str]:
    """Quick static check — not a security boundary, just rate-limits abuse."""
    if len(code) > MAX_CODE_LEN:
        return False, f"Code too long (max {MAX_CODE_LEN} characters)"
    for pat in NC_BLOCKED:
        if pat in code:
            return False, f"Blocked pattern: {pat}"
    return True, ""


# ── FastAPI app ───────────────────────────────────────────────────────
app = FastAPI(title="NC Playground API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # playground is public; tighten if needed
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

started_at = time.time()


# ── Models ────────────────────────────────────────────────────────────
class RunRequest(BaseModel):
    code: str
    timeout: Optional[int] = None  # per-request override, capped to TIMEOUT_SEC


class RunResponse(BaseModel):
    output: str
    error: str
    elapsed_ms: int


# ── Routes ────────────────────────────────────────────────────────────
@app.get("/health")
def health():
    return {
        "status": "ok",
        "service": "nc-playground",
        "version": "1.0.0",
        "uptime_sec": int(time.time() - started_at),
        "nc_binary": NC_BINARY,
    }


@app.post("/run", response_model=RunResponse)
async def run_code(req: RunRequest):
    code = req.code.strip()
    if not code:
        return RunResponse(output="", error="No code provided", elapsed_ms=0)

    # Static safety check
    ok, reason = is_safe(code)
    if not ok:
        return RunResponse(output="", error=reason, elapsed_ms=0)

    # Resolve timeout
    timeout = min(req.timeout or TIMEOUT_SEC, TIMEOUT_SEC)

    # Write code to a temp file
    tmp_dir = tempfile.gettempdir()
    fname   = f"nc_run_{uuid.uuid4().hex[:8]}.nc"
    fpath   = Path(tmp_dir) / fname

    try:
        fpath.write_text(code, encoding="utf-8")

        t0 = time.monotonic()

        result = subprocess.run(
            [NC_BINARY, str(fpath)],
            capture_output=True,
            text=True,
            timeout=timeout,
            # Restrict environment — pass minimal env
            env={
                "PATH": os.environ.get("PATH", "/usr/local/bin:/usr/bin:/bin"),
                "HOME": tmp_dir,
            },
        )

        elapsed = int((time.monotonic() - t0) * 1000)

        stdout = result.stdout[:MAX_OUTPUT]
        stderr = result.stderr[:MAX_OUTPUT]

        # NC sends errors to stderr; combine with stdout if both present
        output = stdout
        error  = stderr if result.returncode != 0 else ""

        # If process exited cleanly but stderr has warnings, show them too
        if result.returncode == 0 and stderr.strip():
            output = (stdout + "\n" + stderr).strip()

        return RunResponse(output=output, error=error, elapsed_ms=elapsed)

    except subprocess.TimeoutExpired:
        return RunResponse(
            output="",
            error=f"Execution timed out after {timeout} seconds.",
            elapsed_ms=timeout * 1000,
        )
    except FileNotFoundError:
        return RunResponse(
            output="",
            error=f"NC binary not found: '{NC_BINARY}'. Set NC_BINARY env var.",
            elapsed_ms=0,
        )
    except Exception as e:
        return RunResponse(output="", error=f"Internal error: {e}", elapsed_ms=0)
    finally:
        try:
            fpath.unlink(missing_ok=True)
        except Exception:
            pass


# ── Entry point ───────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", "8080"))
    uvicorn.run("server:app", host="0.0.0.0", port=port, reload=False)
