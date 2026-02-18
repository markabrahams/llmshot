#!/usr/bin/env bash
# shellcheck shell=bash
# Tag a release, push the tag, then update the Homebrew tap and push.
# Usage: ./release.sh VERSION [-d TAP_DIR] [-t|--test]
# Example: ./release.sh 1.0.1
#          ./release.sh 1.0.1 -d ~/unsure/homebrew-llmshot
#          ./release.sh 1.0.1 -t   # test only: check paths/dirs, no actions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BREW_RELEASE="$SCRIPT_DIR/brew-release.sh"

usage() {
    echo "Usage: $0 VERSION [-d TAP_DIR] [-t|--test]"
    echo "  VERSION    Release version to tag (e.g. 1.0.0). Creates tag vVERSION and pushes, then updates Homebrew tap."
    echo "  -d TAP_DIR Pass through to brew-release.sh (default tap dir: /var/tmp/homebrew-llmshot)."
    echo "  -t, --test Test only: check directories and paths, do not tag, push, or update tap."
    exit 0
}

VERSION=""
TAP_DIR_ARG=()
TEST=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage ;;
        -t|--test) TEST=1; shift ;;
        -d)
            if [[ -z "${2:-}" ]]; then
                echo "error: -d requires a directory argument" >&2
                exit 1
            fi
            TAP_DIR_ARG=(-d "$2")
            shift 2
            ;;
        *)
            if [[ -z "$VERSION" ]]; then
                VERSION="$1"
                shift
            else
                echo "error: unexpected argument: $1" >&2
                exit 1
            fi
            ;;
    esac
done

if [[ -z "$VERSION" ]]; then
    echo "error: VERSION required" >&2
    echo "Usage: $0 VERSION [-d TAP_DIR] [-t|--test]" >&2
    exit 1
fi

if [[ -n "$TEST" ]]; then
    TAP_DIR="${TAP_DIR_ARG[1]:-/var/tmp/homebrew-llmshot}"
    ERR=0
    echo "[test] VERSION=$VERSION"
    echo "[test] SCRIPT_DIR=$SCRIPT_DIR"
    if [[ ! -d "$SCRIPT_DIR" ]]; then
        echo "[test] FAIL: SCRIPT_DIR is not a directory" >&2
        ERR=1
    else
        echo "[test] OK: SCRIPT_DIR exists"
    fi
    if [[ ! -f "$BREW_RELEASE" ]]; then
        echo "[test] FAIL: BREW_RELEASE not found: $BREW_RELEASE" >&2
        ERR=1
    else
        echo "[test] OK: BREW_RELEASE exists"
    fi
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then echo "[test] FAIL: not inside a git repository" >&2; ERR=1; else echo "[test] OK: inside git repo"; fi
    echo "[test] TAP_DIR=$TAP_DIR"
    if [[ ! -d "$TAP_DIR" ]]; then
        echo "[test] WARN: TAP_DIR does not exist (run brew-release.sh -c first?)" >&2
        ERR=1
    else
        echo "[test] OK: TAP_DIR exists"
    fi
    if [[ -d "$TAP_DIR" ]] && [[ ! -f "$TAP_DIR/Formula/llmshot.rb" ]]; then
        echo "[test] WARN: Formula not found at $TAP_DIR/Formula/llmshot.rb" >&2
        ERR=1
    else
        echo "[test] OK: Formula exists"
    fi
    if git rev-parse "v${VERSION}" &>/dev/null; then
        echo "[test] WARN: tag v${VERSION} already exists" >&2
        ERR=1
    else
        echo "[test] OK: tag v${VERSION} does not exist yet"
    fi
    if [[ $ERR -eq 1 ]]; then
        exit 1
    fi
    echo "[test] All checks passed. Would run: git tag -a v${VERSION} -m \"Release ${VERSION}\"; git push origin v${VERSION}; $BREW_RELEASE ${TAP_DIR_ARG[*]} $VERSION"
    exit 0
fi

echo "Tagging v${VERSION} ..."
git tag -a "v${VERSION}" -m "Release ${VERSION}"
echo "Pushing tag v${VERSION} ..."
git push origin "v${VERSION}"

echo "Updating Homebrew tap ..."
"$BREW_RELEASE" "${TAP_DIR_ARG[@]}" "$VERSION"

echo "Done. v${VERSION} is released and the tap is updated."
