# PeakCut on Railway

[PeakCut](https://github.com/haziqahmedqasmi/PeakCut) (MIT) — self-hosted AI clipping for long videos and live streams: finds the highlights, reframes to 9:16, burns word-by-word captions and can post to YouTube Shorts, Instagram Reels and TikTok. Deploy it on Railway with one click.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/D_H2dh)

## What this template runs

- **peakcut**: `ghcr.io/onepush-dev/peakcut:b3e403e` — the upstream Dockerfile built unmodified at commit `b3e403e` (no releases yet), plus a start wrapper. Public HTTPS domain on port 8080, healthcheck `/healthz`, volume at `/data` (videos, clips and the ~480 MB speech model downloaded on first start).
- **Postgres**: Railway PostgreSQL with a volume (accounts, jobs, AI usage).

## Variables

| Service | Variable | Value | Notes |
|---|---|---|---|
| peakcut | `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` | Converted to the `postgresql+psycopg://` form at boot. |
| peakcut | `PEAKCUT_PUBLIC_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Used in links, OAuth redirects and emails. |
| peakcut | `PEAKCUT_ADMIN_PASSWORD` | generated secret | Password of the owner account created on first boot. |
| Postgres | `POSTGRES_PASSWORD`, `DATABASE_URL`, `PGHOST`, `PGPASSWORD`, `PGDATA` | generated / references | Standard connection values. |

Baked into the image: `PEAKCUT_PORT=8080`, `PEAKCUT_DATA=/data`, `PEAKCUT_TRUST_PROXY=1`, `PEAKCUT_ACCOUNTS=1` (sign-in on), `PEAKCUT_OPEN_SIGNUP=0` (public sign-up closed), `PEAKCUT_ADMIN_EMAIL=admin@peakcut.local`, `PEAKCUT_UPDATE_CHECK=0`.

## How to use

1. Deploy, open the domain, sign in as `admin@peakcut.local` with `PEAKCUT_ADMIN_PASSWORD` (peakcut service → Variables). The account is an admin (`/admin`). Change the email and password in Settings.
2. Optional: add an AI key under **Settings, AI** (Gemini, OpenAI, Groq, OpenRouter, Anthropic…). Without one, clips are picked by loudness only.
3. Paste a YouTube/Twitch/Kick link or upload a video. The first job waits until the speech model has downloaded (a few minutes after the first boot).

## Notes

- **Sign-up is closed** so strangers cannot use your CPU or AI key. To let others register, set `PEAKCUT_OPEN_SIGNUP=1` (and keep the per-user limits in mind: `PEAKCUT_MAX_JOBS_PER_USER`, `PEAKCUT_MAX_USER_GB`, ...).
- Transcription and rendering are CPU-heavy. Give the service several vCPUs and a few GB of RAM for real use.
- YouTube sometimes refuses downloads from data-centre IPs; uploads and Twitch/Kick links keep working.
- Posting to YouTube/Instagram/TikTok and SMTP are optional; see upstream `DEPLOY.md`.
- Not affiliated with PeakCut.
