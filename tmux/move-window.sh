#!/bin/bash

# Tmux window mover with fzf
# Allows moving current window to another session

# Get current session and window
current_session=$(tmux display-message -p '#S')
current_window=$(tmux display-message -p '#I')
current_window_name=$(tmux display-message -p '#W')

# Get list of all sessions with window count
sessions=$(tmux list-sessions -F '#{session_name}: #{session_windows} windows' | grep -v "^${current_session}:")

# If no other sessions, offer to create one
if [ -z "$sessions" ]; then
    echo "No other sessions available. Create a new session? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Enter new session name:"
        read -r new_session
        if [ ! -z "$new_session" ]; then
            tmux new-session -d -s "$new_session"
            tmux move-window -t "${new_session}:"
            tmux switch-client -t "$new_session"
        fi
    fi
    exit 0
fi

# Select target session with fzf
target_session=$(echo "$sessions" | fzf --header="Move window '${current_window_name}' to session:" --preview='tmux list-windows -t {1} -F "#{window_index}: #{window_name} [#{window_panes} panes]"' | cut -d: -f1)

# If a session was selected, move the window
if [ ! -z "$target_session" ]; then
    # Move window to target session
    tmux move-window -t "${target_session}:"
    
    # Switch to the target session
    tmux switch-client -t "$target_session"
    
    echo "Moved window '${current_window_name}' to session '${target_session}'"
fi