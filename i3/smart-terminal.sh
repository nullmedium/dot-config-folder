#!/bin/bash

# Smart terminal launcher with monitor-aware tmux sessions
# This script detects the current monitor and workspace to create/attach to appropriate tmux sessions

# Get the focused monitor using i3-msg
get_current_monitor() {
    if command -v i3-msg &> /dev/null && i3-msg -t get_workspaces &>/dev/null; then
        i3-msg -t get_workspaces 2>/dev/null | jq -r '.[] | select(.focused==true) | .output' 2>/dev/null
    else
        echo "default"
    fi
}

# Get the current workspace number
get_current_workspace() {
    if command -v i3-msg &> /dev/null && i3-msg -t get_workspaces &>/dev/null; then
        i3-msg -t get_workspaces 2>/dev/null | jq -r '.[] | select(.focused==true) | .num' 2>/dev/null
    else
        echo "1"
    fi
}

# Determine session name based on monitor and workspace
get_session_name() {
    local monitor=$(get_current_monitor)
    local workspace=$(get_current_workspace)
    
    # Fallback if we can't get monitor/workspace info
    if [ -z "$monitor" ] || [ "$monitor" = "null" ]; then
        monitor="default"
    fi
    if [ -z "$workspace" ] || [ "$workspace" = "null" ]; then
        workspace="1"
    fi
    
    # Clean monitor name (remove special characters)
    monitor_clean=$(echo "$monitor" | sed 's/[^a-zA-Z0-9-]/_/g')
    
    # Map monitors to logical screen names
    case "$monitor_clean" in
        "eDP_1"|"eDP1")
            screen="laptop"
            ;;
        "DVI_I_2_2"|"HDMI_1"|"HDMI1"|"DP_1"|"DP1")
            screen="external1"
            ;;
        "DVI_I_1_1"|"HDMI_2"|"HDMI2"|"DP_2"|"DP2")
            screen="external2"
            ;;
        "default")
            screen="main"
            ;;
        *)
            screen="${monitor_clean}"
            ;;
    esac
    
    # Create session name: screen-workspace (e.g., laptop-1, external1-5)
    if [ "$screen" = "main" ]; then
        echo "main"
    else
        echo "${screen}-ws${workspace}"
    fi
}

# Launch alacritty with tmux
launch_terminal() {
    local session_name=$(get_session_name)
    
    # Debug logging (remove after testing)
    echo "Launching terminal with session: $session_name" >> /tmp/smart-terminal.log
    
    # Check if alacritty exists
    ALACRITTY_PATH="/home/jens/.cargo/bin/alacritty"
    if [ ! -x "$ALACRITTY_PATH" ]; then
        ALACRITTY_PATH=$(which alacritty 2>/dev/null)
        if [ -z "$ALACRITTY_PATH" ]; then
            # Fallback to xterm or another terminal
            echo "Alacritty not found, falling back to xterm" >> /tmp/smart-terminal.log
            xterm -e tmux new-session -A -s "$session_name" &
            exit 0
        fi
    fi
    
    # Check if tmux session exists
    if tmux has-session -t "$session_name" 2>/dev/null; then
        # Session exists, attach to it
        "$ALACRITTY_PATH" --title "Terminal [$session_name]" -e tmux attach-session -t "$session_name" &
    else
        # Create new session with meaningful name
        "$ALACRITTY_PATH" --title "Terminal [$session_name]" -e tmux new-session -s "$session_name" &
    fi
}

# Main execution
launch_terminal