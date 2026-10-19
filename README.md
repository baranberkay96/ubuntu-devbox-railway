# Deploy and Host Ubuntu 24.04 Cloud Dev Box with Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/ubuntu-2404-cloud-dev-box-ssh-claude-cod?referralCode=20H68q)

An always-on Ubuntu 24.04 machine you reach over SSH. It comes with tmux, build tools, Node.js, Python and uv, and the AI coding CLIs Claude Code, OpenAI Codex CLI, Gemini CLI and OpenCode. Your home directory, projects and CLI logins live on a persistent volume.

## About Hosting Ubuntu 24.04 Cloud Dev Box

A remote dev box earns its keep when it stays online: agents keep working in tmux after you close your laptop, and you can connect from any computer, tablet or editor. Running one yourself means maintaining a Linux host, SSH access, tooling and storage that survives rebuilds. This community template builds a pinned Ubuntu 24.04 image, runs OpenSSH behind a Railway TCP proxy for the user `dev` (passwordless sudo, no root login), generates the passwords at deploy and keeps the SSH host keys on the volume, so clients never see "host key changed" after a redeploy. A small password-protected status page and an optional browser terminal run on the public URL. You bring your own AI subscriptions or API keys.

## Common Use Cases

- Run Claude Code, Codex, Gemini CLI or OpenCode on long tasks inside tmux and check in from anywhere
- A remote workspace for VS Code Remote-SSH, Cursor, Zed or plain terminal SSH, from any device
- A consistent Linux environment for builds, scripts and experiments, without touching your laptop
- Quick access from a locked-down machine through the browser terminal

## Dependencies for Ubuntu 24.04 Cloud Dev Box Hosting

- A Railway volume mounted at `/home` (included)
- A Railway TCP proxy for SSH on port 22 (included)
- Optional: accounts or API keys for the AI tools you use (Claude Pro/Max/Team or an Anthropic API key, ChatGPT or an OpenAI API key, a Gemini API key, any OpenCode provider)
- Optional: a GitHub token for private repositories

### Deployment Dependencies

- Ubuntu container image: https://hub.docker.com/_/ubuntu
- Claude Code setup and login: https://code.claude.com/docs/en/setup
- OpenAI Codex CLI sign-in: https://learn.chatgpt.com/docs/auth
- Gemini CLI authentication: https://geminicli.com/docs/get-started/authentication/
- OpenCode CLI: https://opencode.ai/docs/cli/
- Railway TCP proxy: https://docs.railway.com/networking/tcp-proxy
- Railway Fair Use Policy: https://railway.com/legal/fair-use

### Implementation Details

| Service | Source | Purpose |
|---|---|---|
| Dev Box | Dockerfile on `ubuntu:noble-20260930.1` (digest-pinned) | sshd on port 22 behind the TCP proxy; Caddy on `PORT` 8080 with a public `/healthz`, a status page and the ttyd web terminal behind basic auth; volume at `/home` |

**Connect over SSH**

1. After the first deploy, open the service's **Variables** tab and copy `SSH_PASSWORD`. The TCP proxy address is in `RAILWAY_TCP_PROXY_DOMAIN` and `RAILWAY_TCP_PROXY_PORT` (also shown under Settings → Networking).
2. Connect: `ssh -p {RAILWAY_TCP_PROXY_PORT} dev@{RAILWAY_TCP_PROXY_DOMAIN}`, for example `ssh -p 11105 dev@roundhouse.proxy.rlwy.net`. The deploy logs print the exact command and the host key fingerprints.
3. Recommended: paste your public key into `SSH_AUTHORIZED_KEYS`, redeploy, then clear `SSH_PASSWORD` for key-only access. Keys you add to `~/.ssh/authorized_keys` also persist.
4. Start a persistent session so agents keep running when you disconnect: `tmux new -A -s main`.

**Status page and web terminal**: open the service's public URL and log in as `dev` with `WEB_PASSWORD`. The page shows the SSH command, an `~/.ssh/config` snippet and the host key fingerprints. The browser terminal at `/terminal/` attaches to the tmux session `web`. Set `WEB_TERMINAL=false` to turn it off. Only `/healthz` is reachable without a password.

**Log in to the AI CLIs** with your own accounts. Each CLI talks to its own vendor unless you configure a different provider:

- Claude Code: run `claude`, open the login URL on your computer, then paste the code back into the terminal. Or set `ANTHROPIC_API_KEY`, or a `CLAUDE_CODE_OAUTH_TOKEN` created with `claude setup-token`.
- Codex CLI: `codex login --device-auth` (enable device code login in your ChatGPT security settings first), or set `OPENAI_API_KEY`.
- Gemini CLI: set `GEMINI_API_KEY` from Google AI Studio. Google sign-in needs an eligible account; try `NO_BROWSER=true gemini`.
- OpenCode: `opencode auth login`, or set `OPENROUTER_API_KEY`.

**What persists**: everything under `/home/dev`: projects in `~/workspace`, CLI logins, dotfiles, and per-user installs (`npm i -g` goes to `~/.npm-global`, plus `pipx`, `uv tool` and `~/.local/bin`). Packages installed with `sudo apt` reset on redeploy; list them in `APT_PACKAGES` or `~/.config/devbox/apt-packages` and they are reinstalled at every start. tmux sessions survive disconnects, not restarts.

**Scaling**: this is a single-user machine, so keep one replica. Raise CPU and RAM in the service settings when builds or parallel agents need more. For a team, deploy one box per person.

**Pinning and upgrades**: Ubuntu, Node.js, Claude Code, Codex, Gemini CLI, OpenCode, uv, gh, ttyd and Caddy versions are build arguments at the top of the Dockerfile; change them and redeploy. For a newer CLI right away, run `npm i -g @openai/codex@latest` (or the Gemini CLI or OpenCode package) as `dev`, or `claude install` for a self-updating Claude Code in `~/.local/bin`. These live on the volume and take precedence over the image.

**Fair use**: this box is for your own development work. Do not use it for cryptocurrency mining, proxies, VPNs or anonymizers, torrenting, or sharing shell access with others; Railway's Fair Use Policy applies and violations can get the account suspended. Docker-in-Docker and UDP (for example mosh) are not available on Railway.

### Why Deploy Ubuntu 24.04 Cloud Dev Box on Railway?

Railway gives the box a TCP proxy for SSH, an HTTPS URL for the status page and a persistent volume, with no server to administer. It keeps your agents running while you are away, and you pay for the CPU and memory the box actually uses.
