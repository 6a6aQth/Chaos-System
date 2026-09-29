#!/usr/bin/env bash
set -euo pipefail

# Wholesale-replaces this repo's contents with a full standalone DVFP export,
# keeping only docs/ and .git/ intact (.env.example is consumed into a real
# .env, then removed -- see "Environment variables" below).
#
# Usage:
#   ./scripts/nuke.sh path/to/dvfp.zip

BLUE='\033[38;5;33m'
DIM='\033[2m'
BOLD='\033[1m'
GREEN='\033[38;5;42m'
YELLOW='\033[38;5;220m'
RESET='\033[0m'

banner() {
  printf "${BLUE}${BOLD}"
  printf "┌────────────────────────────────────────────┐\n"
  printf "│  👑  MC-DOS · nuke.sh                        │\n"
  printf "│  Next.js · TypeScript · Tailwind · Paychangu │\n"
  printf "└────────────────────────────────────────────┘\n"
  printf "${RESET}\n"
}

section() { printf "${BLUE}${BOLD}== %s ==${RESET}\n" "$1"; }
ok()      { printf "${GREEN}  ✓ %s${RESET}\n" "$1"; }
warn()    { printf "${YELLOW}  ⚠ %s${RESET}\n" "$1"; }
info()    { printf "  %s\n" "$1"; }

banner

ZIP_PATH="${1:?Usage: $0 path/to/dvfp.zip}"
REPO_ROOT="$(pwd)"
TMP_DIR="$(mktemp -d)"
KEEP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR" "$KEEP_DIR"' EXIT

if [ "$(id -u)" -eq 0 ]; then
  warn "Running as root (sudo). Don't -- re-run without sudo:"
  info "    ./scripts/nuke.sh $ZIP_PATH"
  exit 1
fi

if [ ! -d "$REPO_ROOT/.git" ]; then
  warn "No .git folder found here. Run this from the root of a cloned"
  info "client repo -- .git is what makes this recoverable if anything goes wrong."
  exit 1
fi

printf "${DIM}This will DELETE everything in %s${RESET}\n" "$REPO_ROOT"
printf "${DIM}except .git/ and docs/, then replace it with the DVFP.${RESET}\n"
read -r -p "Continue? [y/N] " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  info "Aborted, nothing was touched."
  exit 0
fi

info "Unzipping $ZIP_PATH..."
unzip -q "$ZIP_PATH" -d "$TMP_DIR"

# DVFP zips sometimes have one wrapper folder, sometimes extract flat.
SRC_ROOT="$TMP_DIR"
if [ ! -d "$TMP_DIR/app" ] && [ ! -f "$TMP_DIR/package.json" ]; then
  CANDIDATE=$(find "$TMP_DIR" -maxdepth 1 -mindepth 1 -type d | head -n1)
  [ -n "$CANDIDATE" ] && SRC_ROOT="$CANDIDATE"
fi

if [ ! -f "$SRC_ROOT/package.json" ]; then
  warn "No package.json found in the zip -- this doesn't look like a full"
  info "standalone DVFP export. Aborting before touching anything."
  exit 1
fi

section "Preserving docs/ and .env.example"
[ -d "$REPO_ROOT/docs" ] && cp -r "$REPO_ROOT/docs" "$KEEP_DIR/docs"
[ -f "$REPO_ROOT/.env.example" ] && cp "$REPO_ROOT/.env.example" "$KEEP_DIR/.env.example"
ok "stashed"

section "Wiping repo contents (except .git)"
find "$REPO_ROOT" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +
ok "clean slate"

section "Copying in the DVFP"
rsync -a --exclude 'docs' --exclude '.env.example' "$SRC_ROOT"/ "$REPO_ROOT"/
ok "app/, components/, lib/, public/, and full project config in place"

section "Restoring docs/"
[ -d "$KEEP_DIR/docs" ] && cp -r "$KEEP_DIR/docs" "$REPO_ROOT/docs"
ok "docs/ restored"

section "Environment variables"
if [ -f "$KEEP_DIR/.env.example" ]; then
  cp "$KEEP_DIR/.env.example" "$REPO_ROOT/.env"
  info "Created .env from the template's .env.example."

  # Guarantee .env is excluded from git, regardless of what the DVFP's own
  # .gitignore does or doesn't already cover -- this now holds real
  # Paychangu test credentials, not placeholders, so there's no margin here.
  GITIGNORE="$REPO_ROOT/.gitignore"
  touch "$GITIGNORE"
  if ! grep -qxF '.env' "$GITIGNORE" 2>/dev/null; then
    {
      echo ""
      echo "# added by nuke.sh -- never track real secrets"
      echo ".env"
    } >> "$GITIGNORE"
  fi
  ok ".gitignore confirmed to exclude .env"

  rm -f "$REPO_ROOT/.env.example"
  ok ".env.example removed -- .env is now the only copy, and it's gitignored"
  info "When you deploy, import this .env file directly into Vercel's env"
  info "var screen rather than relying on any auto-detected integration."
else
  warn "No .env.example was found to seed from -- add env vars manually."
fi

printf "\n${GREEN}${BOLD}Done.${RESET}\n"
info "If a dev server from before this was running, stop it first -- package.json"
info "and the config files just changed underneath it, so a browser refresh alone"
info "won't pick that up. Then:"
printf "${DIM}  pnpm install && pnpm dev${RESET}\n"
