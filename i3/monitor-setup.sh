#!/bin/bash

# Monitor setup script for i3wm
# This script automatically detects connected monitors and configures them

# Get the internal display name (usually eDP-1 or LVDS-1)
INTERNAL=$(xrandr | grep " connected" | grep -E "(eDP|LVDS)" | cut -d" " -f1)

# Get external displays
EXTERNAL=$(xrandr | grep " connected" | grep -v -E "(eDP|LVDS)" | cut -d" " -f1)

# If no internal display found, fallback to first connected display
if [ -z "$INTERNAL" ]; then
    INTERNAL=$(xrandr | grep " connected" | head -n1 | cut -d" " -f1)
fi

echo "Internal display: $INTERNAL"
echo "External displays: $EXTERNAL"

# Turn off all displays first
xrandr --auto

# Configure displays based on what's connected
if [ -n "$EXTERNAL" ]; then
    # External monitor(s) connected
    # Count external monitors
    EXT_COUNT=$(echo "$EXTERNAL" | wc -l)
    echo "Found $EXT_COUNT external monitor(s)"
    
    if [ $EXT_COUNT -eq 1 ]; then
        # Single external monitor - place to the right
        ext=$(echo "$EXTERNAL" | head -n1)
        echo "Configuring single external display: $ext"
        xrandr --output $INTERNAL --auto --primary --output $ext --auto --right-of $INTERNAL
    else
        # Multiple external monitors - chain them
        echo "Configuring multiple external displays"
        prev_output=$INTERNAL
        
        # First, enable the internal display
        xrandr --output $INTERNAL --auto --primary
        
        # Then chain each external monitor
        for ext in $EXTERNAL; do
            echo "Configuring external display: $ext (right of $prev_output)"
            xrandr --output $ext --auto --right-of $prev_output
            prev_output=$ext
        done
    fi
    
    # Restart i3 to refresh workspace assignments
    i3-msg restart
else
    # Only internal display
    echo "Only internal display connected"
    xrandr --output $INTERNAL --auto
    
    # Turn off any disconnected displays
    for output in $(xrandr | grep " disconnected" | cut -d" " -f1); do
        xrandr --output $output --off
    done
fi

# Refresh i3bar
i3-msg reload
