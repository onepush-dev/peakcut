# PeakCut on Railway. BASE is the upstream Dockerfile built unmodified at commit b3e403e
# (haziqahmedqasmi/PeakCut, MIT; there are no releases yet, so the commit is pinned).
# This layer bakes Railway defaults (plain template values don't survive template generation): port 8080,
# sign-in on, a closed public sign-up, and a start wrapper that creates the owner account on first boot.
ARG BASE=ghcr.io/onepush-dev/peakcut-upstream:b3e403e
FROM ${BASE}
LABEL org.opencontainers.image.source="https://github.com/onepush-dev/peakcut"
COPY railway/serve.py /app/railway_serve.py
COPY railway/start.sh /app/railway_start.sh
ENV PEAKCUT_PORT=8080 \
    PEAKCUT_HOST=0.0.0.0 \
    PEAKCUT_DATA=/data \
    PEAKCUT_TRUST_PROXY=1 \
    PEAKCUT_ACCOUNTS=1 \
    PEAKCUT_OPEN_SIGNUP=0 \
    PEAKCUT_ADMIN_EMAIL=admin@peakcut.local \
    PEAKCUT_UPDATE_CHECK=0
EXPOSE 8080
HEALTHCHECK NONE
CMD ["/bin/sh", "/app/railway_start.sh"]
