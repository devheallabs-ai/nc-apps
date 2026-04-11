# NC Playground API — Docker image
# Builds the NC binary from source, then runs the Python API server.

# ── Stage 1: Build NC from source ─────────────────────────────────────
FROM gcc:13-bookworm AS nc-builder

WORKDIR /build

COPY nc-lang/ ./nc-lang/

RUN cd nc-lang && \
    make -C engine -j$(nproc) && \
    cp engine/build/nc /usr/local/bin/nc && \
    chmod +x /usr/local/bin/nc

# ── Stage 2: Python API server ─────────────────────────────────────────
FROM python:3.12-slim

# Copy NC binary from builder
COPY --from=nc-builder /usr/local/bin/nc /usr/local/bin/nc

WORKDIR /app

# Install Python deps
COPY nc-apps/playground-server/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy server code
COPY nc-apps/playground-server/server.py .

# Sandbox: run as non-root
RUN useradd -m -u 1001 ncrunner
USER ncrunner

ENV NC_BINARY=/usr/local/bin/nc
ENV NC_TIMEOUT=10
ENV PORT=8080

EXPOSE 8080

CMD ["python", "server.py"]
