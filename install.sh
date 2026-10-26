#!/usr/bin/env bash
# Link the launchers into ~/.local/bin. Nothing is copied and no service is
# enabled: the widget starts the page server on demand.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bin="$HOME/.local/bin"

mkdir -p "$bin"
chmod +x "$here/bin/omarchy-ai-server" "$here/bin/omarchy-ai-widget"
ln -sf "$here/bin/omarchy-ai-server" "$bin/omarchy-ai-server"
ln -sf "$here/bin/omarchy-ai-widget" "$bin/omarchy-ai-widget"

echo "linked:"
echo "  $bin/omarchy-ai-server  -> $here/bin/omarchy-ai-server"
echo "  $bin/omarchy-ai-widget  -> $here/bin/omarchy-ai-widget"
echo
echo "Make sure ~/.local/bin is on PATH, then run: omarchy-ai-widget"
