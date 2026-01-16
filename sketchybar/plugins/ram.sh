#!/bin/sh

# Get memory stats using vm_stat
STATS=$(vm_stat)

# Parse page size and memory values
PAGE_SIZE=$(pagesize)
PAGES_FREE=$(echo "$STATS" | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
PAGES_ACTIVE=$(echo "$STATS" | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
PAGES_INACTIVE=$(echo "$STATS" | grep "Pages inactive" | awk '{print $3}' | sed 's/\.//')
PAGES_SPECULATIVE=$(echo "$STATS" | grep "Pages speculative" | awk '{print $3}' | sed 's/\.//')
PAGES_WIRED=$(echo "$STATS" | grep "Pages wired" | awk '{print $4}' | sed 's/\.//')
PAGES_COMPRESSED=$(echo "$STATS" | grep "Pages occupied by compressor" | awk '{print $5}' | sed 's/\.//')

# Calculate used memory in GB
USED_PAGES=$((PAGES_ACTIVE + PAGES_WIRED + PAGES_COMPRESSED))
USED_BYTES=$((USED_PAGES * PAGE_SIZE))
USED_GB=$(echo "scale=1; $USED_BYTES / 1073741824" | bc)

# Get total RAM
TOTAL_BYTES=$(sysctl -n hw.memsize)
TOTAL_GB=$(echo "scale=0; $TOTAL_BYTES / 1073741824" | bc)

# Calculate percentage
USED_PERCENT=$(echo "scale=0; ($USED_BYTES * 100) / $TOTAL_BYTES" | bc)

sketchybar --set "$NAME" icon="󰍛" label="${USED_GB}G"
