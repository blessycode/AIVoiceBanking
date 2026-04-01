#!/usr/bin/env bash

set -euo pipefail

DEVICE="${1:-emulator-5554}"
OUTPUT_DIR="${2:-screenshots/emulator}"
PACKAGE="com.example.kimari"
DEFAULT_SETTLE_SECONDS="${DEFAULT_SETTLE_SECONDS:-4}"
SPLASH_SETTLE_SECONDS="${SPLASH_SETTLE_SECONDS:-8}"

SCREENS=(
  splash
  voice-auth
  voice-home
  dashboard
  send-money
  voice-transaction
  transaction-success
  airtime
  bills
  cards
  all-transactions
  top-up
  pin-entry
  ai-assistant
  voice-listening
  settings
)

mkdir -p "$OUTPUT_DIR"

cleanup() {
  if [[ -n "${RUN_PID:-}" ]]; then
    kill -INT "$RUN_PID" 2>/dev/null || true
    wait "$RUN_PID" 2>/dev/null || true
  fi
  adb -s "$DEVICE" shell am force-stop "$PACKAGE" >/dev/null 2>&1 || true
}

trap cleanup EXIT

adb -s "$DEVICE" wait-for-device
adb -s "$DEVICE" shell am force-stop "$PACKAGE" >/dev/null 2>&1 || true

capture_screen() {
  local screen="$1"
  local output_file="$OUTPUT_DIR/$screen.png"
  local log_file="/tmp/kimari_screenshot_${screen}.log"
  local settle_seconds="$DEFAULT_SETTLE_SECONDS"

  if [[ "$screen" == "splash" ]]; then
    settle_seconds="$SPLASH_SETTLE_SECONDS"
  fi

  adb -s "$DEVICE" shell am force-stop "$PACKAGE" >/dev/null 2>&1 || true

  flutter run \
    -d "$DEVICE" \
    -t lib/main_screenshots.dart \
    --dart-define=SCREENSHOT_SCREEN="$screen" \
    >"$log_file" 2>&1 &
  RUN_PID=$!

  echo "Launching $screen on $DEVICE..."
  for _ in $(seq 1 240); do
    if adb -s "$DEVICE" shell pidof "$PACKAGE" >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done

  if ! adb -s "$DEVICE" shell pidof "$PACKAGE" >/dev/null 2>&1; then
    echo "App did not start for $screen. See $log_file"
    exit 1
  fi

  sleep "$settle_seconds"
  echo "Capturing $screen -> $output_file"
  adb -s "$DEVICE" exec-out screencap -p >"$output_file"

  kill -INT "$RUN_PID" 2>/dev/null || true
  wait "$RUN_PID" 2>/dev/null || true
  RUN_PID=""
}

for screen in "${SCREENS[@]}"; do
  capture_screen "$screen"
done

echo "Screenshots saved to $OUTPUT_DIR"
