# Ubuntu 26.04 SSH + Claude Code Dev Box: Railway template spec

## Listing

| Field | Value |
|---|---|
| Name | **Ubuntu 26.04 SSH + Claude Code Dev Box** (38 chars; renamed 2026-11-14 from "Ubuntu 24.04 Cloud Dev Box (SSH + Claude Code)") |
| Description | SSH + Claude Code in one click, no setup: web terminal, persistent disk. (72 chars) |
| Category | Other |
| Tags | ubuntu, ssh, claude-code, web-terminal, devbox, tmux, codex, gemini-cli, opencode, ai-coding (the first five are sent to Railway) |
| Icon | `https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/ubuntu-linux.svg` (200, image/svg+xml) |
| Template id / code | `b9e979fe-1bdf-4029-a05c-6d0c834137b6` / `ubuntu-2404-cloud-dev-box-ssh-claude-cod` (the code keeps the old name; renaming does not change it) |
| `idSeed` | unchanged (`Ubuntu 24.04 Cloud Dev Box (SSH + Claude Code) / 2026-11-07`), so service and volume ids stay the same for the in-place update |

The description is delivered as written: no required inputs (both passwords are generated), SSH through a TCP proxy, a browser terminal on the public URL, Claude Code (plus Codex CLI, Gemini CLI and OpenCode) preinstalled, and `/home` on a Railway volume.

Why the rename (market scan 2026-11-14): the niche "Ubuntu + SSH/terminal + Claude Code" had ~5.4k recent deploys, almost all on `ubuntu-ssh-claude` ("Ubuntu SSH + Claude"), whose health is 0 (its entrypoint exits 1 when `ROOT_PASSWORD` is not set). The new name puts the words people search for first and keeps the pinned release in the name.

## Base market template

- **Base: `ubuntu-ssh-claude`** ("Ubuntu SSH + Claude" by parham7991, 4,184 active projects, 4,328 deploys in 30 days). Kept what users pick it for: a current Ubuntu LTS, SSH over a TCP proxy that the template creates, Claude Code ready to run, tmux. MIT-licensed, but no file was adapted. Problems fixed: no volume (everything is lost on redeploy; it pushes `/root/src` to a GitHub repo as a workaround), root login with a password the user must type, host keys baked at build time (they change on every rebuild), unpinned `npm install -g @anthropic-ai/claude-code`, a default `~/.claude/settings.json` that routes Claude Code to a free third-party model through OpenRouter, no healthcheck, no other AI CLIs.
- `ubuntu-sshd-1` (georgebrnv, 452 active, MIT): Ubuntu **22.04**, non-root sudo user, root login off (kept), but required user-typed credentials with insecure script defaults (`myuser`/`mypassword`), no volume, no healthcheck.
- `ubuntu-2604-web-terminal` (decoge, 508 active, no license, read only): ttyd with basic auth on the public domain (idea kept, behind Caddy), but ttyd downloaded from `releases/latest` at build, required user-typed credentials, the shell runs as root.
- No README text was reused.

## Pinned versions

| Component | Source | Version | Released | Checked |
|---|---|---|---|---|
| Base image | `ubuntu:resolute-20261105.1@sha256:66b8084a…71846e` (same platform images as `26.04` today) | Ubuntu 26.04 LTS | pushed 2026-11-12 | 2026-11-14 |
| OpenSSH | Ubuntu `openssh-server` (resolute-updates) | 10.2p1 | distro | 2026-11-14 |
| Python | Ubuntu `python3` | 3.14.3 | distro | 2026-11-14 |
| Node.js | nodejs.org tarball, SHA-256 pinned | 26.13.1 (LTS "Lithium") | 2026-11-10 | 2026-11-14 |
| corepack | npm `corepack` (Node.js 25+ no longer bundles it) | 0.36.0 | | 2026-11-14 |
| Claude Code | Anthropic native release download (`downloads.claude.ai/claude-code-releases`), `stable` channel, SHA-256 pinned | 2.1.311 | 2026-11 | 2026-11-14 (still `stable`) |
| OpenAI Codex CLI | npm `@openai/codex` (`latest`) | 0.169.0 | 2026-11-13 | 2026-11-14 |
| Gemini CLI | npm `@google/gemini-cli` (`latest`) | 0.68.0 | 2026-11-10 | 2026-11-14 |
| OpenCode | npm `opencode-ai` (`latest`) | 1.19.5 | 2026-10-28 | 2026-11-14 |
| uv | GitHub release tarball, SHA-256 pinned (was: Astral install script) | 0.13.8 | 2026-11-12 | 2026-11-14 |
| GitHub CLI | GitHub release tarball, SHA-256 pinned | 2.104.0 | 2026-11-12 | 2026-11-14 |
| ttyd | GitHub release binary, SHA-256 pinned | 1.7.7 (latest) | 2024-03-30 | 2026-11-14 |
| Caddy | GitHub release tarball, SHA-512 pinned | 2.11.9 | 2026-11-05 | 2026-11-14 |

All pins are `PIN_*` build args at the top of `services/devbox/Dockerfile` (the prefix avoids collisions with the tools' own env variables, Rule 8.10). Every download is a release artifact that stays downloadable, checked against the vendor's published checksum and fetched with `--retry 5 --retry-all-errors` (Rule 8.27); npm versions are immutable once published. Claude Code follows Anthropic's `stable` channel rather than `latest` (2.1.325). Users can upgrade CLIs without a rebuild: `npm i -g <pkg>@latest` installs into `~/.npm-global` and `claude install` installs a self-updating Claude Code into `~/.local/bin`. Both are on the volume and come first in `PATH`.

### Ubuntu 24.04 → 26.04 (2026-11-14)

- Base `noble-20260930.1` → `resolute-20261105.1`; `dnsutils` → `bind9-dnsutils` (the transitional package is gone); `sudo` stays classic sudo 1.9.17 (`sudo-rs` is not installed).
- OpenSSH 9.6 → 10.2: `PerSourcePenalties no` added (every client arrives from the TCP proxy's address). Existing ed25519/RSA host keys on the volume keep working.
- Node.js 24 → 26 LTS; corepack now comes from npm. uv now from the checksum-verified release tarball instead of the install script.
- Existing volumes: `/home/dev` (UID 1000), `/home/.devbox/ssh` host keys and dotfiles are used as they are. The entrypoint records the release in `/home/.devbox/os-version-id`; on the first start after the release changes it logs a warning and writes `~/.config/devbox/upgrade-notice.txt` (shown at login until deleted) with the reinstall commands for pipx apps, uv tools and virtualenvs (their interpreters pointed at Python 3.12) and native npm addons (Node ABI change).

## Architecture

```
 ssh -p {proxy port} dev@{proxy host} ── Railway TCP proxy ──► :22   sshd (user dev only)
 Browser ── HTTPS (Railway edge) ──► :8080 Caddy ─┬─ /healthz      public "ok"
                                                  ├─ /             status page   ┐ basic auth
                                                  └─ /terminal/*   ttyd ─► tmux  ┘ dev / WEB_PASSWORD
             ┌──────────────────────────────────────────────────────────────┐
             │ Dev Box (Dockerfile in services/devbox)                       │
             │ Railway init (PID 1) → tini -s -g → devbox-entrypoint (root)  │
             │   ├─ supervise sshd -D            (restart loop, backoff)      │
             │   ├─ supervise ttyd 127.0.0.1:7681 as dev (optional)           │
             │   └─ exec caddy run :$PORT as www-data                        │
             │ claude · codex · gemini · opencode · gh · node 26 · python 3  │
             │ uv · pipx · build-essential · tmux · git · rg · fd · jq       │
             │ volume /home: /home/dev ($HOME), /home/.devbox (host keys)    │
             └──────────────────────────────────────────────────────────────┘
```

## Services

### Dev Box

| Setting | Value |
|---|---|
| Source | repo `baranberkay96/ubuntu-devbox-railway`, root `/services/devbox` (Dockerfile) |
| Start command | none (image entrypoint) |
| Healthcheck | `/healthz` on `PORT=8080` (public, served by Caddy), timeout 300 s |
| Public domain | yes, target port 8080 |
| TCP proxy | 22 (sshd) |
| Volume | `/home` (`/home/dev` is `$HOME`; `/home/.devbox` holds root-only state such as SSH host keys) |
| Restart policy | ALWAYS (no max retries) |
| Replicas | 1 (volume-backed, single user) |

Files in `services/devbox/`:
- `Dockerfile`: digest-pinned Ubuntu 26.04, apt toolchain, user `dev` (UID 1000, passwordless sudo, stock `ubuntu` user removed), checksum-verified release downloads for Node.js, gh, Claude Code, ttyd, Caddy and uv, npm CLIs plus corepack, PAM tweaks for containers (`pam_loginuid` optional, Ubuntu's dynamic motd off), host keys removed from the image, tool versions recorded in `/etc/devbox/versions.txt`.
- `rootfs/usr/local/bin/devbox-entrypoint` (bash): checks inputs without ever exiting on a form value (invalid ports fall back to the defaults; unusable passwords fail closed, see Variables), un-exports `SSH_PASSWORD`/`WEB_PASSWORD` so no child process inherits them, seeds `/home/dev` on first boot (non-recursive ownership repair afterwards), notes an Ubuntu release change on an existing volume (`~/.config/devbox/upgrade-notice.txt`), writes API keys and Railway info to `/etc/devbox/env.sh` (0640 root:dev), configures git and the gh credential helper, generates ed25519 and RSA host keys once on the volume, sets SSH auth, renders and tests `sshd_config`, starts sshd and ttyd under `supervise`, renders the status page, starts background jobs (`APT_PACKAGES`, `GIT_REPO`), hashes `WEB_PASSWORD` with bcrypt, renders and validates the Caddyfile and execs Caddy as `www-data`.
- `rootfs/usr/local/lib/devbox/`: `supervise` (restart loop, 3→30 s backoff, clean TERM), `render-sshd-config`, `render-caddyfile`, `render-status-page`, `render-authorized-keys` (accepts keys one per line, several per line or `\n`-separated; validates each with `ssh-keygen`), `install-apt-packages`, `collect-versions`.
- `rootfs/usr/local/bin/devbox-info` (SSH command, fingerprints, versions), `devbox-web-shell` (ttyd → `tmux new -A -s web`).
- `rootfs/etc/profile.d/devbox.sh` (PATH: `~/.local/bin`, `~/.npm-global/bin`, `~/.cargo/bin`, `~/go/bin` first; `NPM_CONFIG_PREFIX`; env file; login banner), `rootfs/etc/tmux.conf`, `rootfs/etc/devbox/motd.txt`.

SSH hardening (`render-sshd-config`, OpenSSH 10.2): `PermitRootLogin no`, `AllowUsers dev`, password auth only when `SSH_PASSWORD` is set, `KbdInteractiveAuthentication no`, `PermitEmptyPasswords no`, `MaxAuthTries 3`, `LoginGraceTime 20`, `MaxStartups 10:30:60`, `PerSourcePenalties no`, `X11Forwarding no`, `PermitTunnel no`, `LogLevel VERBOSE` (key fingerprints in the deploy logs). TCP and agent forwarding stay on for VS Code Remote-SSH and `ssh -L`. **No fail2ban**: Railway's TCP proxy does not pass the client IP (every connection comes from the proxy), so per-source banning would ban the proxy and lock out the owner. Brute force is instead bounded by the 24-character generated password (about 140 bits), the per-connection limits and `MaxStartups`. OpenSSH's built-in per-source penalties (on by default since 9.8) are off for the same reason.

### Variables

| Variable | Default | Notes |
|---|---|---|
| `SSH_PASSWORD` | `${{secret(24, "<57-char unambiguous alphabet>")}}` | Password SSH for `dev`. Empty = key-only. A trailing newline is trimmed; under 12 characters or an inner line break turns password login off with a warning (fail closed, the deploy still succeeds). |
| `SSH_AUTHORIZED_KEYS` | empty | Recommended. Public keys; invalid entries are skipped with a warning. |
| `WEB_PASSWORD` | `${{secret(24, …)}}` | Basic auth (user `dev`) for the status page and web terminal. 12-72 bytes (bcrypt limit). Empty, too short, too long or a line break: the web login is locked with a random 64-hex password nobody knows and the log says how to fix it; `/healthz` stays up, so the deploy succeeds. Never served without auth. |
| `WEB_TERMINAL` | `true` | `false` removes the `/terminal` route and does not start ttyd. Unknown values keep it off with a warning. |
| `PORT` | `8080` | Caddy listen port (healthcheck, Rule 8.1). Not a number, out of range or colliding with SSH/ttyd: falls back to 8080 with a warning. |
| `TZ` | `UTC` | Applied to `/etc/localtime` and shells. |
| `ANTHROPIC_API_KEY`, `CLAUDE_CODE_OAUTH_TOKEN`, `OPENAI_API_KEY`, `GEMINI_API_KEY`, `OPENROUTER_API_KEY` | empty | Optional; every CLI also supports its own login from the terminal. |
| `GITHUB_TOKEN`, `GIT_USER_NAME`, `GIT_USER_EMAIL`, `GIT_REPO` | empty | Optional git setup; `GIT_REPO` is cloned once in the background. |
| `APT_PACKAGES` | empty | Reinstalled in the background at every start (plus `~/.config/devbox/apt-packages`). |
| `DEVBOX_ENV_PASSTHROUGH` | empty | Extra variable names exposed to shells (passwords are always excluded). |
| `RAILWAY_DEPLOYMENT_DRAINING_SECONDS` | `10` | Clean shutdown on redeploy. |

Advanced (not in the template, read by the entrypoint): `SSH_PORT` (default 22; the TCP proxy must target the same port; invalid values fall back to 22).

No required inputs. The box boots with generated passwords, and users log in to each CLI with their own subscription or key.

## First login

Quickest path: open the public URL, log in as `dev` with `WEB_PASSWORD`, click **Open the web terminal**, run `claude`. Over SSH:

1. Variables tab: copy `SSH_PASSWORD`. The deploy logs show `connect with: ssh -p {port} dev@{tcp-proxy-domain}` (built from `RAILWAY_TCP_PROXY_PORT` and `RAILWAY_TCP_PROXY_DOMAIN`) and the host key fingerprints.
2. `ssh -p {port} dev@{tcp-proxy-domain}`, compare the fingerprint, enter the password.
3. `tmux new -A -s main`, then sign in: `claude`, `codex login --device-auth`, `opencode auth login`, Gemini via `GEMINI_API_KEY`.
4. Optional: open the public URL (user `dev`, `WEB_PASSWORD`) for the status page and `/terminal/`.
5. Recommended: put a public key in `SSH_AUTHORIZED_KEYS`, redeploy, clear `SSH_PASSWORD`.

## Improvements over market templates

1. **Persistent home on a volume** (`/home`): projects, dotfiles, CLI logins (`~/.claude`, `~/.codex`, `~/.gemini`, `~/.local/share/opencode`), `npm -g`/pipx/uv installs and `~/.ssh/authorized_keys` survive redeploys. None of the three market templates mounts a volume for the home directory.
2. **Works out of the box, safely**: `SSH_PASSWORD` and `WEB_PASSWORD` come from `secret()`; zero required inputs. The market templates need user-typed credentials, and the leader logs in as root.
3. **No root SSH**: user `dev` with passwordless sudo, `AllowUsers dev`, hardened sshd (limits above), key-only mode, robust `SSH_AUTHORIZED_KEYS` parsing.
4. **Stable host keys**: generated once on the volume, so no "REMOTE HOST IDENTIFICATION HAS CHANGED" after redeploys; fingerprints are printed in the logs, on the status page and by `devbox-info`.
5. **Four AI CLIs, pinned, official channels**: Claude Code from Anthropic's native release downloads (SHA-256 pinned), Codex, Gemini CLI and OpenCode from their npm packages. No third-party model routing by default.
6. **Healthcheck and PORT** on a public `/healthz` (Rule 8.1); all other HTTP paths need a password. The market templates have no healthcheck.
7. **Status page and optional web terminal** behind basic auth over HTTPS; the browser terminal runs as `dev` in tmux, never as root.
8. **Railway runtime fit** (Rule 8.3): tini as subreaper reaps orphaned agent processes; sshd and ttyd run under a restart loop; restart policy ALWAYS.
9. **System packages that stick**: `APT_PACKAGES` / `~/.config/devbox/apt-packages` are reinstalled at each start.
10. **Supply chain**: base image by digest; Node, ttyd, Caddy, gh, uv and Claude Code checksum-verified release downloads; no `releases/latest` downloads, no vendor apt repositories.
11. **Secrets stay out of shells**: passwords are un-exported before any child starts; API keys reach shells through a 0640 env file; the Caddyfile holds only a bcrypt hash.
12. **No deploy-form value can fail the deploy** (Rule 29): the market leader exits 1 without `ROOT_PASSWORD` (health 0). Here invalid ports fall back to the defaults, and unusable passwords fail closed (SSH password login off, web login locked with a random password) while the box still boots and passes its healthcheck.
13. **In-place upgrades keep user data**: the 24.04 → 26.04 redeploy keeps `/home/dev`, logins and host keys and tells the user which self-installed tools need a reinstall.

## Resource estimate

Railway prices: RAM $10/GB-month, vCPU $20/vCPU-month, volume $0.15/GB-month.

Measured on Railway 2026-11-14 (Ubuntu 26.04 image, nobody running an agent): cgroup `memory.current` ≈ 126 MiB (anon 32 MiB, page cache 85 MiB); largest processes Caddy ~48 MiB RSS, ttyd ~18 MiB, sshd ~7 MiB. The other rows are estimates.

| Profile | RAM | CPU | Volume | $/month |
|---|---|---|---|---|
| Idle (sshd, Caddy, ttyd, nobody connected), measured | ~0.13 GB | ~0.005 vCPU | 1 GB | ≈ $1.5 |
| Typical (one AI CLI in tmux for several hours a day, occasional builds) | 0.8 GB avg, 2-3 GB peaks | 0.15 vCPU avg | 5 GB | ≈ $12 |
| Heavy (2-3 agents around the clock, frequent builds) | 2.5 GB avg | 0.6 vCPU avg | 20 GB | ≈ $40 |

AI usage is billed by the respective vendor. Plans: idle use is about a quarter of Free's 0.5 GB per service and an eighth of Trial's 1 GB, so the box boots on every plan (measured idle; not run on a Free/Trial account). One agent session fits Trial's 1 GB; builds and parallel agents can hit it. **Hobby** is the realistic plan (its 5 GB volume cap fits the typical profile); **Pro** for larger volumes and the heavy profile.

## Verification checklist

Done on Railway 2026-11-14 (test projects deleted afterwards):

- [x] Upgrade path: a box deployed from the published 24.04 template (commit `fdc2cd6`), with a file in `~/workspace`, a file in `~/.claude`, a `~/.bashrc` edit and `npm i -g cowsay`, redeployed on the 26.04 commit: build succeeded, the healthcheck passed, the same SSH host keys (fingerprints unchanged, the existing `known_hosts` entry was accepted), the same `SSH_PASSWORD` worked, all files and `cowsay` were still there, the log warned about the release change and `~/.config/devbox/upgrade-notice.txt` was written.
- [x] Build prints `/etc/devbox/versions.txt`: Ubuntu 26.04.1 LTS, Claude Code 2.1.311, Codex 0.169.0, Gemini CLI 0.68.0, OpenCode 1.19.5, Node v26.13.1, npm 11.20.0, Python 3.14.4, uv 0.13.8, gh 2.104.0, tmux 3.6, OpenSSH 10.2p1, ttyd 1.7.7, Caddy v2.11.9. corepack 0.36.0 gives `pnpm`.
- [x] `GET /healthz` 200 without credentials; `/` and `/terminal/` 401 without or with a wrong password, 200 with `dev`/`WEB_PASSWORD`; the page contains no password; `/terminal/` serves ttyd.
- [x] SSH with `SSH_PASSWORD` works; `sudo -n true` works; `echo "$SSH_PASSWORD$WEB_PASSWORD"` prints nothing in a login shell.
- [x] Deploy-form values (Rule 29): `WEB_PASSWORD=short`, `SSH_PASSWORD=abc`, `WEB_TERMINAL=maybe` → deploy SUCCESS, `/healthz` 200, web login locked (401 even with the short value), SSH offers only public keys, warnings in the log.
- [x] Published template by its real id (`health_sweep.py run 59-ubuntu-devbox`) and a fresh hands-on deploy: see the report in `_reports/health/`.
- [ ] `claude` login completes over SSH (URL + pasted code); `codex login --device-auth` completes (needs real accounts).
- [ ] `APT_PACKAGES=figlet`: `figlet` is installed a minute after start (`/var/log/devbox-apt.log`), and again after a redeploy.
- [ ] With a key in `SSH_AUTHORIZED_KEYS` and `SSH_PASSWORD` cleared: key login works, password login is refused.

## Open questions

- **Self-installed tools after the 24.04 → 26.04 upgrade**: pipx apps, uv tools and virtualenvs on the volume point at Python 3.12, which 26.04 no longer has; global npm packages with native addons were built for Node 24. Files are untouched and the box works, but those tools need the reinstall commands from `~/.config/devbox/upgrade-notice.txt`. Pure-JS npm globals (tested: cowsay) keep working.
- **Codex CLI** prints "failed to clean up stale arg0 temp dirs: Cross-device link" on stderr at start in Railway's build (overlay filesystem); `codex --version` still works. Not seen as a functional problem.
- **CLI sandboxes**: Claude Code's bubblewrap sandbox and Codex's Linux sandbox may be blocked by Railway's runtime (no user namespaces); then the CLIs run without their sandbox inside the container boundary.
- **Gemini CLI**: since 2026-06-18 Google points unpaid and Google One users to Antigravity CLI; the template documents `GEMINI_API_KEY` as the remote login.
- **Vendor apt retention** (fixed 2026-11-07): gh and Claude Code come from release downloads that keep every version, not from vendor apt repositories (Rule 8.27).
