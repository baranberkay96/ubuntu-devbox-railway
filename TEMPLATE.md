# Ubuntu 24.04 Cloud Dev Box (SSH + Claude Code): Railway template spec

## Listing

| Field | Value |
|---|---|
| Name | **Ubuntu 24.04 Cloud Dev Box (SSH + Claude Code)** (46 chars, as given) |
| Description | Always-on Ubuntu box with SSH, tmux and AI coding CLIs on persistent disk. (74 chars, as given) |
| Category | Other |
| Tags | ubuntu, ssh, devbox, tmux, claude-code, codex, gemini-cli, opencode, web-terminal, ai-coding |
| Icon | `https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/ubuntu-linux.svg` (200, image/svg+xml) |
| Expected template code | `ubuntu-2404-cloud-dev-box-ssh-claude-cod` (Railway slug, truncated to 40 chars; the README deploy button uses it, confirm after publishing) |

The description is delivered as written: the service runs continuously (restart policy ALWAYS, no sleep), SSH through a TCP proxy, tmux, Claude Code, Codex CLI, Gemini CLI and OpenCode preinstalled, and `/home` on a Railway volume.

## Base market template

- **Base: `ubuntu-ssh-claude`** ("Ubuntu SSH + Claude" by parham7991, 4,184 active projects, 4,328 deploys in 30 days). Kept what users pick it for: Ubuntu 24.04, SSH over a TCP proxy that the template creates, Claude Code ready to run, tmux. MIT-licensed, but no file was adapted. Problems fixed: no volume (everything is lost on redeploy; it pushes `/root/src` to a GitHub repo as a workaround), root login with a password the user must type, host keys baked at build time (they change on every rebuild), unpinned `npm install -g @anthropic-ai/claude-code`, a default `~/.claude/settings.json` that routes Claude Code to a free third-party model through OpenRouter, no healthcheck, no other AI CLIs.
- `ubuntu-sshd-1` (georgebrnv, 452 active, MIT): Ubuntu **22.04**, non-root sudo user, root login off (kept), but required user-typed credentials with insecure script defaults (`myuser`/`mypassword`), no volume, no healthcheck.
- `ubuntu-2604-web-terminal` (decoge, 508 active, no license, read only): ttyd with basic auth on the public domain (idea kept, behind Caddy), but Ubuntu 26.04 interim release, ttyd downloaded from `releases/latest` at build, required user-typed credentials, the shell runs as root.
- No README text was reused.

## Pinned versions

| Component | Source | Version | Released | Checked |
|---|---|---|---|---|
| Base image | `ubuntu:noble-20260930.1@sha256:68ee2200…aff33ac` (= `24.04` today) | Ubuntu 24.04 LTS | pushed 2026-10-17 | 2026-10-20 |
| OpenSSH | Ubuntu `openssh-server` (noble-updates) | 9.6p1 | distro | 2026-10-20 |
| Node.js | nodejs.org tarball, SHA-256 pinned | 24.22.0 (LTS "Krypton") | 2026-10-14 | 2026-10-20 |
| Claude Code | Anthropic apt repo, `stable` channel, key fingerprint pinned | 2.1.292-1 | 2026-10-06 | 2026-10-20 |
| OpenAI Codex CLI | npm `@openai/codex` (`latest`) | 0.163.0 | 2026-10-15 | 2026-10-20 |
| Gemini CLI | npm `@google/gemini-cli` (`latest`) | 0.64.0 | 2026-10-13 | 2026-10-20 |
| OpenCode | npm `opencode-ai` (`latest`) | 1.19.3 | 2026-10-16 | 2026-10-20 |
| uv | Astral installer `astral.sh/uv/0.13.1/install.sh` | 0.13.1 | 2026-10-14 | 2026-10-20 |
| GitHub CLI | cli.github.com apt repo | 2.102.0 | 2026-09-30 | 2026-10-20 |
| ttyd | GitHub release binary, SHA-256 pinned | 1.7.7 (latest) | 2024-03-30 | 2026-10-20 |
| Caddy | GitHub release tarball, SHA-512 pinned | 2.11.7 | 2026-10-03 | 2026-10-20 |

All pins are `PIN_*` build args at the top of `services/devbox/Dockerfile` (the prefix avoids collisions with the tools' own env variables, Rule 8.10). Claude Code uses the apt `stable` channel version rather than npm `latest` (2.1.303). Node 26 becomes LTS on 2026-10-28; switching is a one-line bump plus the two checksums. Users can upgrade CLIs without a rebuild: `npm i -g <pkg>@latest` installs into `~/.npm-global` and `claude install` installs a self-updating Claude Code into `~/.local/bin`. Both are on the volume and come first in `PATH`.

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
             │ claude · codex · gemini · opencode · gh · node 24 · python 3  │
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
- `Dockerfile`: digest-pinned Ubuntu 24.04, apt toolchain, user `dev` (UID 1000, passwordless sudo, stock `ubuntu` user removed), checksum-verified Node.js, ttyd and Caddy, signed apt repos for gh and Claude Code (key fingerprint checked), uv installer, npm CLIs, PAM tweaks for containers (`pam_loginuid` optional, Ubuntu's dynamic motd off), host keys removed from the image, tool versions recorded in `/etc/devbox/versions.txt`.
- `rootfs/usr/local/bin/devbox-entrypoint` (bash): validates inputs, un-exports `SSH_PASSWORD`/`WEB_PASSWORD` so no child process inherits them, seeds `/home/dev` on first boot (non-recursive ownership repair afterwards), writes API keys and Railway info to `/etc/devbox/env.sh` (0640 root:dev), configures git and the gh credential helper, generates ed25519 and RSA host keys once on the volume, sets SSH auth, renders and tests `sshd_config`, starts sshd and ttyd under `supervise`, renders the status page, starts background jobs (`APT_PACKAGES`, `GIT_REPO`), hashes `WEB_PASSWORD` with bcrypt, renders and validates the Caddyfile and execs Caddy as `www-data`.
- `rootfs/usr/local/lib/devbox/`: `supervise` (restart loop, 3→30 s backoff, clean TERM), `render-sshd-config`, `render-caddyfile`, `render-status-page`, `render-authorized-keys` (accepts keys one per line, several per line or `\n`-separated; validates each with `ssh-keygen`), `install-apt-packages`, `collect-versions`.
- `rootfs/usr/local/bin/devbox-info` (SSH command, fingerprints, versions), `devbox-web-shell` (ttyd → `tmux new -A -s web`).
- `rootfs/etc/profile.d/devbox.sh` (PATH: `~/.local/bin`, `~/.npm-global/bin`, `~/.cargo/bin`, `~/go/bin` first; `NPM_CONFIG_PREFIX`; env file; login banner), `rootfs/etc/tmux.conf`, `rootfs/etc/devbox/motd.txt`.

SSH hardening (`render-sshd-config`): `PermitRootLogin no`, `AllowUsers dev`, password auth only when `SSH_PASSWORD` is set, `KbdInteractiveAuthentication no`, `PermitEmptyPasswords no`, `MaxAuthTries 3`, `LoginGraceTime 20`, `MaxStartups 10:30:60`, `X11Forwarding no`, `PermitTunnel no`, `LogLevel VERBOSE` (key fingerprints in the deploy logs). TCP and agent forwarding stay on for VS Code Remote-SSH and `ssh -L`. **No fail2ban**: Railway's TCP proxy does not pass the client IP (every connection comes from the proxy), so per-source banning would ban the proxy and lock out the owner. Brute force is instead bounded by the 24-character generated password (about 140 bits), the per-connection limits and `MaxStartups`. If the base moves to OpenSSH ≥ 9.8 (Ubuntu 26.04), set `PerSourcePenalties no` for the same reason.

### Variables

| Variable | Default | Notes |
|---|---|---|
| `SSH_PASSWORD` | `${{secret(24, "<57-char unambiguous alphabet>")}}` | Password SSH for `dev`. Empty = key-only. Minimum 12 characters, else the container exits with an error. |
| `SSH_AUTHORIZED_KEYS` | empty | Recommended. Public keys; invalid entries are skipped with a warning. |
| `WEB_PASSWORD` | `${{secret(24, …)}}` | Basic auth (user `dev`) for the status page and web terminal. Required: an empty value stops the container rather than serving a page without auth. |
| `WEB_TERMINAL` | `true` | `false` removes the `/terminal` route and does not start ttyd. |
| `PORT` | `8080` | Caddy listen port (healthcheck, Rule 8.1). |
| `TZ` | `UTC` | Applied to `/etc/localtime` and shells. |
| `ANTHROPIC_API_KEY`, `CLAUDE_CODE_OAUTH_TOKEN`, `OPENAI_API_KEY`, `GEMINI_API_KEY`, `OPENROUTER_API_KEY` | empty | Optional; every CLI also supports its own login from the terminal. |
| `GITHUB_TOKEN`, `GIT_USER_NAME`, `GIT_USER_EMAIL`, `GIT_REPO` | empty | Optional git setup; `GIT_REPO` is cloned once in the background. |
| `APT_PACKAGES` | empty | Reinstalled in the background at every start (plus `~/.config/devbox/apt-packages`). |
| `DEVBOX_ENV_PASSTHROUGH` | empty | Extra variable names exposed to shells (passwords are always excluded). |
| `RAILWAY_DEPLOYMENT_DRAINING_SECONDS` | `10` | Clean shutdown on redeploy. |

Advanced (not in the template, read by the entrypoint): `SSH_PORT` (default 22; the TCP proxy must target the same port).

No required inputs. The box boots with generated passwords, and users log in to each CLI with their own subscription or key.

## First login

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
5. **Four AI CLIs, pinned, official channels**: Claude Code from Anthropic's signed apt repo (fingerprint checked), Codex, Gemini CLI and OpenCode from their npm packages. No third-party model routing by default.
6. **Healthcheck and PORT** on a public `/healthz` (Rule 8.1); all other HTTP paths need a password. The market templates have no healthcheck.
7. **Status page and optional web terminal** behind basic auth over HTTPS; the browser terminal runs as `dev` in tmux, never as root.
8. **Railway runtime fit** (Rule 8.3): tini as subreaper reaps orphaned agent processes; sshd and ttyd run under a restart loop; restart policy ALWAYS.
9. **System packages that stick**: `APT_PACKAGES` / `~/.config/devbox/apt-packages` are reinstalled at each start.
10. **Supply chain**: base image by digest; Node, ttyd and Caddy checksum-verified; signed apt repos; no `releases/latest` downloads.
11. **Secrets stay out of shells**: passwords are un-exported before any child starts; API keys reach shells through a 0640 env file; the Caddyfile holds only a bcrypt hash.

## Resource estimate

Railway prices: RAM $10/GB-month, vCPU $20/vCPU-month, volume $0.15/GB-month. Estimates, not measurements.

| Profile | RAM | CPU | Volume | $/month |
|---|---|---|---|---|
| Idle (sshd, Caddy, ttyd, nobody connected) | ~0.08 GB | ~0.005 vCPU | 1 GB | ≈ $1 |
| Typical (one AI CLI in tmux for several hours a day, occasional builds) | 0.8 GB avg, 2-3 GB peaks | 0.15 vCPU avg | 5 GB | ≈ $12 |
| Heavy (2-3 agents around the clock, frequent builds) | 2.5 GB avg | 0.6 vCPU avg | 20 GB | ≈ $40 |

AI usage is billed by the respective vendor. Minimum plan: **Trial** boots it (well under 1 GB idle) but builds and agents can hit the 1 GB limit; **Hobby** is the realistic plan (its 5 GB volume cap fits the typical profile); **Pro** for larger volumes and the heavy profile.

## Verification checklist

- [ ] Build completes on Railway; the last Dockerfile step prints `/etc/devbox/versions.txt` with versions for Claude Code 2.1.292, Codex 0.163.0, Gemini CLI 0.64.0, OpenCode 1.19.3, Node v24.22.0, uv 0.13.1, ttyd 1.7.7, Caddy v2.11.7.
- [ ] Deploy logs show the generated host key fingerprints, `SSH auth: password yes, 0 key(s)...`, `starting sshd on port 22`, the `connect with: ssh -p ...` line, and no `no_new_privs` warning.
- [ ] `GET /healthz` returns 200 `ok` without credentials; `GET /` returns 401 without credentials and the status page with `dev`/`WEB_PASSWORD`; the page contains no password.
- [ ] `/terminal/` opens a writable terminal as `dev` attached to tmux session `web`; closing and reopening the tab shows the same session.
- [ ] `ssh -p {port} dev@{tcp-proxy-domain}` works with `SSH_PASSWORD`; `ssh root@...` is refused; `sudo -n true` works.
- [ ] With a key in `SSH_AUTHORIZED_KEYS` and `SSH_PASSWORD` cleared: key login works, password login is refused.
- [ ] In a shell: `echo "$SSH_PASSWORD$WEB_PASSWORD"` prints nothing; `claude --version`, `codex --version`, `gemini --version`, `opencode --version`, `node -v`, `uv --version`, `gh --version`, `devbox-info` work.
- [ ] `claude` login completes over SSH (URL + pasted code); `codex login --device-auth` completes.
- [ ] Persistence: create `~/workspace/test.txt`, `npm i -g cowsay`, log in to a CLI, redeploy. All survive, `which cowsay` is under `~/.npm-global/bin`, and the SSH client reports no host key change.
- [ ] `APT_PACKAGES=figlet`: `figlet` is installed a minute after start (`/var/log/devbox-apt.log`), and again after a redeploy.
- [ ] `sudo pkill -f 'sshd -D -e'` → a new sshd listener is up within ~3 s (supervise), the current session survives.
- [ ] `WEB_TERMINAL=false` → `/terminal/` returns 404, the status page still works.

## Open questions

- **Not built locally** (no Docker by instruction): the first Railway build is the first build of this Dockerfile. Every package name, tag, digest, URL and checksum was checked against the registries; the scripts were syntax-checked and the renderers run locally (see the round 4 report).
- **Caddyfile not run through Caddy locally** (no Caddy binary here). It follows the v2.11.7 docs and source; the entrypoint runs `caddy validate` before starting and exits with a clear error if it is invalid.
- **ttyd `--interface 127.0.0.1`**: libwebsockets accepts an IP or an interface name; if it rejected the IP, ttyd would restart in a loop and `/terminal/` would return 502 (SSH unaffected). Fallback: `--interface lo`.
- **Basic auth on the ttyd WebSocket through Railway's edge**: browsers resend same-origin basic auth credentials on the upgrade request; not tested on Railway.
- **sudo on Railway**: works only if the runtime does not set `no_new_privs`; the entrypoint logs a warning if it does. SSH login itself does not depend on it.
- **PAM password login in Railway's container runtime** (`pam_loginuid` made optional as a precaution) and `RAILWAY_TCP_PROXY_*` being present on the very first deploy are assumed from the market leader working on Railway.
- **Claude Code apt retention**: the stable repo currently keeps 62 versions; when 2.1.292-1 is pruned, bump `PIN_CLAUDE_CODE_DEB`.
- **CLI sandboxes**: Claude Code's bubblewrap sandbox and Codex's Linux sandbox may be blocked by Railway's runtime (no user namespaces); then the CLIs run without their sandbox inside the container boundary.
- **Gemini CLI**: since 2026-06-18 Google points unpaid and Google One users to Antigravity CLI; the template documents `GEMINI_API_KEY` as the remote login.
- **Ubuntu `mawk`**: the key parser was tested with BWK awk (macOS); it uses only POSIX awk features that mawk 1.3.4 supports.
