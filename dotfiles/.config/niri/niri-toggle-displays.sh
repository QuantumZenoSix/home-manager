#!/bin/bash

# Get monitor names (adjust based on your setup from `niri msg outputs`)
# INTERNAL="eDP-1"
# EXTERNAL="HDMI-A-1"  # or whatever yours is

INTERNAL="$(niri msg outputs | grep -E '^Output' | sed -n '1{p;q}' | sed -r 's:Output\s+\".*\"::' | tr -d '()' | xargs)"
EXTERNAL="$(niri msg outputs | grep -E '^Output' | sed -n '2{p;q}' | sed -r 's:Output\s+\".*\"::' | tr -d '()' | xargs)"
EXTERNAL2="$(niri msg outputs | grep -E '^Output' | sed -n '3{p;q}' | sed -r 's:Output\s+\".*\"::' | tr -d '()' | xargs)"

# Simple states: Laptop only, Laptop + 1 External, Laptop + 2 External
STATE_FILE="/tmp/niri-display-state"

if [ ! -f "$STATE_FILE" ]; then
    echo "laptop" > "$STATE_FILE"
fi

STATE=$(cat "$STATE_FILE")

case $STATE in
    laptop)
        niri msg output "$INTERNAL" on
        niri msg output "$EXTERNAL" on
        niri msg output "$EXTERNAL2" off
        echo "external1only" > "$STATE_FILE"
        notify-send "Displays: Laptop + 1 External"
        ;;
    external1only)
        niri msg output "$INTERNAL" on
        niri msg output "$EXTERNAL" off
        niri msg output "$EXTERNAL2" on
        echo "external2only" > "$STATE_FILE"
        notify-send "Displays: Laptop + 1 External"
        ;;
    external2only)
        niri msg output "$INTERNAL" on
        niri msg output "$EXTERNAL" on
        niri msg output "$EXTERNAL2" on
        echo "external2" > "$STATE_FILE"
        notify-send "Displays: Laptop + 2 External"
        ;;
    external2)
        niri msg output "$INTERNAL" on
        niri msg output "$EXTERNAL" off
        niri msg output "$EXTERNAL2" off
        echo "laptop" > "$STATE_FILE"
        notify-send "Displays: Laptop only"
        ;;
esac
