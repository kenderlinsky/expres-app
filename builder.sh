#!/usr/bin/env sh
set -euo pipefail
IFS=$'\n\t'

SCRIPT_NAME="$(basename "$0")"

log() {
    # log "message"
    printf "[%s] [%s] %s\n" \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$SCRIPT_NAME" \
        "$*" >&2
}

TMPDIR="$(mktemp -d)"

cleanup() {
    [[ -d "$TMPDIR" ]] && rm -rf "$TMPDIR" || true
}

if [ $# -lt 2 ]; then
    echo "Usage: $0 <github-repo> <docker-image:tag>" >&2
    exit 1
fi

main() {
GH_PATH="$1"
REPO_URL="https://github.com/${GH_PATH}.git"
REPO_DIR="$(basename "$GH_PATH")"
DOCKER_TAG="$2"
log "Repo path: $GH_PATH"
log "Clone URL: $REPO_URL"
log "Target dir: $REPO_DIR"

cd "$TMPDIR"
git clone "$REPO_URL"
log "Entering directory: $REPO_DIR"
cd "$REPO_DIR"
log "build docker image $DOCKER_TAG"
cat /docker/password.txt | docker login registry-1.docker.io -u kenderlinsky --password-stdin
docker build -f Dockerfile.build -t "$DOCKER_TAG" . 
}

main "$@"

cleanup
