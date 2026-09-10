#!/usr/bin/env sh
#
# Install the Rubric command line.
#
#   curl -fsSL https://raw.githubusercontent.com/rahul-thatipamula/rubric-cli/main/install.sh | sh
#
# Downloads the release built for this machine, verifies it against the
# published checksums, and puts it somewhere on your PATH.

set -eu

REPO="rahul-thatipamula/rubric-cli"
BIN="rubric"

say() { printf "  %s\n" "$1"; }
die() { printf "  error: %s\n" "$1" >&2; exit 1; }

# ------------------------------------------------------------------ platform
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64) ARCH=amd64 ;;
  arm64|aarch64) ARCH=arm64 ;;
  *) die "no build for $ARCH — the source builds anywhere Go does" ;;
esac
case "$OS" in
  darwin|linux) ;;
  *) die "no build for $OS" ;;
esac

# ------------------------------------------------------------------- version
VERSION="${RUBRIC_VERSION:-}"
if [ -z "$VERSION" ]; then
  VERSION=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
    | sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p' | head -1)
fi
[ -n "$VERSION" ] || die "could not work out the latest version — set RUBRIC_VERSION"
say "installing rubric $VERSION for $OS/$ARCH"

# ------------------------------------------------------------------ download
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
FILE="rubric_${VERSION}_${OS}_${ARCH}.tar.gz"
BASE="https://github.com/$REPO/releases/download/v$VERSION"

curl -fsSL "$BASE/$FILE" -o "$TMP/$FILE" || die "no release asset $FILE"

# A download nobody checks is a download anybody can replace. The checksums
# come from the same release, so this catches a corrupted transfer rather than
# a determined attacker — but it catches the thing that actually happens.
if curl -fsSL "$BASE/checksums.txt" -o "$TMP/checksums.txt" 2>/dev/null; then
  EXPECTED=$(grep " $FILE\$" "$TMP/checksums.txt" | awk '{print $1}')
  if [ -n "$EXPECTED" ]; then
    if command -v shasum >/dev/null 2>&1; then
      ACTUAL=$(shasum -a 256 "$TMP/$FILE" | awk '{print $1}')
    else
      ACTUAL=$(sha256sum "$TMP/$FILE" | awk '{print $1}')
    fi
    [ "$EXPECTED" = "$ACTUAL" ] || die "checksum mismatch — not installing"
    say "checksum verified"
  fi
fi

tar -xzf "$TMP/$FILE" -C "$TMP"
chmod +x "$TMP/$BIN"

# ------------------------------------------------------------------- install
# Prefer somewhere already on PATH that this user can write to: asking for a
# password to install a single binary into a personal machine is a poor trade.
TARGET=""
for dir in "$HOME/.local/bin" "$HOME/bin" /usr/local/bin; do
  case ":$PATH:" in
    *":$dir:"*) [ -w "$dir" ] && { TARGET="$dir"; break; } ;;
  esac
done

# Nothing writable on PATH. ~/.local/bin is the conventional home for this, so
# make it — and say plainly that it needs adding to PATH, rather than leaving a
# binary the shell cannot find.
NEEDS_PATH=""
if [ -z "$TARGET" ] && [ -d "$HOME/.local" ] || [ -z "$TARGET" ]; then
  mkdir -p "$HOME/.local/bin" 2>/dev/null || true
  if [ -w "$HOME/.local/bin" ]; then
    TARGET="$HOME/.local/bin"
    case ":$PATH:" in *":$TARGET:"*) ;; *) NEEDS_PATH=1 ;; esac
  fi
fi

if [ -z "$TARGET" ]; then
  TARGET=/usr/local/bin
  say "$TARGET needs a password"
  sudo mv "$TMP/$BIN" "$TARGET/$BIN"
else
  mv "$TMP/$BIN" "$TARGET/$BIN"
fi

say "installed $TARGET/$BIN"

if [ -n "$NEEDS_PATH" ]; then
  printf '\n'
  say "$TARGET is not on your PATH yet. Add it:"
  say "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc && exec zsh"
fi
"$TARGET/$BIN" --version 2>/dev/null || true

printf '\n'
say "next:  export RUBRIC_HOST=https://devrubric.tech"
say "       rubric login"
