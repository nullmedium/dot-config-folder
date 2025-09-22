#!/bin/bash

# Simple fallback terminal launcher
# Uses alacritty directly without complex session detection

ALACRITTY="/home/jens/.cargo/bin/alacritty"

if [ -x "$ALACRITTY" ]; then
    exec "$ALACRITTY"
else
    # Fallback to xterm
    exec xterm
fi