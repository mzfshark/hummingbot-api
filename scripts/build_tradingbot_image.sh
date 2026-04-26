#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

IMAGE_TAG="${HBOT_IMAGE:-hummingbot/hummingbot:development}"
PREFERRED_PATH="${TRADINGBOT_PATH:-/opt/tradingbot}"
FALLBACK_PATH="/opt/Tradingbot"

die() { echo "ERROR: $*" >&2; exit 1; }

repo_path=""
if [[ -d "$PREFERRED_PATH" ]]; then
  repo_path="$PREFERRED_PATH"
elif [[ -d "$FALLBACK_PATH" ]]; then
  repo_path="$FALLBACK_PATH"
else
  die "Repo Tradingbot nao encontrado em '$PREFERRED_PATH' nem em '$FALLBACK_PATH'. Defina TRADINGBOT_PATH ou clone em /opt/tradingbot."
fi

[[ -f "$repo_path/Dockerfile" ]] || die "Dockerfile nao encontrado em '$repo_path/Dockerfile'"

branch=""
commit=""
build_date=""
if command -v git >/dev/null 2>&1 && [[ -d "$repo_path/.git" ]]; then
  branch="$(git -C "$repo_path" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  commit="$(git -C "$repo_path" rev-parse HEAD 2>/dev/null || true)"
fi
build_date="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || true)"

echo "Building Tradingbot image from: $repo_path"
echo "Image tag: $IMAGE_TAG"

args=(docker build -t "$IMAGE_TAG")
if [[ -n "$branch" ]]; then args+=(--build-arg "BRANCH=$branch"); fi
if [[ -n "$commit" ]]; then args+=(--build-arg "COMMIT=$commit"); fi
if [[ -n "$build_date" ]]; then args+=(--build-arg "BUILD_DATE=$build_date"); fi
args+=("$repo_path")

"${args[@]}"

echo "OK: Tradingbot image built: $IMAGE_TAG"
