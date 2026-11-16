#!/bin/sh
# Railway start wrapper for PeakCut. Starts the server, waits for /healthz, and on first boot creates the
# owner account (PEAKCUT_ADMIN_EMAIL / PEAKCUT_ADMIN_PASSWORD) and makes it an admin with upstream's own
# `python -m studio.admin grant`, so a fresh public URL is never open for someone else to claim.
if [ -z "${PEAKCUT_PUBLIC_URL:-}" ] && [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  export PEAKCUT_PUBLIC_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
fi
case "${DATABASE_URL:-}" in
  postgresql://*) export DATABASE_URL="postgresql+psycopg://${DATABASE_URL#postgresql://}" ;;
  postgres://*) export DATABASE_URL="postgresql+psycopg://${DATABASE_URL#postgres://}" ;;
esac
python /app/railway_serve.py &
PID=$!
trap 'kill -TERM "$PID" 2>/dev/null; wait "$PID"; exit $?' TERM INT
B="http://127.0.0.1:${PEAKCUT_PORT:-8080}"
i=0
until python -c "import urllib.request,sys; urllib.request.urlopen('$B/healthz', timeout=3)" 2>/dev/null; do
  i=$((i+1))
  if ! kill -0 "$PID" 2>/dev/null; then wait "$PID"; exit $?; fi
  [ $i -ge 300 ] && break
  sleep 1
done
if [ -n "${PEAKCUT_ADMIN_PASSWORD:-}" ] && [ -n "${PEAKCUT_ADMIN_EMAIL:-}" ]; then
  python - "$B" <<'PY'
import json, os, sys, urllib.request, urllib.error
b = sys.argv[1]
body = json.dumps({"email": os.environ["PEAKCUT_ADMIN_EMAIL"], "password": os.environ["PEAKCUT_ADMIN_PASSWORD"], "name": "Owner"}).encode()
req = urllib.request.Request(b + "/api/auth/signup", body, {"Content-Type": "application/json", "X-Railway-Bootstrap": os.environ["PEAKCUT_ADMIN_PASSWORD"]})
try:
    urllib.request.urlopen(req, timeout=30)
    print("railway: created the owner account " + os.environ["PEAKCUT_ADMIN_EMAIL"], flush=True)
except urllib.error.HTTPError as e:
    msg = e.read().decode(errors="ignore")[:200]
    if "already" in msg:
        print("railway: owner account already exists", flush=True)
    else:
        print(f"railway: could not create the owner account (HTTP {e.code}): {msg}", file=sys.stderr, flush=True)
PY
  python -m studio.admin grant "$PEAKCUT_ADMIN_EMAIL" >/dev/null 2>&1 && echo "railway: ${PEAKCUT_ADMIN_EMAIL} is an admin; sign in with PEAKCUT_ADMIN_PASSWORD from this service's Variables tab"
fi
wait "$PID"
