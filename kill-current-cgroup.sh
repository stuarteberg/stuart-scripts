#!/bin/bash

# Determine the current cgroup of this script
CGROUP=$(cat /proc/self/cgroup | grep -o ':[^:]*:[^:]*$' | cut -d':' -f3)
if [ -z "$CGROUP" ]; then
    echo "Error: Unable to determine the current cgroup."
    exit 1
fi

echo "This script is running in cgroup: $CGROUP"

# Find all PIDs in the cgroup
CGROUP_PROCS="/sys/fs/cgroup/$CGROUP/cgroup.procs"
if [ ! -f "$CGROUP_PROCS" ]; then
    echo "Error: Unable to locate cgroup processes file: $CGROUP_PROCS."
    exit 1
fi

# Get the current script's PID
SELF_PID=$$

# Read all process IDs in the cgroup
PIDS=$(cat "$CGROUP_PROCS")
if [ -z "$PIDS" ]; then
    echo "Error: No processes found in cgroup $CGROUP."
    exit 1
fi

# Remove the script's own PID from the list
PIDS=$(echo "$PIDS" | grep -v "^$SELF_PID$")

# Display processes and their command lines
echo "Processes in cgroup $CGROUP (excluding this script):"
for PID in $PIDS; do
    if [ -d "/proc/$PID" ]; then
        CMDLINE=$(tr '\0' ' ' < /proc/$PID/cmdline)
        echo "PID: $PID, Command: $CMDLINE"
    else
        echo "PID: $PID, Command: <Process no longer exists>"
    fi
done

# Confirm shutdown with y/n
read -p "Do you want to terminate all these processes in reverse order? (y/n) [default: n]: " CONFIRM
CONFIRM=${CONFIRM:-n}

if [[ "$CONFIRM" != "y" ]]; then
    echo "Aborting shutdown."
    exit 0
fi

# Kill all processes in reverse PID order
echo "Shutting down all processes in reverse PID order in cgroup $CGROUP..."
REVERSE_PIDS=$(echo "$PIDS" | sort -nr) # Sort PIDs in reverse numerical order

# Avoid killing ourselves when our parent dies
trap '' SIGTERM SIGHUP
kill ${REVERSE_PIDS}

echo "Done"
exit 0
