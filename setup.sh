#!/bin/zsh

set -euo pipefail

# Apple Silicon only — Homebrew is assumed at /opt/homebrew here and in
# zsh/.zshrc. Intel Macs are intentionally not supported.

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
# Absolutize without resolving symlinks (:a, not :A). A relative override like
# DOTFILES_DIR=dotfiles would otherwise make STOW_TARGET "." — which, after the
# cd below, is the repo itself; stow then skips every package with a warning
# but exits 0, and the script would announce success having linked nothing.
DOTFILES_DIR="${DOTFILES_DIR:a}"
STOW_TARGET="${DOTFILES_DIR:h}"
DEFAULT_PROFILE="personal"
SCRIPT_NAME="${0:t}"

if [[ "$SCRIPT_NAME" == "zsh" || "$SCRIPT_NAME" == "-zsh" ]]; then
  SCRIPT_NAME="setup.sh"
fi

usage() {
  echo "Usage: $SCRIPT_NAME [personal|work]"
  echo "  With no argument, asks which profile to install."
  echo "  NONINTERACTIVE=1 skips the prompt and installs the $DEFAULT_PROFILE default."
}

# `[[ -r /dev/tty ]]` only checks the file mode, so it succeeds even when the
# process has no controlling terminal and opening /dev/tty would fail. Probe it
# for real, in a subshell so the failed redirection cannot kill this script.
have_tty() {
  ( : < /dev/tty ) 2>/dev/null
}

# Confirm the profile when it was not given on the command line, so that
# forgetting the argument on a work Mac does not silently install the personal
# profile. Nothing has been installed at this point.
confirm_profile() {
  local reply prompt_in="" prompt_out=/dev/stdout

  # Piped into zsh (the README one-liner): stdin is the script itself, so the
  # answer has to come from the controlling terminal. The prompt goes to the
  # same place; otherwise a redirected stdout would leave the script waiting
  # on /dev/tty with no visible question.
  if have_tty; then
    prompt_in=/dev/tty prompt_out=/dev/tty
  elif [[ -t 0 ]]; then
    prompt_in=/dev/stdin
  else
    echo "No profile given and no terminal available to confirm one." >&2
    echo "Re-run as '$SCRIPT_NAME personal' or '$SCRIPT_NAME work'," >&2
    echo "or set NONINTERACTIVE=1 to accept the '$DEFAULT_PROFILE' default." >&2
    exit 1
  fi

  {
    echo "No profile given. Pick one:"
    echo "  personal  Brewfile.common + Brewfile.personal, ghostty config"
    echo "  work      Brewfile.common + Brewfile.work, iterm2 config"
    echo
  } > "$prompt_out"

  while true; do
    printf "Which profile? [p]ersonal / [w]ork / [q]uit: " > "$prompt_out"
    if ! read -r reply < "$prompt_in"; then
      echo >&2
      echo "No answer; aborting without installing anything." >&2
      exit 1
    fi
    case "${reply:l}" in
      p|personal) PROFILE="personal"; break ;;
      w|work)     PROFILE="work"; break ;;
      q|quit)     echo "Aborted." > "$prompt_out"; exit 0 ;;
      # No default on an empty answer: the whole point is a deliberate choice.
      *)          echo "Please answer p, w, or q." > "$prompt_out" ;;
    esac
  done
  echo > "$prompt_out"
}

load_brew_shellenv() {
  [[ -x /opt/homebrew/bin/brew ]] || return 1
  eval "$(/opt/homebrew/bin/brew shellenv)"
}

# Machines provisioned before --no-folding got whole directories folded into
# the repo, so files their programs wrote at runtime (herdr session state,
# logs) physically live inside the package. After unfolding, move every
# gitignored stray out to its real target path so the repo only holds tracked
# config. Finder/editor debris is skipped, not migrated.
migrate_strays() {
  local pkg="$1" stray rel target
  for stray in ${(f)"$(git ls-files --others --ignored --exclude-standard -- "$pkg" 2>/dev/null)"}; do
    [[ -n "$stray" ]] || continue
    case "${stray:t}" in (.DS_Store|*~|'#'*'#') continue ;; esac
    rel="${stray#$pkg/}"
    target="$STOW_TARGET/$rel"
    if [[ -L "$target" && "${target:A}" == "${DOTFILES_DIR:A}/$stray" ]]; then
      rm "$target"   # the restow just linked the stray back home; unlink it
    elif [[ -e "$target" || -L "$target" ]]; then
      mv "$target" "$target$BACKUP_SUFFIX"
    else
      mkdir -p "${target:h}"
    fi
    mv "$stray" "$target"
    echo "Moved runtime file out of the repo: $stray -> $target"
  done
}

# stow aborts an entire package on its first conflict, so a Mac that already
# has a real ~/.zshrc (or ~/.config/ghostty/config) would stop the script
# here. Move anything that is in the way — and not already the exact link stow
# would make — aside first.
stow_pkg() {
  local pkg="$1" rel target
  local -a files
  # Keep the exclusions in sync with what stow will actually link: stow's
  # built-in ignore list covers editor backups (*~, #*#) and the --ignore flag
  # below covers .DS_Store. Backing up a file stow never replaces would make
  # it silently disappear into its .pre-stow name.
  files=("${(@f)$(cd "$pkg" && find . -type f ! -name .stow-local-ignore ! -name '.DS_Store' ! -name '*~' ! -name '#*#' | sed 's|^\./||')}")
  for rel in $files; do
    [[ -n "$rel" ]] || continue
    target="$STOW_TARGET/$rel"
    [[ -e "$target" || -L "$target" ]] || continue
    # Skip only the exact links stow would create itself: relative, resolving
    # to the package file. An absolute symlink resolves identically, but stow
    # treats it as "not owned" and aborts — move it aside like any conflict.
    if [[ "${target:A}" == "${DOTFILES_DIR:A}/$pkg/$rel" && "$(readlink -- "$target" 2>/dev/null)" != /* ]]; then
      continue
    fi
    echo "Backing up $target -> $target$BACKUP_SUFFIX"
    mv "$target" "$target$BACKUP_SUFFIX"
  done
  # --no-folding links leaf files only, never whole directories. Without it
  # stow would collapse a missing ~/.config into a single link into this repo,
  # and then everything that writes to ~/.config would be writing into the
  # dotfiles repo. --restow unfolds any such link left over from an earlier
  # run. .DS_Store is not in stow's default ignore list, so a Finder visit to
  # a package directory would otherwise get it linked into $HOME.
  if ! stow --target="$STOW_TARGET" --no-folding --restow --ignore='\.DS_Store' "$pkg"; then
    echo "stow $pkg failed. Files moved aside this run still end in $BACKUP_SUFFIX." >&2
    exit 1
  fi
  migrate_strays "$pkg"
}

main() {
  PROFILE="${1:-$DEFAULT_PROFILE}"
  # An empty first argument (e.g. a blank $VAR) counts as not given, so it
  # still goes through the confirmation below instead of silently defaulting.
  PROFILE_GIVEN=$(( ${#${1-}} > 0 ))

  case "$PROFILE" in
    personal|work) ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac

  # hw.optional.arm64 is 1 on Apple Silicon even under Rosetta, where uname -m
  # would misreport x86_64.
  if [[ "$(sysctl -n hw.optional.arm64 2>/dev/null)" != 1 ]]; then
    echo "This setup supports Apple Silicon Macs only; Intel is not supported." >&2
    exit 1
  fi

  # NONINTERACTIVE=1 accepts the personal default. It also propagates to the
  # Homebrew installer below, which then cannot prompt for a sudo password —
  # see "Profile confirmation" in the README.
  if (( ! PROFILE_GIVEN )) && [[ -z "${NONINTERACTIVE-}" ]]; then
    confirm_profile
  fi

  echo "Setting up the $PROFILE profile."

  # 1. Install Homebrew if not installed
  local brew_installer
  if ! load_brew_shellenv; then
    brew_installer="$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # When this script is piped into zsh (the README one-liner) stdin is not a
    # TTY. Homebrew then switches to non-interactive mode, probes sudo with
    # `sudo -n`, and aborts with "Need sudo access on macOS" because it cannot
    # prompt for a password. Hand it the controlling terminal instead.
    if [[ -t 0 ]]; then
      /bin/bash -c "$brew_installer"
    elif have_tty; then
      /bin/bash -c "$brew_installer" < /dev/tty
    else
      echo "No terminal available to install Homebrew." >&2
      echo "Install Homebrew first, then re-run $SCRIPT_NAME." >&2
      exit 1
    fi
    if ! load_brew_shellenv; then
      echo "The Homebrew installer finished but brew was not found at /opt/homebrew." >&2
      exit 1
    fi
  fi

  # 2. Clone dotfiles if not cloned
  if [[ ! -d "$DOTFILES_DIR" ]]; then
    git clone --recursive https://github.com/iCell/dotfiles "$DOTFILES_DIR"
  fi

  # 3. Install brew packages
  brew bundle --file="$DOTFILES_DIR/Brewfile.common"
  brew bundle --file="$DOTFILES_DIR/Brewfile.$PROFILE"

  # 4. Give rustup a default toolchain — the formula ships only shims, and
  # rustc/cargo error out with "no default toolchain" until one is set.
  local rustup_bin="$HOMEBREW_PREFIX/opt/rustup/bin/rustup"
  if [[ -x "$rustup_bin" ]] && ! "$rustup_bin" default &>/dev/null; then
    "$rustup_bin" default stable
  fi

  # 5. Stow configs
  cd "$DOTFILES_DIR"
  BACKUP_SUFFIX=".pre-stow-$(date +%Y%m%d%H%M%S)"

  stow_pkg zsh
  stow_pkg herdr

  case "$PROFILE" in
    personal)
      stow_pkg ghostty
      ;;
    work)
      if [[ -d "$DOTFILES_DIR/iterm2" ]]; then
        stow_pkg iterm2
      fi
      ;;
  esac

  echo "Done! Restart your terminal to apply the $PROFILE profile."
}

# Everything effectful lives in main, and this call is the file's last line:
# zsh must have read the whole script before any of it runs, so a truncated
# `curl | zsh` download cannot execute half a script, and child processes
# cannot slurp script text off the stdin pipe.
main "$@"
