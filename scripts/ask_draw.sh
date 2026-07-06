#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${DRAW_VENV:-$HOME/.cache/draw/venv}"
PYTHON_BIN="${DRAW_PYTHON:-}"

if [[ -z "$PYTHON_BIN" ]]; then
  if [[ -x "$VENV_DIR/bin/python3" ]]; then
    PYTHON_BIN="$VENV_DIR/bin/python3"
  elif [[ -x "$VENV_DIR/Scripts/python.exe" ]]; then
    PYTHON_BIN="$VENV_DIR/Scripts/python.exe"
  else
    PYTHON_BIN="$VENV_DIR/bin/python3"
  fi
fi

SYSTEM_PYTHON="${DRAW_SYSTEM_PYTHON:-}"
if [[ -z "$SYSTEM_PYTHON" ]]; then
  if command -v python3 >/dev/null 2>&1; then
    SYSTEM_PYTHON="python3"
  elif command -v python >/dev/null 2>&1; then
    SYSTEM_PYTHON="python"
  else
    echo "[ERROR] Python not found. Install Python 3 or set DRAW_SYSTEM_PYTHON." >&2
    exit 1
  fi
fi

if [[ ! -x "$PYTHON_BIN" ]]; then
  mkdir -p "$VENV_DIR"
  "$SYSTEM_PYTHON" -m venv "$VENV_DIR"
  if [[ ! -x "$PYTHON_BIN" && -x "$VENV_DIR/Scripts/python.exe" ]]; then
    PYTHON_BIN="$VENV_DIR/Scripts/python.exe"
  fi
fi

if [[ ! -x "$PYTHON_BIN" ]]; then
  echo "[ERROR] Could not find virtualenv Python at $PYTHON_BIN. Set DRAW_PYTHON to override." >&2
  exit 1
fi

if ! "$PYTHON_BIN" -c "import google.genai, PIL" >/dev/null 2>&1; then
  PIP_DISABLE_PIP_VERSION_CHECK=1 "$PYTHON_BIN" -m pip install --quiet --upgrade pip google-genai pillow
fi

# --frame <path>: prepend a frame reference image before all other --ref args.
# Usage: ask_draw.sh --frame /path/to/frame.png [other args...]
# This injects --ref <frame> at the front so the frame is always ref[0].
FRAME_PATH=""
REMAINING_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --frame)
      if [[ $# -lt 2 || "${2:-}" == --* ]]; then
        echo "[ERROR] --frame requires a reference image path." >&2
        exit 2
      fi
      FRAME_PATH="$2"
      shift 2
      ;;
    *)
      REMAINING_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ -n "$FRAME_PATH" ]]; then
  exec "$PYTHON_BIN" "$SCRIPT_DIR/generate_image.py" --ref "$FRAME_PATH" "${REMAINING_ARGS[@]}"
else
  exec "$PYTHON_BIN" "$SCRIPT_DIR/generate_image.py" "${REMAINING_ARGS[@]}"
fi
