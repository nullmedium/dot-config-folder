#!/bin/bash

# Advanced tmux operations menu using fzf
# Provides a unified interface for various tmux operations

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Main menu options
show_menu() {
    echo "Session: Switch to session"
    echo "Window: Switch to window"
    echo "Move Window: Move current window to another session"
    echo "Move Pane: Move current pane to another window"
    echo "Swap Window: Swap current window with another"
    echo "Rename Window: Rename current window"
    echo "Rename Session: Rename current session"
    echo "Kill Window: Kill a window"
    echo "Kill Session: Kill a session"
    echo "New Session: Create new session"
    echo "Link Window: Link window from another session"
    echo "Unlink Window: Unlink current window"
}

# Function to switch session
switch_session() {
    tmux list-sessions -F '#{session_name}: #{session_windows} windows#{?session_attached, (attached),}' | \
    fzf --header='Switch to session:' \
        --preview='tmux list-windows -t {1} -F "#{window_index}: #{window_name} [#{window_panes} panes]"' | \
    cut -d: -f1 | \
    xargs -I {} tmux switch-client -t {}
}

# Function to switch window
switch_window() {
    tmux list-windows -a -F '#{session_name}:#{window_index}: #{window_name}' | \
    fzf --header='Switch to window:' \
        --preview='tmux list-panes -t {1} -F "Pane #{pane_index}: #{pane_current_command}"' | \
    cut -d: -f1,2 | \
    xargs -I {} tmux switch-client -t {}
}

# Function to move current window
move_window() {
    current_window=$(tmux display-message -p '#W')
    target=$(tmux list-sessions -F '#{session_name}' | \
             fzf --header="Move window '${current_window}' to session:" \
                 --preview='tmux list-windows -t {} -F "#{window_index}: #{window_name}"')
    
    if [ ! -z "$target" ]; then
        tmux move-window -t "${target}:"
        tmux switch-client -t "$target"
    fi
}

# Function to move current pane
move_pane() {
    target=$(tmux list-windows -a -F '#{session_name}:#{window_index}: #{window_name}' | \
             fzf --header='Move pane to window:' \
                 --preview='tmux list-panes -t {1} -F "Pane #{pane_index}: #{pane_current_command}"')
    
    if [ ! -z "$target" ]; then
        window_target=$(echo "$target" | cut -d: -f1,2)
        tmux join-pane -t "$window_target"
    fi
}

# Function to swap windows
swap_window() {
    target=$(tmux list-windows -F '#{window_index}: #{window_name}' | \
             fzf --header='Swap current window with:')
    
    if [ ! -z "$target" ]; then
        window_idx=$(echo "$target" | cut -d: -f1)
        tmux swap-window -t "$window_idx"
    fi
}

# Function to rename window
rename_window() {
    echo -n "New window name: "
    read -r new_name
    if [ ! -z "$new_name" ]; then
        tmux rename-window "$new_name"
    fi
}

# Function to rename session
rename_session() {
    echo -n "New session name: "
    read -r new_name
    if [ ! -z "$new_name" ]; then
        tmux rename-session "$new_name"
    fi
}

# Function to kill window
kill_window() {
    target=$(tmux list-windows -a -F '#{session_name}:#{window_index}: #{window_name}' | \
             fzf --header='Kill window:' --multi \
                 --preview='tmux list-panes -t {1} -F "Pane #{pane_index}: #{pane_current_command}"')
    
    if [ ! -z "$target" ]; then
        echo "$target" | while IFS= read -r window; do
            window_target=$(echo "$window" | cut -d: -f1,2)
            tmux kill-window -t "$window_target"
        done
    fi
}

# Function to kill session
kill_session() {
    target=$(tmux list-sessions -F '#{session_name}: #{session_windows} windows#{?session_attached, (attached),}' | \
             fzf --header='Kill session:' --multi \
                 --preview='tmux list-windows -t {1} -F "#{window_index}: #{window_name}"')
    
    if [ ! -z "$target" ]; then
        echo "$target" | while IFS= read -r session; do
            session_name=$(echo "$session" | cut -d: -f1)
            tmux kill-session -t "$session_name"
        done
    fi
}

# Function to create new session
new_session() {
    echo -n "New session name: "
    read -r session_name
    if [ ! -z "$session_name" ]; then
        tmux new-session -d -s "$session_name"
        tmux switch-client -t "$session_name"
    fi
}

# Function to link window from another session
link_window() {
    target=$(tmux list-windows -a -F '#{session_name}:#{window_index}: #{window_name}' | \
             fzf --header='Link window:' \
                 --preview='tmux list-panes -t {1} -F "Pane #{pane_index}: #{pane_current_command}"')
    
    if [ ! -z "$target" ]; then
        source_window=$(echo "$target" | cut -d' ' -f1)
        tmux link-window -s "$source_window"
    fi
}

# Function to unlink current window
unlink_window() {
    tmux unlink-window
    echo "Current window unlinked"
}

# Main execution
if [ "$1" == "--menu" ] || [ -z "$1" ]; then
    # Show interactive menu
    selection=$(show_menu | fzf --header='Tmux Operations:' | cut -d: -f1)
    
    case "$selection" in
        "Session") switch_session ;;
        "Window") switch_window ;;
        "Move Window") move_window ;;
        "Move Pane") move_pane ;;
        "Swap Window") swap_window ;;
        "Rename Window") rename_window ;;
        "Rename Session") rename_session ;;
        "Kill Window") kill_window ;;
        "Kill Session") kill_session ;;
        "New Session") new_session ;;
        "Link Window") link_window ;;
        "Unlink Window") unlink_window ;;
    esac
else
    # Direct command execution
    case "$1" in
        session) switch_session ;;
        window) switch_window ;;
        move-window) move_window ;;
        move-pane) move_pane ;;
        swap-window) swap_window ;;
        rename-window) rename_window ;;
        rename-session) rename_session ;;
        kill-window) kill_window ;;
        kill-session) kill_session ;;
        new-session) new_session ;;
        link-window) link_window ;;
        unlink-window) unlink_window ;;
        *) echo "Unknown command: $1" ;;
    esac
fi