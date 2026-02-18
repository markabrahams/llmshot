#!/usr/bin/env bash
# shellcheck shell=bash
# Maintainer script: create or update the Homebrew tap for llmshot.
# Requires: gh (GitHub CLI), logged in. Tap dir: /var/tmp/homebrew-llmshot (override with -d/--dir).
#
# Before releasing a version, tag it in the llmshot repo and push the tag (so the tarball exists on GitHub):
#   git tag -a v1.0.0 -m "Release 1.0.0"    # or: git tag v1.0.0
#   git push origin v1.0.0
#
# Create tap from scratch (one-time). Pass VERSION to also set formula and push:
#   ./scripts/brew-release.sh -c 1.0.0
#   # or without VERSION, then run a release step later to set version/sha256 and push.
#
# Release an update (bump version in tap; tag vVERSION must exist). Script commits and pushes:
#   ./scripts/brew-release.sh 1.0.1

set -euo pipefail

TAP_DIR="/var/tmp/homebrew-llmshot"
REPO_NAME="homebrew-llmshot"
FORMULA_NAME="llmshot.rb"

usage() {
    echo "Usage: $0 [-c|--create] [-d DIR|--dir DIR] [VERSION]"
    echo "  -c, --create   Create tap from scratch (repo + clone + Formula/)."
    echo "  -d, --dir DIR  Local tap directory (default: /var/tmp/homebrew-llmshot)."
    echo "  VERSION        Set formula to VERSION and push (e.g. 1.0.1); tag vVERSION must exist. Optional after -c."
    echo ""
    echo "Env: GITHUB_OWNER  Override GitHub owner (default: from 'gh api user' or tap remote)."
    exit 0
}

create_tap() {
    local skip_next_msg="$1"
    local owner
    owner="${GITHUB_OWNER:-$(gh api user -q .login)}"
    if [[ -z "$owner" ]]; then
        echo "error: could not determine GitHub owner; set GITHUB_OWNER or run 'gh auth login'" >&2
        exit 1
    fi

    if [[ -d "$TAP_DIR" ]]; then
        echo "error: $TAP_DIR already exists; remove it or use without -c to release an update" >&2
        exit 1
    fi

    echo "Creating GitHub repo $owner/$REPO_NAME ..."
    gh repo create "$owner/$REPO_NAME" --public --description "Homebrew tap for llmshot" || true

    echo "Cloning to $TAP_DIR ..."
    git clone "git@github.com:${owner}/${REPO_NAME}.git" "$TAP_DIR"
    mkdir -p "$TAP_DIR/Formula"

    local formula_src
    formula_src="$(cd "$(dirname "$0")" && pwd)/llmshot.rb"
    if [[ ! -f "$formula_src" ]]; then
        echo "error: formula not found at $formula_src" >&2
        exit 1
    fi
    cp "$formula_src" "$TAP_DIR/Formula/$FORMULA_NAME"
    echo "Copied formula to $TAP_DIR/Formula/$FORMULA_NAME"
    if [[ -z "$skip_next_msg" ]]; then
        echo "Next: run ./scripts/brew-release.sh -d $TAP_DIR <VERSION> to set version/sha256 and push."
    fi
}

release_update() {
    local version="$1"
    if [[ -z "$version" ]]; then
        echo "error: VERSION required for release update (e.g. $0 1.0.1)" >&2
        exit 1
    fi

    if [[ ! -d "$TAP_DIR" ]] || [[ ! -f "$TAP_DIR/Formula/$FORMULA_NAME" ]]; then
        echo "error: tap not found at $TAP_DIR; run with -c to create first" >&2
        exit 1
    fi

    local owner
    owner="${GITHUB_OWNER:-}"
    if [[ -z "$owner" ]]; then
        owner=$(git -C "$TAP_DIR" remote get-url origin 2>/dev/null | sed -n 's|.*github.com[:/]\([^/]*\)/.*|\1|p' || true)
    fi
    if [[ -z "$owner" ]]; then
        echo "error: could not determine GitHub owner; set GITHUB_OWNER" >&2
        exit 1
    fi

    local tarball_url
    tarball_url="https://github.com/${owner}/llmshot/archive/refs/tags/v${version}.tar.gz"
    echo "Fetching sha256 for v${version} ..."
    local sha
    sha=$(curl -fsSL "$tarball_url" | sha256sum | awk '{print $1}')
    if [[ -z "$sha" ]]; then
        echo "error: failed to download or hash $tarball_url (does tag v${version} exist?)" >&2
        exit 1
    fi

    local formula_path="$TAP_DIR/Formula/$FORMULA_NAME"
    sed -i.bak \
        -e "s|/archive/refs/tags/v[0-9.]*\\.tar\\.gz|/archive/refs/tags/v${version}.tar.gz|" \
        -e "s|sha256 \"REPLACE_WITH_SHA256_FROM_BREW_FETCH\"|sha256 \"${sha}\"|" \
        -e "s|sha256 \"[a-fA-F0-9]\{64\}\"|sha256 \"${sha}\"|" \
        "$formula_path"
    rm -f "${formula_path}.bak"

    echo "Updated $formula_path to v${version} (sha256 set)."
    (cd "$TAP_DIR" && git add "Formula/$FORMULA_NAME" && git commit -m "llmshot v${version}" && git push)
    echo "Committed and pushed to origin."
}

# --- main ---
CREATE=""
VERSION=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--create) CREATE=1; shift ;;
        -d|--dir)
            if [[ -z "${2:-}" ]]; then
                echo "error: -d/--dir requires a directory argument" >&2
                exit 1
            fi
            TAP_DIR="$2"
            shift 2
            ;;
        -h|--help) usage ;;
        *) VERSION="$1"; shift; break ;;
    esac
done

if [[ -n "$CREATE" ]]; then
    create_tap "${VERSION:+1}"
    if [[ -n "$VERSION" ]]; then
        release_update "$VERSION"
    fi
else
    release_update "$VERSION"
fi
