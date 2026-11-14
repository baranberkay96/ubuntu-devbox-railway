# Ubuntu Dev Box shell environment.
# Sourced by login shells (/etc/profile.d) and interactive shells (/etc/bash.bashrc);
# safe to source more than once.

if [ "$(id -u)" -ne 0 ]; then
  # Per-user installs on the persistent volume take precedence over the image's
  # tools, so `npm i -g <cli>@latest`, `claude install`, pipx or `uv tool install`
  # upgrade a CLI without rebuilding the image.
  for devbox_dir in "${HOME}/go/bin" "${HOME}/.cargo/bin" "${HOME}/.npm-global/bin" "${HOME}/.local/bin"; do
    case ":${PATH}:" in
      *":${devbox_dir}:"*) ;;
      *) PATH="${devbox_dir}:${PATH}" ;;
    esac
  done
  unset devbox_dir
  export PATH
  export NPM_CONFIG_PREFIX="${HOME}/.npm-global"
  # The image's Claude Code is pinned in the Dockerfile and cannot update itself;
  # after `claude install` the copy in ~/.local/bin updates on its own.
  if [ ! -e "${HOME}/.local/bin/claude" ]; then
    export DISABLE_AUTOUPDATER=1
  fi
fi
export EDITOR="${EDITOR:-nano}"
export LANG="${LANG:-C.UTF-8}"

# Clients such as Ghostty send a TERM this image has no terminfo for; fall back
# so tmux, editors and the AI CLIs still render.
if [ -n "${TERM:-}" ] && command -v infocmp >/dev/null 2>&1 && ! infocmp "${TERM}" >/dev/null 2>&1; then
  export TERM=xterm-256color
fi

# API keys, git and Railway settings from the service variables (written at
# container start, readable by root and dev only).
if [ -r /etc/devbox/env.sh ]; then
  . /etc/devbox/env.sh
fi

# Short overview once per login (and in the first pane of the web terminal).
if [ -t 1 ] && [ -z "${DEVBOX_MOTD_SHOWN:-}" ] && [ -r /etc/devbox/motd.txt ]; then
  case "${TMUX_PANE:-none}" in
    none|%0)
      cat /etc/devbox/motd.txt
      if [ -r "${HOME}/.config/devbox/upgrade-notice.txt" ]; then
        cat "${HOME}/.config/devbox/upgrade-notice.txt"
        echo
      fi
      export DEVBOX_MOTD_SHOWN=1
      ;;
  esac
fi
