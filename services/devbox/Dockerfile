# syntax=docker/dockerfile:1
#
# Ubuntu 24.04 Cloud Dev Box for Railway.
#   - OpenSSH server for the Railway TCP proxy (user "dev", passwordless sudo,
#     no root login, host keys persisted on the volume)
#   - tmux, build tools, Node.js LTS, Python 3, uv
#   - Claude Code, OpenAI Codex CLI, Gemini CLI, OpenCode (pinned, official channels)
#   - Caddy on $PORT: public /healthz, password-protected status page and ttyd
#     web terminal
# Persistent data lives on a Railway volume mounted at /home.
#
# Base image pinned by dated tag and digest (Docker Hub library/ubuntu, checked 2026-10-20).
FROM ubuntu:noble-20260930.1@sha256:68ee22004a9109b44973313b02ff7b1de250f1de0f5ecb628d73f579aaff33ac

# Pinned versions. Bump deliberately; checksums must match the new release.
# (PIN_ prefix keeps build args from colliding with the tools' own env variables.)
ARG PIN_NODE=24.22.0
ARG PIN_NODE_SHA256_AMD64=cc2f601cee82d9a5a233302fe307abc600727035fd7d2c3a3571755989e95008
ARG PIN_NODE_SHA256_ARM64=fef00bb4d36e1c50104a9775a10359beee98f162b4104dd12472c75065c6a143
ARG PIN_CLAUDE_CODE_DEB=2.1.292-1
ARG PIN_CLAUDE_CODE_KEY_FPR=31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE
ARG PIN_CODEX=0.163.0
ARG PIN_GEMINI_CLI=0.64.0
ARG PIN_OPENCODE=1.19.3
ARG PIN_UV=0.13.1
ARG PIN_GH=2.102.0
ARG PIN_TTYD=1.7.7
ARG PIN_TTYD_SHA256_AMD64=8a217c968aba172e0dbf3f34447218dc015bc4d5e59bf51db2f2cd12b7be4f55
ARG PIN_TTYD_SHA256_ARM64=b38acadd89d1d396a0f5649aa52c539edbad07f4bc7348b27b4f4b7219dd4165
ARG PIN_CADDY=2.11.7
ARG PIN_CADDY_SHA512_AMD64=a7a433a1b133efc3c8d10eb0b99d52a24b5ef5c322dc77f5282182b1c0402139ab83f3a99f0c52409df77d20123fb0b523edad8a66d8f5e49136197bf61ef0e7
ARG PIN_CADDY_SHA512_ARM64=3db36ba90c7a6e8dda40ee3dd71fa08844c76b5fb08f61b31e5e78d2ed38e71c51dc7baed875e50d1ca1279196e84302967237386ae87c91ae9f2aaceada682e

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
      htop nano vim procps psmisc lsof iproute2 iputils-ping dnsutils netcat-openbsd \
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
 && curl -fsSLo /tmp/node.tar.xz "https://nodejs.org/dist/v${PIN_NODE}/node-v${PIN_NODE}-linux-${node_arch}.tar.xz" \
 && echo "${node_sha}  /tmp/node.tar.xz" | sha256sum -c - \
 && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 --no-same-owner \
 && rm -f /tmp/node.tar.xz /usr/local/CHANGELOG.md /usr/local/README.md \
 && install -d /usr/local/share/doc/nodejs \
 && mv /usr/local/LICENSE /usr/local/share/doc/nodejs/LICENSE \
 && corepack enable \
 && node --version && npm --version

# GitHub CLI and Claude Code from their vendors' signed apt repositories.
# The Claude Code signing key fingerprint is checked against Anthropic's docs.
RUN install -d -m 0755 /etc/apt/keyrings \
 && curl -fsSLo /etc/apt/keyrings/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg \
 && chmod 0644 /etc/apt/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
 && curl -fsSLo /etc/apt/keyrings/claude-code.asc https://downloads.claude.ai/keys/claude-code.asc \
 && chmod 0644 /etc/apt/keyrings/claude-code.asc \
 && key_fpr="$(gpg --show-keys --with-colons /etc/apt/keyrings/claude-code.asc | awk -F: '$1 == "fpr" { print $10; exit }')" \
 && if [ "${key_fpr}" != "${PIN_CLAUDE_CODE_KEY_FPR}" ]; then \
      echo "Claude Code signing key fingerprint mismatch: '${key_fpr}'" >&2; exit 1; \
    fi \
 && echo "deb [signed-by=/etc/apt/keyrings/claude-code.asc] https://downloads.claude.ai/claude-code/apt/stable stable main" \
      > /etc/apt/sources.list.d/claude-code.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends "gh=${PIN_GH}" "claude-code=${PIN_CLAUDE_CODE_DEB}" \
 && rm -rf /var/lib/apt/lists/* /root/.gnupg \
 && gh --version && claude --version

# ttyd (web terminal) and Caddy (HTTP front on $PORT): static release binaries,
# checksum-verified.
RUN case "$(dpkg --print-architecture)" in \
      amd64) ttyd_arch=x86_64;  ttyd_sha="${PIN_TTYD_SHA256_AMD64}"; caddy_arch=amd64; caddy_sha="${PIN_CADDY_SHA512_AMD64}" ;; \
      arm64) ttyd_arch=aarch64; ttyd_sha="${PIN_TTYD_SHA256_ARM64}"; caddy_arch=arm64; caddy_sha="${PIN_CADDY_SHA512_ARM64}" ;; \
      *) echo "unsupported architecture: $(dpkg --print-architecture)" >&2; exit 1 ;; \
    esac \
 && curl -fsSLo /usr/local/bin/ttyd "https://github.com/tsl0922/ttyd/releases/download/${PIN_TTYD}/ttyd.${ttyd_arch}" \
 && echo "${ttyd_sha}  /usr/local/bin/ttyd" | sha256sum -c - \
 && chmod 0755 /usr/local/bin/ttyd \
 && curl -fsSLo /tmp/caddy.tar.gz "https://github.com/caddyserver/caddy/releases/download/v${PIN_CADDY}/caddy_${PIN_CADDY}_linux_${caddy_arch}.tar.gz" \
 && echo "${caddy_sha}  /tmp/caddy.tar.gz" | sha512sum -c - \
 && install -d /usr/local/share/doc/caddy \
 && tar -xzf /tmp/caddy.tar.gz -C /usr/local/bin --no-same-owner caddy \
 && tar -xzf /tmp/caddy.tar.gz -C /usr/local/share/doc/caddy --no-same-owner LICENSE \
 && rm -f /tmp/caddy.tar.gz \
 && ttyd --version && caddy version

# uv via Astral's official installer, pinned to a release.
RUN curl -fsSL "https://astral.sh/uv/${PIN_UV}/install.sh" \
      | env UV_INSTALL_DIR=/usr/local/bin UV_NO_MODIFY_PATH=1 sh \
 && uv --version && uvx --version

# OpenAI Codex CLI, Gemini CLI and OpenCode from their official npm packages,
# installed system-wide so the /home volume never hides them. Per-user
# upgrades go to ~/.npm-global (on the volume), which comes first in PATH.
RUN npm install -g --no-fund --no-audit \
      "@openai/codex@${PIN_CODEX}" \
      "@google/gemini-cli@${PIN_GEMINI_CLI}" \
      "opencode-ai@${PIN_OPENCODE}" \
 && npm cache clean --force \
 && codex --version && gemini --version && opencode --version

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
