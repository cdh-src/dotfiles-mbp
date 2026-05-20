#!/bin/zsh
# Print " NN%" for the tmux status bar: a Nerd Font Material Design Icon
# matching the current battery level, a space, then the percentage.
#
# The icon family switches between charging and discharging based on
# `pmset -g batt`. Buckets are 10% wide.
#
# Discharging: complete 0-9..90-100 series (f0079, f007a..f0082).
# Charging:    f0085 (full), f089d (80), f008b..f0086 (70..20), f089c (10).
#              The 0-9 charging bucket falls back to f089c (10-19).
# Change the case branches below if you want different fallbacks.

set -u

line=$(pmset -g batt 2>/dev/null | sed -n '2p')
pct=$(printf '%s' "$line" | grep -oE '[0-9]+%' | head -1 | tr -d '%')
[[ -z "$pct" ]] && exit 0

# Detect charging state. pmset strings contain:
#   "discharging"           → on battery
#   "charging"              → plugged in, charging
#   "not charging present"  → plugged in, full (or paused by macOS)
#   "charged"               → plugged in, full
# The match order matters: check "discharging" / "not charging" before "charging".
case "$line" in
  *"discharging"*)   state=discharging ;;
  *"not charging"*)  state=charging ;;  # treat as topped-off
  *"charged"*)       state=charging ;;
  *"charging"*)      state=charging ;;
  *"AC attached"*)   state=charging ;;
  *)                 state=discharging ;;
esac

# Bucket: 0..9, capped.
bucket=$(( pct / 10 ))
# (( bucket > 9 )) && bucket=9

if [[ "$state" == charging ]]; then
  case $bucket in
    10) glyph=$'\U000f0085';;   # 100    → battery-charging (full)
    9) glyph=$'\U000f008b' ;;   # 90-99  → battery-charging-90
    8) glyph=$'\U000f008a' ;;   # 80-89  → battery-charging-80
    7) glyph=$'\U000f089e' ;;   # 70-79  → battery-charging-70
    6) glyph=$'\U000f0089' ;;   # 60-69  → battery-charging-60
    5) glyph=$'\U000f089d' ;;   # 50-59  → battery-charging-50
    4) glyph=$'\U000f0088' ;;   # 40-49  → battery-charging-40
    3) glyph=$'\U000f0087' ;;   # 30-39  → battery-charging-30
    2) glyph=$'\U000f0086' ;;   # 20-29  → battery-charging-20
    1) glyph=$'\U000f089c' ;;   # 10-19  → battery-charging-10
    0) glyph=$'\U000f089f' ;;   # 0-9    → fallback to charging-10
  esac
else
  case $bucket in
    10) glyph=$'\U000f0079';;   # 100    → battery (full)
    9) glyph=$'\U000f0082' ;;   # 90-99  → battery_90
    8) glyph=$'\U000f0081' ;;   # 80-89  → battery_80
    7) glyph=$'\U000f0080' ;;   # 70-79  → battery_70
    6) glyph=$'\U000f007f' ;;   # 60-69  → battery_60
    5) glyph=$'\U000f007e' ;;   # 50-59  → battery_50
    4) glyph=$'\U000f007d' ;;   # 40-49  → battery_40
    3) glyph=$'\U000f007c' ;;   # 30-39  → battery_30
    2) glyph=$'\U000f007b' ;;   # 20-29  → battery_20
    1) glyph=$'\U000f007a' ;;   # 10-19  → battery_10
    0) glyph=$'\U000f1210' ;;   # 0-9    → battery_heart_outline
  esac
fi

printf '%s %s%%\n' "$glyph" "$pct"
