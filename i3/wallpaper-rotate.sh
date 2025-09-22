#!/bin/bash

WALLPAPER_DIR="$HOME/.cache/wallpapers"
CURRENT_WALLPAPER="$WALLPAPER_DIR/current.jpg"
CATEGORIES=("nature" "space" "cityscape")

mkdir -p "$WALLPAPER_DIR"

fetch_wallpaper() {
    local category=$1
    local temp_file="$WALLPAPER_DIR/temp_${category}_$(date +%s).jpg"
    
    echo "Fetching $category wallpaper..."
    
    # Try different image sources
    local urls=(
        "https://picsum.photos/1920/1080?random=$(date +%s)"
        "https://source.unsplash.com/1920x1080/?${category}"
    )
    
    for url in "${urls[@]}"; do
        echo "Trying source..."
        if wget --timeout=10 --tries=2 -q -O "$temp_file" "$url" 2>/dev/null; then
            if [[ -f "$temp_file" ]] && [[ $(stat -c%s "$temp_file") -gt 10000 ]]; then
                mv "$temp_file" "$CURRENT_WALLPAPER"
                echo "Successfully fetched wallpaper"
                return 0
            fi
        fi
        rm -f "$temp_file"
    done
    
    echo "Failed to fetch from all sources"
    return 1
}

set_wallpaper() {
    if command -v feh >/dev/null 2>&1; then
        feh --bg-fill "$CURRENT_WALLPAPER"
    elif command -v nitrogen >/dev/null 2>&1; then
        nitrogen --set-zoom-fill "$CURRENT_WALLPAPER" --save
    elif command -v xwallpaper >/dev/null 2>&1; then
        xwallpaper --zoom "$CURRENT_WALLPAPER"
    else
        echo "Error: No wallpaper setter found. Install feh, nitrogen, or xwallpaper."
        exit 1
    fi
}

rotate_wallpaper() {
    local random_category=${CATEGORIES[$RANDOM % ${#CATEGORIES[@]}]}
    
    if fetch_wallpaper "$random_category"; then
        set_wallpaper
        echo "Wallpaper set: $random_category theme"
    else
        echo "Failed to fetch wallpaper. Keeping current wallpaper."
    fi
}

cleanup_old_wallpapers() {
    find "$WALLPAPER_DIR" -name "temp_*.jpg" -mtime +1 -delete 2>/dev/null
}

case "${1:-}" in
    --once)
        rotate_wallpaper
        cleanup_old_wallpapers
        ;;
    --daemon)
        INTERVAL=${2:-1800}  # Default 30 minutes
        echo "Starting wallpaper rotation daemon (interval: ${INTERVAL}s)"
        while true; do
            rotate_wallpaper
            cleanup_old_wallpapers
            sleep "$INTERVAL"
        done
        ;;
    --category)
        if [[ -n "${2:-}" ]]; then
            if fetch_wallpaper "$2"; then
                set_wallpaper
                echo "Wallpaper set: $2 theme"
            else
                echo "Failed to fetch $2 wallpaper"
            fi
        else
            echo "Usage: $0 --category <nature|space|cityscape>"
        fi
        ;;
    *)
        echo "Wallpaper Rotation Script"
        echo "Usage:"
        echo "  $0 --once              Rotate wallpaper once"
        echo "  $0 --daemon [seconds]  Run as daemon (default: 1800s/30min)"
        echo "  $0 --category <type>   Set specific category wallpaper"
        echo ""
        echo "Categories: nature, space, cityscape"
        ;;
esac