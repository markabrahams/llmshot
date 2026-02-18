#!/usr/bin/env bash
# shellcheck shell=bash
# Tag a release, push the tag, then update the Homebrew tap and push.
# Usage: ./release.sh VERSION [-d TAP_DIR]
# Example: ./release.sh 1.0.1
#          ./release.sh 1.0.1 -d ~/unsure/homebrew-llmshot

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BREW_RELEASE="$SCRIPT_DIR/brew-release.sh"

usage() {
    echo "Usage: $0 VERSION [-d TAP_DIR]"
    echo "  VERSION    Release version to tag (e.g. 1.0.0). Creates tag vVERSION and pushes, then updates Homebrew tap."
    echo "  -d TAP_DIR Pass through to brew-release.sh (default tap dir: /var/tmp/homebrew-llmshot)."
    exit 0
}

VERSION=""
TAP_DIR_ARG=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage ;;
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
    echo "Usage: $0 VERSION [-d TAP_DIR]" >&2
    exit 1
fi

echo "Tagging v${VERSION} ..."
git tag -a "v${VERSION}" -m "Release ${VERSION}"
echo "Pushing tag v${VERSION} ..."
git push origin "v${VERSION}"

echo "Updating Homebrew tap ..."
"$BREW_RELEASE" "${TAP_DIR_ARG[@]}" "$VERSION"

echo "Done. v${VERSION} is released and the tap is updated."
