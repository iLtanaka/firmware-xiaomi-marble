#!/bin/sh
# marble-kwin-boost.sh: give the compositor a CPU frequency floor (uclamp.min)
#
# schedutil leaves the little cores at ~0.5 GHz between touch events, so KWin
# misses the 8.3 ms frame budget at 120 Hz. A per-task uclamp.min only costs
# power while KWin actually runs. New threads and a kwin_wayland restarted by
# kwin_wayland_wrapper inherit the clamp from their parent.
# (A cgroup clamp does not work here: it is capped by root-owned parents.)

UCLAMP_MIN=512
wrapper="$1"
[ -n "$wrapper" ] || exit 0

uclampset -m "$UCLAMP_MIN" -a -p "$wrapper"

# The wrapper spawns kwin_wayland asynchronously; wait up to 10 s for it
i=0
while [ $i -lt 20 ]; do
	kwin=$(pgrep -P "$wrapper" -x kwin_wayland)
	if [ -n "$kwin" ]; then
		uclampset -m "$UCLAMP_MIN" -a -p "$kwin"
		exit 0
	fi
	sleep 0.5
	i=$((i + 1))
done
exit 0
