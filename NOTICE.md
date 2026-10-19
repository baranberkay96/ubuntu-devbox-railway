# NOTICE: Ubuntu 24.04 Cloud Dev Box template

## Software installed in the image

| Component | Source | License | How it is used |
|---|---|---|---|
| Ubuntu 24.04 LTS | `ubuntu:noble-20260930.1@sha256:68ee2200…` (Docker Hub official image) | various (Ubuntu archive packages) | Base OS; apt packages installed unmodified |
| OpenSSH 9.6p1 | Ubuntu `openssh-server` | BSD-style | sshd, configured by our own generated `sshd_config` |
| tmux, git, build-essential, ripgrep, jq, Python 3, pipx, tini and other tools | Ubuntu archive | various (GPL, ISC, MIT, BSD, PSF, ...) | Installed unmodified |
| Node.js 24.22.0 LTS | https://nodejs.org/dist/ official tarball (SHA-256 checked) | MIT (plus bundled dependency licenses, kept in `/usr/local/share/doc/nodejs/LICENSE`) | Runtime for the npm-based CLIs |
| Claude Code 2.1.292 | Anthropic's signed apt repository `downloads.claude.ai/claude-code/apt/stable` (key fingerprint checked) | Proprietary, Anthropic Commercial Terms of Service | Installed unmodified; use is subject to Anthropic's terms |
| OpenAI Codex CLI 0.163.0 | npm `@openai/codex`, https://github.com/openai/codex | Apache-2.0 | Installed unmodified |
| Gemini CLI 0.64.0 | npm `@google/gemini-cli`, https://github.com/google-gemini/gemini-cli | Apache-2.0 | Installed unmodified |
| OpenCode 1.19.3 | npm `opencode-ai`, https://github.com/anomalyco/opencode | MIT | Installed unmodified |
| uv 0.13.1 | Astral installer `astral.sh/uv/0.13.1/install.sh`, https://github.com/astral-sh/uv | MIT or Apache-2.0 | Installed unmodified |
| GitHub CLI 2.102.0 | cli.github.com apt repository, https://github.com/cli/cli | MIT | Installed unmodified |
| ttyd 1.7.7 | GitHub release binary (SHA-256 checked), https://github.com/tsl0922/ttyd | MIT, Copyright (c) 2016-2022 Shuanglei Tao | Web terminal, unmodified binary |
| Caddy 2.11.7 | GitHub release tarball (SHA-512 checked), https://github.com/caddyserver/caddy | Apache-2.0 (license kept in `/usr/local/share/doc/caddy/LICENSE`) | HTTP front with basic auth, unmodified binary |

Product names belong to their owners. This is a community template, not affiliated with Canonical, Anthropic, OpenAI, Google, the OpenCode project or Railway. Users supply their own accounts and keys and are bound by each vendor's terms.

## Upstream sources and docs checked (2026-10-20)

- Docker Hub `library/ubuntu` tags: `noble-20260930.1` = `24.04` = digest `sha256:68ee22004a9109b44973313b02ff7b1de250f1de0f5ecb628d73f579aaff33ac`
- Ubuntu noble, noble-updates and noble-security package indexes (main, universe): every apt package in the Dockerfile exists; `openssh-server` 1:9.6p1-3ubuntu13.19/20
- Claude Code setup docs (https://code.claude.com/docs/en/setup): native installer, signed apt/dnf/apk repositories with `stable`/`latest` channels, npm package; release signing key fingerprint `31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE` (recomputed locally from `claude-code.asc`). apt `stable` index lists `claude-code 2.1.292-1` (62 versions back to 2.1.108)
- Claude Code authentication docs (login code paste for SSH sessions, `claude setup-token`, `CLAUDE_CODE_OAUTH_TOKEN`)
- Codex CLI auth docs (https://learn.chatgpt.com/docs/auth): `codex login --device-auth`, device code login must be enabled in ChatGPT security settings
- Gemini CLI authentication docs: API key or Vertex AI for headless use; unpaid tier and Google One users moved to Antigravity CLI on 2026-06-18
- OpenCode CLI docs: `opencode auth login`, credentials in `~/.local/share/opencode/auth.json`
- npm dist-tags: `@anthropic-ai/claude-code` stable 2.1.292, `@openai/codex` latest 0.163.0, `@google/gemini-cli` latest 0.64.0, `opencode-ai` latest 1.19.3
- Node.js release index and schedule: 24.22.0 is the current LTS (Krypton); 26.x becomes LTS on 2026-10-28
- GitHub releases: ttyd 1.7.7 (`SHA256SUMS`), Caddy v2.11.7 (`caddy_2.11.7_checksums.txt`), uv 0.13.1, gh 2.102.0
- Caddy v2.11.7 source (`modules/caddyhttp/caddyauth/command.go`, `caddyfile.go`): `hash-password` reads stdin up to a newline, `--bcrypt-cost`, raw bcrypt hashes accepted, hash cache on by default
- ttyd 1.7.7 source (`src/server.c`): `--writable`, `--base-path`, `--interface`, `--cwd`; IPv6 off by default
- Railway docs: TCP proxy (HTTP and TCP on one service), variable reference (`RAILWAY_TCP_PROXY_DOMAIN`, `RAILWAY_TCP_PROXY_PORT`), Fair Use Policy

## Market templates and repositories reviewed

| Template / repo | License | Use |
|---|---|---|
| `ubuntu-ssh-claude` / `parham7991/railway-ubuntu-ssh-claude` | MIT, Copyright (c) 2025 Egor | Read for feature expectations (Ubuntu 24.04, SSH over a TCP proxy, Claude Code preinstalled, tmux helper). No files or text adapted. |
| `ubuntu-sshd-1` / `georgebrnv/railway-ubuntu-sshd` | MIT, Copyright (c) 2025 Egor | Read (non-root sudo user, root login disabled). No files or text adapted. |
| `ubuntu-2604-web-terminal` / `decoge/ubuntu-2604-webterminal-railway` | none (all rights reserved) | Read only (ttyd with basic auth). Nothing copied. |

All files in this package (Dockerfile, entrypoint, renderers, profile, tmux.conf, motd, status page and the docs) were written for this template. Patterns for the persistent home, env file and supervised sshd follow our own `22-ai-workstation` template.
