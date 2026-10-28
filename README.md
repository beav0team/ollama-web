# ollama-web

A small, dependency-free chat interface for a local [Ollama](https://ollama.com)
server — one HTML file, no build step, no CDN, no framework.

![screenshot](docs/screenshot.png)

Ollama ships a CLI and an HTTP API but no web UI. This fills that gap with a
single page that talks straight to `http://127.0.0.1:11434`, plus a ~250 line
Python server whose only job is to turn PDFs and images into text so they can
be attached to a prompt — and to serve the desktop palette as CSS.

## Features

- **Streaming chat** against `/api/chat`, with a live cursor and Stop (`Esc`).
- **Thinking models.** Handles every shape Ollama returns: a separate
  `message.thinking` field, and inline ` thinking…</think>` or
  `<thinking>…</thinking>` text inside `message.content` (which is what raw GGUF
  imports produce) — including the unclosed tag while a reply is streaming.
  Collapsed by default, char count in the summary.
- **Markdown** — fenced code, inline code, headings, ordered/unordered lists,
  blockquotes, rules, bold, italic, links, and **tables** with `:--`/`--:`/
  `:-:` alignment. A pipe line only becomes a table when the row beneath it is
  the `|---|---|` rule, so prose with a `|` in it stays prose. Everything is
  escaped before rendering, so a model reply cannot inject markup.
- **Copy buttons** on every code block, and one per reply that copies the
  whole answer as markdown (fences and table pipes intact).
- **Follows the desktop theme.** The page carries only nine tokens; the local
  server serves `/theme.css` generated from `~/.config/waybar/colors.css`, so
  `theme-switch` repaints the chat window too. Panels, borders and the code
  background are `color-mix()`ed from those tokens, which is why a light theme
  needs no second set of rules. Falls back to the built-in Everforest palette
  when the stylesheet is not served (any plain static server).
- **Attachments** — plain text and source files are read in the browser; PDFs
  and images go through the local server (`pdftotext`, `tesseract`), with an
  OCR fallback for scanned PDFs. Nothing leaves the machine.
- **Parameter panel** — temperature, top_p, context, max tokens, repeat
  penalty, thread count, system prompt. Persisted in `localStorage`.
- **Model info** — parameter count, quantisation, size and capabilities shown
  next to the picker, read from `/api/show`.
- **Retry** — ask the same question again, replacing the previous answer.
- **Context meter** — prompt + generated tokens against `num_ctx`, so a full
  window is visible before the oldest turns start dropping.
- **Errors stay put.** A failure is written where the answer would have been
  (an empty bubble with the reason in a status line reads like a hang), and the
  status line survives the 15 s model poll — only a connectivity warning is
  cleared by it, never a real error.

## Install

```bash
git clone https://github.com/beav0team/ollama-web.git
cd ollama-web
./install.sh
```

That symlinks `omarchy-ai-server` and `omarchy-ai-widget` into `~/.local/bin`.
Nothing else is installed and no service is enabled — the launcher starts the
page server on demand.

**Requirements:** `python3`, and `ollama` running on `127.0.0.1:11434`.
Optional: `poppler-utils` (`pdftotext`, `pdftoppm`) and `tesseract` for PDF and
image attachments. The launcher uses Brave as a Chromium app window; any
Chromium-based browser works if you change one line.

## Usage

```bash
omarchy-ai-widget        # opens (or focuses) the chat window
```

On the Hyprland setup this is bound to `SUPER + A`, and the window is an
ordinary tiled window — no floating popup, no titlebar to fight with.

Environment variables for the server:

| variable | default | meaning |
|---|---|---|
| `OMARCHY_AI_PORT` | `8099` | port to serve the page on |
| `OMARCHY_AI_ROOT` | repo root | directory to serve |
| `OMARCHY_AI_COLORS` | `~/.config/waybar/colors.css` | palette served at `/theme.css` |

## Note: what the server exposes

It serves the repository directory — `index.html`, `/theme.css` and `/extract`
are the page — so everything else is deliberately shut: any path with a dot
segment (`/.git/config`, `/.env`) answers 404, and the page and the palette are
sent with `Cache-Control: no-store`, because they are edited in place and a
cached copy is always the wrong one. It binds to `127.0.0.1` only; Ollama
accepts that origin by default and rejects `file://`, which is why the page is
served rather than opened from disk.

## Gotcha: Ollama has two model stores

This cost an afternoon, so it is written down. If a model works in the CLI but
never appears in the UI, you are probably looking at two different stores:

```bash
# what the service is serving
systemctl show ollama -p User        # User=ollama
# -> its store is /usr/share/ollama/.ollama/models

# what your shell imported into when the service was not running
ls ~/.ollama/models/manifests       # -> your own store
```

A model imported while the service was down lands in `~/.ollama/models` and is
invisible to the running daemon. The fix is to create it against the service:

```bash
ollama create <name> -f Modelfile   # no OLLAMA_HOST override
ollama list                         # now it shows up
```

## Note: importing a raw GGUF

`ollama create` does **not** use the chat template embedded in a GGUF. It falls
back to `{{ .Prompt }}`, and the model will ramble instead of answering. Supply
the template yourself:

```
FROM /path/to/model.gguf
TEMPLATE """{{- if .System }}<|im_start|>system
{{ .System }}<|im_end|>
{{ end }}{{- range .Messages }}<|im_start|>{{ .Role }}
{{ .Content }}<|im_end|>
{{ end }}<|im_start|>assistant
"""
PARAMETER num_ctx 4096
PARAMETER num_thread 8
```

Verify with `curl -s localhost:11434/api/show -d '{"model":"<name>"}'` — a
template of about 13 characters means the fallback was used.

## Performance, measured

A 9B model at IQ3_S (4.37 GB) on an i5-8350U with 8 GB RAM and no GPU:

| config | generation |
|---|---|
| `num_ctx 2048` | 0.8 tok/s |
| `num_ctx 4096` | 0.8 tok/s |
| `num_ctx 4096`, `num_thread 8` | **1.3 tok/s** |
| `num_ctx 8192` | 1.5 tok/s, 5.9 GB peak |

Thread count is the setting that matters — Ollama defaults to physical cores.
Context size barely moves the speed on hybrid-attention models but costs
memory, so 4096 is the sweet spot at 8 GB.

## License

No license file yet — ask the author before redistributing.
