# Homebrew formula template for llmshot.
#
# For maintainers: steps below are for you to publish llmshot on Homebrew.
# End users only run: brew install markabrahams/llmshot/llmshot (or --head for latest main).
#
# To publish (maintainer), use scripts/brew-release.sh (requires gh CLI, logged in):
#
#   One-time — create the tap (GitHub repo + local clone + Formula/):
#     ./scripts/brew-release.sh -c
#   Then run a release step below so the formula has version/sha256, and push from the tap dir.
#
#   Each release — tag must exist (e.g. v1.0.0). Script updates formula and pushes:
#     ./scripts/brew-release.sh 1.0.0
#
#   Optional: -d DIR to use a different tap directory (default: /var/tmp/homebrew-llmshot).
#
#   ./scripts/brew-release.sh -h for usage.

class Llmshot < Formula
  desc "Multi-provider LLM CLI (OpenAI, Google, Anthropic, Ollama)"
  homepage "https://github.com/markabrahams/llmshot"
  url "https://github.com/markabrahams/llmshot/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "REPLACE_WITH_SHA256_FROM_BREW_FETCH"
  license "MIT"
  head "https://github.com/markabrahams/llmshot.git", branch: "main"

  depends_on "jq"

  def install
    bin.install "bin/llmshot" => "llmshot"
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/llmshot 2>&1", 1)
  end
end
