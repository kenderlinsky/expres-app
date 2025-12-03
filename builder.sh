#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

#CONFIG

SCRIPT_NAME="$(basename "$0")"

#LOGGING

log() {
    # log "message"
    printf "[%s] [%s] %s\n" \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$SCRIPT_NAME" \
        "$*" >&2
}

debug() {
    if [[ "${VERBOSE:-0}" -ne 0 ]]; then
        log "[DEBUG] $*"
    fi
}

# CLEANUP & ERROR HANDLING

TMPDIR="$(mktemp -d)"
debug "Using temp dir: $TMPDIR"

cleanup() {
    debug "Running cleanup..."
    [[ -d "$TMPDIR" ]] && rm -rf "$TMPDIR" || true
}

on_error() {
    local code=$?
    local line="${BASH_LINENO[0]}"
    log "ERROR: Script failed at line $line with exit code $code"
}

on_term() {
    log "Received termination signal (SIGTERM/SIGINT/SIGHUP)"
    cleanup
    exit 0
}

trap on_error ERR
trap cleanup EXIT
trap on_term SIGTERM SIGINT SIGHUP

if [ $# -lt 2 ]; then
    echo "use two arguments: github repository, dockerhub repository" >&2
    exit 1
fi

# MAIN FUNCTIONALITY
main() {
GH_PATH="$1"
REPO_URL="https://github.com/${GH_PATH}.git"
REPO_DIR="$(basename "$GH_PATH")"

log "Repo path: $GH_PATH"
log "Clone URL: $REPO_URL"
log "Target dir: $REPO_DIR"

cd "$TMPDIR"
git clone "$REPO_URL"
log "Entering directory: $REPO_DIR"
cd "$REPO_DIR"
echo "Now inside: $(pwd)"
log "docker build"
docker build . -t "$2"
docker tag "$2" "$2"
docker push "$2"                                                                                                                  
}

main "$@"
