#!/bin/sh
# The msm DRM driver lights the marble panel only after a disable/enable
# cycle (KWin does one when it starts). Cycle it in the initramfs so the FDE
# unlock screen is visible; without the pauses the panel stays dark.
fb=/sys/class/graphics/fb0/blank
if [ -w "$fb" ]; then
	echo 1 > "$fb"
	sleep 1
	echo 0 > "$fb"
	sleep 1
fi
