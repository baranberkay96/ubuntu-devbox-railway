# syntax=docker/dockerfile:1
#
# Ubuntu 26.04 SSH + Claude Code Dev Box for Railway.
#   - OpenSSH server for the Railway TCP proxy (user "dev", passwordless sudo,
#     no root login, host keys persisted on the volume)
#   - tmux, build tools, Node.js LTS (with corepack), Python 3, uv
#   - Claude Code, OpenAI Codex CLI, Gemini CLI, OpenCode (pinned, official channels)
#   - Caddy on $PORT: public /healthz, password-protected status page and ttyd
#     web terminal
# Persistent data lives on a Railway volume mounted at /home.
#
# Base image pinned by dated tag and digest (Docker Hub library/ubuntu, checked 2026-11-14).
# resolute-20261105.1 = 26.04 LTS "Resolute Raccoon" (same platform images as the 26.04 tag).
FROM ubuntu:resolute-20261105.1@sha256:66b8084a0d45bd4877992bd38e04b51bfa99bd57293364cb6391fb674771846e

# Pinned versions. Bump deliberately; checksums must match the new release.
# Every download retries: a dropped connection fails the whole build, and the
# marketplace health score counts failed builds.
# (PIN_ prefix keeps build args from colliding with the tools' own env variables.)
ARG PIN_NODE=26.13.1
ARG PIN_NODE_SHA256_AMD64=5c063e46bab0fbc1c17cc445d7ff129cbdcd0471be6ed83b6ab864f8143bc864
ARG PIN_NODE_SHA256_ARM64=89e1853138db51e8b82d3e98ba9c0d3f2956a28e5e55ea1b7e12d25aae92d5dd
ARG PIN_COREPACK=0.36.0
ARG PIN_CLAUDE_CODE=2.1.311
ARG PIN_CLAUDE_CODE_SHA256_AMD64=86dc1fcc69498159eaf15f446613e847010f9036bfbbdffd4c49350be8489ada
ARG PIN_CLAUDE_CODE_SHA256_ARM64=2e2496c9a8065df93acb0fca2d341f59a6b8777649b2e025ab8c9bcd5eef61f3
ARG PIN_CODEX=0.169.0
ARG PIN_GEMINI_CLI=0.68.0
ARG PIN_OPENCODE=1.19.5
ARG PIN_UV=0.13.8
ARG PIN_UV_SHA256_AMD64=5acfd9177cfecf0bf87578f059728215ccc884388988f55f7a65041b57387d91
ARG PIN_UV_SHA256_ARM64=74f2f5c6024d397481db228db8fc25eed420db192243f88438c118e7e013e585
ARG PIN_GH=2.104.0
ARG PIN_GH_SHA256_AMD64=98cb101ad87dbbd3f6b2f2bfcbd43197ccd07643140121d8a9cfaa91eadbc24e
ARG PIN_GH_SHA256_ARM64=cb34cefc6f4e77b90731374a2b737516bb8f3033c6ca46aa949e5344f68069e3
ARG PIN_TTYD=1.7.7
ARG PIN_TTYD_SHA256_AMD64=8a217c968aba172e0dbf3f34447218dc015bc4d5e59bf51db2f2cd12b7be4f55
ARG PIN_TTYD_SHA256_ARM64=b38acadd89d1d396a0f5649aa52c539edbad07f4bc7348b27b4f4b7219dd4165
ARG PIN_CADDY=2.11.9
ARG PIN_CADDY_SHA512_AMD64=0e85544340290a16ce4bfb76fe7d65e9de1bf3a6e67f5ccfff30b30d27ea4c73e078077b7bf3e58ae60b6b12e44327705287059c775bca5782e8ee85ea7edd75
ARG PIN_CADDY_SHA512_ARM64=9e5e76d7888542924de2c25353ae87c5f77e2a22c5b1198633cae13688922282e05383d142599205c88d8d80eee5e967d291214d7abce4835329a191b20dd6e0

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=UTC

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Base system and developer toolchain from the Ubuntu archive.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl wget gnupg sudo tini tzdata \
      openssh-server openssh-client \
      tmux git git-lfs build-essential pkg-config \
      python3 python3-dev python3-pip python3-venv python-is-python3 pipx \
      jq ripgrep fd-find unzip zip xz-utils bzip2 zstd less tree file rsync \
      htop nano vim procps psmisc lsof iproute2 iputils-ping bind9-dnsutils netcat-openbsd \
      bash-completion ncurses-term bubblewrap socat sqlite3 \
 && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
 && rm -rf /var/lib/apt/lists/*

# Non-root user "dev" (UID/GID 1000) with passwordless sudo. The stock image
# ships a "ubuntu" user on UID 1000, which is removed first.
RUN userdel -r ubuntu 2>/dev/null || true \
 && groupadd --gid 1000 dev \
 && useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash --groups sudo dev \
 && printf 'dev ALL=(ALL:ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/90-dev \
 && chmod 0440 /etc/sudoers.d/90-dev \
 && visudo -cf /etc/sudoers.d/90-dev

# Node.js LTS from the official nodejs.org tarball, checksum-verified.
RUN case "$(dpkg --print-architecture)" in \
      amd64) node_arch=x64;   node_sha="${PIN_NODE_SHA256_AMD64}" ;; \
      arm64) node_arch=arm64; node_sha="${PIN_NODE_SHA256_ARM64}" ;; \
      *) echo "unsupported architecture: $(dpkg --print-architecture)" >&2; exit 1 ;; \
    esac \
 && curl -fsSL --retry 5 --retry-all-errors -o /tmp/node.tar.xz "https://nodejs.org/dist/v${PIN_NODE}/node-v${PIN_NODE}-linux-${node_arch}.tar.xz" \
 && echo "${node_sha}  /tmp/node.tar.xz" | sha256sum -c - \
 && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 --no-same-owner \
 && rm -f /tmp/node.tar.xz /usr/local/CHANGELOG.md /usr/local/README.md \
 && install -d /usr/local/share/doc/nodejs \
 && mv /usr/local/LICENSE /usr/local/share/doc/nodejs/LICENSE \
 && node --version && npm --version

# GitHub CLI and Claude Code from their vendors' release downloads, checksum-verified.
# Not from their apt repositories: those drop old versions (the GitHub CLI repo
# lists only the newest release), which broke every rebuild of a pinned version.
RUN case "$(dpkg --print-architecture)" in \
      amd64) gh_arch=amd64; gh_sha="${PIN_GH_SHA256_AMD64}"; claude_arch=linux-x64;   claude_sha="${PIN_CLAUDE_CODE_SHA256_AMD64}" ;; \
      arm64) gh_arch=arm64; gh_sha="${PIN_GH_SHA256_ARM64}"; claude_arch=linux-arm64; claude_sha="${PIN_CLAUDE_CODE_SHA256_ARM64}" ;; \
      *) echo "unsupported architecture: $(dpkg --print-architecture)" >&2; exit 1 ;; \
    esac \
 && curl -fsSL --retry 5 --retry-all-errors -o /tmp/gh.tar.gz "https://github.com/cli/cli/releases/download/v${PIN_GH}/gh_${PIN_GH}_linux_${gh_arch}.tar.gz" \
 && echo "${gh_sha}  /tmp/gh.tar.gz" | sha256sum -c - \
 && tar -xzf /tmp/gh.tar.gz -C /tmp --no-same-owner \
 && install -m 0755 "/tmp/gh_${PIN_GH}_linux_${gh_arch}/bin/gh" /usr/local/bin/gh \
 && install -d /usr/local/share/doc/gh /usr/share/bash-completion/completions \
 && install -m 0644 "/tmp/gh_${PIN_GH}_linux_${gh_arch}/LICENSE" /usr/local/share/doc/gh/LICENSE \
 && /usr/local/bin/gh completion -s bash > /usr/share/bash-completion/completions/gh \
 && rm -rf /tmp/gh.tar.gz "/tmp/gh_${PIN_GH}_linux_${gh_arch}" \
 && curl -fsSL --retry 5 --retry-all-errors -o /usr/local/bin/claude "https://downloads.claude.ai/claude-code-releases/${PIN_CLAUDE_CODE}/${claude_arch}/claude" \
 && echo "${claude_sha}  /usr/local/bin/claude" | sha256sum -c - \
 && chmod 0755 /usr/local/bin/claude \
 && gh --version && claude --version

# ttyd (web terminal), Caddy (HTTP front on $PORT) and uv: static release
# binaries, checksum-verified.
RUN case "$(dpkg --print-architecture)" in \
      amd64) ttyd_arch=x86_64;  ttyd_sha="${PIN_TTYD_SHA256_AMD64}"; caddy_arch=amd64; caddy_sha="${PIN_CADDY_SHA512_AMD64}"; uv_arch=x86_64;  uv_sha="${PIN_UV_SHA256_AMD64}" ;; \
      arm64) ttyd_arch=aarch64; ttyd_sha="${PIN_TTYD_SHA256_ARM64}"; caddy_arch=arm64; caddy_sha="${PIN_CADDY_SHA512_ARM64}"; uv_arch=aarch64; uv_sha="${PIN_UV_SHA256_ARM64}" ;; \
      *) echo "unsupported architecture: $(dpkg --print-architecture)" >&2; exit 1 ;; \
    esac \
 && curl -fsSL --retry 5 --retry-all-errors -o /usr/local/bin/ttyd "https://github.com/tsl0922/ttyd/releases/download/${PIN_TTYD}/ttyd.${ttyd_arch}" \
 && echo "${ttyd_sha}  /usr/local/bin/ttyd" | sha256sum -c - \
 && chmod 0755 /usr/local/bin/ttyd \
 && curl -fsSL --retry 5 --retry-all-errors -o /tmp/caddy.tar.gz "https://github.com/caddyserver/caddy/releases/download/v${PIN_CADDY}/caddy_${PIN_CADDY}_linux_${caddy_arch}.tar.gz" \
 && echo "${caddy_sha}  /tmp/caddy.tar.gz" | sha512sum -c - \
 && install -d /usr/local/share/doc/caddy \
 && tar -xzf /tmp/caddy.tar.gz -C /usr/local/bin --no-same-owner caddy \
 && tar -xzf /tmp/caddy.tar.gz -C /usr/local/share/doc/caddy --no-same-owner LICENSE \
 && rm -f /tmp/caddy.tar.gz \
 && curl -fsSL --retry 5 --retry-all-errors -o /tmp/uv.tar.gz "https://github.com/astral-sh/uv/releases/download/${PIN_UV}/uv-${uv_arch}-unknown-linux-gnu.tar.gz" \
 && echo "${uv_sha}  /tmp/uv.tar.gz" | sha256sum -c - \
 && tar -xzf /tmp/uv.tar.gz -C /tmp --no-same-owner \
 && install -m 0755 "/tmp/uv-${uv_arch}-unknown-linux-gnu/uv" "/tmp/uv-${uv_arch}-unknown-linux-gnu/uvx" /usr/local/bin/ \
 && rm -rf /tmp/uv.tar.gz "/tmp/uv-${uv_arch}-unknown-linux-gnu" \
 && ttyd --version && caddy version && uv --version && uvx --version

# OpenAI Codex CLI, Gemini CLI and OpenCode from their official npm packages,
# installed system-wide so the /home volume never hides them. Per-user
# upgrades go to ~/.npm-global (on the volume), which comes first in PATH.
# corepack (yarn/pnpm shims) left the Node.js tarball with Node 25; it comes
# from npm now.
RUN npm install -g --no-fund --no-audit \
      "corepack@${PIN_COREPACK}" \
      "@openai/codex@${PIN_CODEX}" \
      "@google/gemini-cli@${PIN_GEMINI_CLI}" \
      "opencode-ai@${PIN_OPENCODE}" \
 && npm cache clean --force \
 && corepack enable \
 && codex --version && gemini --version && opencode --version && corepack --version

# Dev box wiring: entrypoint, renderers, shell profile, tmux defaults.
COPY rootfs/ /
RUN chmod 0755 /usr/local/bin/devbox-* /usr/local/lib/devbox/* \
 && chmod 0644 /etc/profile.d/devbox.sh /etc/tmux.conf /etc/devbox/motd.txt \
 && echo '[ -r /etc/profile.d/devbox.sh ] && . /etc/profile.d/devbox.sh' >> /etc/bash.bashrc \
 && sed -i -E 's/^(session[[:space:]]+)required([[:space:]]+pam_loginuid\.so)/\1optional\2/' /etc/pam.d/sshd \
 && sed -i -E 's/^(session[[:space:]]+optional[[:space:]]+pam_motd\.so)/# \1/' /etc/pam.d/sshd \
 && rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub \
 && install -d -m 0755 /run/sshd /etc/ssh/authorized_keys.d \
 && /usr/local/lib/devbox/collect-versions > /etc/devbox/versions.txt \
 && cat /etc/devbox/versions.txt

ENV PORT=8080
EXPOSE 8080 22

# Railway runs its own init as PID 1, so tini runs as a subreaper (-s) that
# reaps orphaned agent processes and forwards signals to the whole process
# group (-g). The entrypoint starts sshd and ttyd under a restart loop and
# then execs Caddy (the healthchecked process on $PORT).
ENTRYPOINT ["/usr/bin/tini", "-s", "-g", "--", "/usr/local/bin/devbox-entrypoint"]
CMD []
