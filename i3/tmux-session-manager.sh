#!/bin/bash

# Advanced tmux session management for multi-monitor setup
# Provides utilities for managing monitor-specific tmux sessions

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# List all tmux sessions with their status
list_sessions() {
    echo -e "${BLUE}=== Tmux Sessions by Screen ===${NC}"
    
    # Group sessions by screen
    for screen in laptop external1 external2; do
        sessions=$(tmux list-sessions 2>/dev/null | grep "^${screen}-" | cut -d: -f1)
        if [ ! -z "$sessions" ]; then
            echo -e "\n${GREEN}${screen}:${NC}"
            while IFS= read -r session; do
                workspace=$(echo "$session" | cut -d- -f2)
                attached=""
                if tmux list-sessions 2>/dev/null | grep "^${session}:" | grep -q "(attached)"; then
                    attached=" ${YELLOW}[attached]${NC}"
                fi
                echo -e "  • ${session}${attached}"
            done <<< "$sessions"
        fi
    done
    
    # Show other sessions
    other_sessions=$(tmux list-sessions 2>/dev/null | grep -v -E "^(laptop|external1|external2)-" | cut -d: -f1)
    if [ ! -z "$other_sessions" ]; then
        echo -e "\n${BLUE}Other sessions:${NC}"
        while IFS= read -r session; do
            attached=""
            if tmux list-sessions 2>/dev/null | grep "^${session}:" | grep -q "(attached)"; then
                attached=" ${YELLOW}[attached]${NC}"
            fi
            echo -e "  • ${session}${attached}"
        done <<< "$other_sessions"
    fi
}

# Kill all sessions for a specific screen
kill_screen_sessions() {
    local screen=$1
    if [ -z "$screen" ]; then
        echo -e "${RED}Error: Please specify a screen (laptop, external1, external2)${NC}"
        return 1
    fi
    
    sessions=$(tmux list-sessions 2>/dev/null | grep "^${screen}-" | cut -d: -f1)
    if [ -z "$sessions" ]; then
        echo -e "${YELLOW}No sessions found for screen: ${screen}${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Killing all sessions for ${screen}...${NC}"
    while IFS= read -r session; do
        tmux kill-session -t "$session" 2>/dev/null
        echo -e "  ${RED}✗${NC} Killed: $session"
    done <<< "$sessions"
}

# Rename a session
rename_session() {
    local old_name=$1
    local new_name=$2
    
    if [ -z "$old_name" ] || [ -z "$new_name" ]; then
        echo -e "${RED}Error: Usage: rename_session <old_name> <new_name>${NC}"
        return 1
    fi
    
    if tmux has-session -t "$old_name" 2>/dev/null; then
        tmux rename-session -t "$old_name" "$new_name"
        echo -e "${GREEN}✓${NC} Renamed: $old_name → $new_name"
    else
        echo -e "${RED}Error: Session '$old_name' not found${NC}"
        return 1
    fi
}

# Switch to a different session
switch_session() {
    local session_name=$1
    
    if [ -z "$session_name" ]; then
        # Interactive session picker using fzf if available
        if command -v fzf &> /dev/null; then
            session_name=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --prompt="Select session: ")
        else
            echo -e "${RED}Error: Please specify a session name${NC}"
            list_sessions
            return 1
        fi
    fi
    
    if [ ! -z "$session_name" ] && tmux has-session -t "$session_name" 2>/dev/null; then
        if [ -n "$TMUX" ]; then
            tmux switch-client -t "$session_name"
        else
            tmux attach-session -t "$session_name"
        fi
    else
        echo -e "${RED}Error: Session '$session_name' not found${NC}"
        return 1
    fi
}

# Create a new session for current monitor/workspace
new_session_here() {
    # Source the functions from smart-terminal.sh
    source /home/jens/.config/i3/smart-terminal.sh
    local session_name=$(get_session_name)
    
    if tmux has-session -t "$session_name" 2>/dev/null; then
        echo -e "${YELLOW}Session '$session_name' already exists${NC}"
        return 1
    fi
    
    tmux new-session -d -s "$session_name"
    echo -e "${GREEN}✓${NC} Created new session: $session_name"
}

# Clean up detached sessions
cleanup_detached() {
    local detached=$(tmux list-sessions 2>/dev/null | grep -v "(attached)" | cut -d: -f1)
    
    if [ -z "$detached" ]; then
        echo -e "${GREEN}No detached sessions to clean up${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Found detached sessions:${NC}"
    echo "$detached"
    echo -e "\n${YELLOW}Kill all detached sessions? (y/N)${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        while IFS= read -r session; do
            tmux kill-session -t "$session" 2>/dev/null
            echo -e "  ${RED}✗${NC} Killed: $session"
        done <<< "$detached"
    fi
}

# Main menu
show_menu() {
    echo -e "${BLUE}=== Tmux Session Manager ===${NC}"
    echo "1. List all sessions"
    echo "2. Switch to session"
    echo "3. Kill screen sessions"
    echo "4. Rename session"
    echo "5. Create session for current workspace"
    echo "6. Cleanup detached sessions"
    echo "7. Exit"
    echo -n "Select option: "
}

# Main execution
case "$1" in
    list)
        list_sessions
        ;;
    kill-screen)
        kill_screen_sessions "$2"
        ;;
    rename)
        rename_session "$2" "$3"
        ;;
    switch)
        switch_session "$2"
        ;;
    new)
        new_session_here
        ;;
    cleanup)
        cleanup_detached
        ;;
    *)
        if [ -z "$1" ]; then
            # Interactive mode
            while true; do
                show_menu
                read -r option
                case $option in
                    1) list_sessions ;;
                    2) 
                        echo -n "Session name: "
                        read -r session
                        switch_session "$session"
                        ;;
                    3)
                        echo -n "Screen (laptop/external1/external2): "
                        read -r screen
                        kill_screen_sessions "$screen"
                        ;;
                    4)
                        echo -n "Old name: "
                        read -r old
                        echo -n "New name: "
                        read -r new
                        rename_session "$old" "$new"
                        ;;
                    5) new_session_here ;;
                    6) cleanup_detached ;;
                    7) exit 0 ;;
                    *) echo -e "${RED}Invalid option${NC}" ;;
                esac
                echo
            done
        else
            echo "Usage: $0 [command] [args]"
            echo "Commands:"
            echo "  list                    - List all sessions"
            echo "  kill-screen <screen>    - Kill all sessions for a screen"
            echo "  rename <old> <new>      - Rename a session"
            echo "  switch <session>        - Switch to a session"
            echo "  new                     - Create session for current workspace"
            echo "  cleanup                 - Cleanup detached sessions"
            echo ""
            echo "Run without arguments for interactive mode"
        fi
        ;;
esac