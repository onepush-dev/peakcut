"""Railway launcher for PeakCut (upstream app unmodified).

Runs the upstream server (studio.server.main) with one addition: public sign-up is closed unless
PEAKCUT_OPEN_SIGNUP=1, so strangers who find the URL cannot create accounts and use your CPU or AI key.
The owner account is created on first boot by railway/start.sh, which authenticates its sign-up call with
the X-Railway-Bootstrap header (the owner password itself).
"""
import hmac
import os

from starlette.responses import JSONResponse

from studio import server

OPEN = os.environ.get("PEAKCUT_OPEN_SIGNUP", "0") == "1"
BOOT = os.environ.get("PEAKCUT_ADMIN_PASSWORD", "")


@server.app.middleware("http")
async def _railway_signup_gate(request, call_next):
    if (not OPEN and request.method == "POST" and request.url.path == "/api/auth/signup"
            and not (BOOT and hmac.compare_digest(request.headers.get("x-railway-bootstrap", ""), BOOT))):
        return JSONResponse({"detail": "Sign-up is closed on this server. Ask the owner, or set PEAKCUT_OPEN_SIGNUP=1."},
                            status_code=403)
    return await call_next(request)


if __name__ == "__main__":
    server.main()
