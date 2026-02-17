# llmmux

A small **bash** CLI that talks to multiple LLM providers from the command line. One script, one interface—switch providers with a flag.

## Features

- **Multiple providers**: OpenAI, Google (Gemini), Anthropic (Claude), and Ollama (local).
- **Flexible prompt input**: Inline text (`-t`), a file (`-f`), or stdin.
- **Config file**: API keys and default models in `~/.config/llmmux/llmmux.conf` or via `-e`.
- **Model override**: Use `-m` to override the default model for the chosen provider.
- **No extra runtime**: Uses only `bash`, `curl`, and `jq`.

## Prerequisites

You need:

- **Bash** (4+)
- **curl**
- **jq**

### Installing prerequisites by platform

#### Linux

**Debian / Ubuntu / Linux Mint**

```bash
sudo apt update
sudo apt install curl jq
```

(Bash is usually already installed.)

**Fedora / RHEL / CentOS / Rocky**

```bash
sudo dnf install curl jq
```

**Arch Linux**

```bash
sudo pacman -S curl jq
```

**openSUSE**

```bash
sudo zypper install curl jq
```

**Alpine**

```bash
sudo apk add curl jq
```

#### macOS

**Homebrew (recommended)**

```bash
brew install curl jq
```

macOS ships with an old Bash; the script runs with `/usr/bin/env bash` (often Bash 3.2). For a newer Bash:

```bash
brew install bash
```

Then ensure your PATH uses the Homebrew `bash` before the system one if you rely on Bash 4+ features.

#### Windows

The script is written for Bash, so run it in a Bash environment:

**Option A: WSL (Windows Subsystem for Linux)**  
Use your WSL distro (e.g. Ubuntu) and install as on Debian/Ubuntu:

```bash
sudo apt update && sudo apt install curl jq
```

**Option B: Git for Windows (Git Bash)**  
Git for Windows includes Bash, curl, and often basic tools. Install **jq** separately:

- Download from [jqlang/jq](https://github.com/jqlang/jq/releases) (e.g. `jq-win64.exe`), rename to `jq.exe`, and put it in your `PATH`, or  
- If you have Chocolatey: `choco install jq`

Then run `llmmux` from Git Bash.

**Option C: MSYS2 / Cygwin**  
Install the `curl` and `jq` packages in your MSYS2 or Cygwin environment and run the script from that shell.

---

## Installation

1. Clone or download this repo (or copy the `llmmux` script).
2. Make the script executable:

   ```bash
   chmod +x llmmux
   ```

3. (Optional) Put it on your PATH, e.g.:

   ```bash
   sudo cp llmmux /usr/local/bin/
   # or
   mkdir -p ~/.local/bin && cp llmmux ~/.local/bin/ && export PATH="$HOME/.local/bin:$PATH"
   ```

## Configuration

Create a config file so llmmux can find your API keys and defaults.

**Location (by default):** `~/.config/llmmux/llmmux.conf`

**Override:** use `-e /path/to/file` to point to another env/config file.

### Config file format

Use the same variable names you would for environment variables. Example:

```bash
# OpenAI (optional if you only use other providers)
export OPENAI_API_KEY="sk-..."
export OPENAI_MODEL="gpt-4o"   # optional; script has a default

# Anthropic
export ANTHROPIC_API_KEY="sk-ant-..."
export ANTHROPIC_MODEL="claude-sonnet-4-5"   # optional

# Google (Gemini)
export GOOGLE_API_KEY="..."
export GOOGLE_MODEL="gemini-2.5-flash"   # optional

# Ollama (local; no API key)
export OLLAMA_MODEL="llama3.1"   # optional
export OLLAMA_URL="http://localhost:11434"   # optional
```

Only set the keys and variables for the providers you use. The script sources this file, so `export` is optional but keeps things clear.

### Securing the config file

```bash
chmod 600 ~/.config/llmmux/llmmux.conf
```

## Usage

```text
Usage: llmmux -p <provider> [-m <model>] [-t <text>] [-f <file>] [-e <env_file>] [-u <url>]
  -p, --provider   Provider: openai, google, anthropic, ollama
  -m, --model      Override model from config (or use provider default if unset)
  -t, --text       Prompt text (takes precedence over -f and stdin)
  -f, --file       Prompt file (used if -t not given; else stdin)
  -e, --env        Environment/config file (optional; see above for default lookup)
  -u, --url        URL for ollama provider (default: http://localhost:11434)
```

### Examples

**Inline prompt (OpenAI):**

```bash
./llmmux -p openai -t "Explain recursion in one sentence."
```

**Prompt from file (Anthropic):**

```bash
./llmmux -p anthropic -f ./prompt.txt
```

**Stdin (e.g. pipe):**

```bash
echo "Summarize the following: ..." | ./llmmux -p google
```

**Ollama with custom URL and model:**

```bash
./llmmux -p ollama -u http://192.168.1.10:11434 -m llama3.2 -t "Hello"
```

**Override model for one call:**

```bash
./llmmux -p openai -m gpt-4o-mini -t "Short joke about shells"
```

**Use a specific config file:**

```bash
./llmmux -p openai -e ~/work/llmmux.env -t "Hello"
```

## Default models

If you don’t set a model in config or with `-m`, the script uses:

| Provider | Default model            |
|----------|--------------------------|
| openai   | gpt-5                    |
| google   | gemini-2.5-flash         |
| anthropic| claude-sonnet-4-5        |
| ollama   | llama3.1                 |

(Update these in the script or in your config if your provider uses different model names.)

## Troubleshooting

- **"no environment file found"**  
  Create `~/.config/llmmux/llmmux.conf` (or use `-e <file>`) with at least the API key for the provider you’re using.

- **"Unknown provider"**  
  Use one of: `openai`, `google`, `anthropic`, `ollama` (case-insensitive).

- **jq/curl not found**  
  Install `jq` and `curl` as in [Prerequisites](#prerequisites).

- **Ollama connection errors**  
  Ensure Ollama is running (e.g. `ollama serve`) and that `OLLAMA_URL` (or `-u`) matches your server (default `http://localhost:11434`).

- **API errors (401, 403, etc.)**  
  Check that the corresponding API key in your config is correct and has access to the requested model.

## License

MIT License

Copyright (c) 2026 Mark Abrahams

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Third-party services

This tool can interact with external AI providers such as OpenAI, Google,
and Anthropic. This project is not affiliated with or endorsed by any
of these providers. Users are responsible for complying with the respective
API terms of service.
