#!/bin/bash
# by spiritlhl
# from https://github.com/spiritLHLS/Oracle-server-keep-alive-script

pid_file=/tmp/memory-limit.pid
if [ -e "${pid_file}" ]; then
  # If the PID file exists, read the PID from it
  pid=$(cat "${pid_file}")
  # Check if the PID corresponds to a running process
  if ps -p "${pid}" > /dev/null; then
    echo "Error: Another instance of memory-limit.sh is already running with PID ${pid}"
    exit 1
  fi
  # If the PID file exists but the corresponding process has stopped running, delete the PID file
  rm "${pid_file}"
fi
echo $$ > "${pid_file}"

while true
do
  mem_total=$(free | awk '/Mem/ {print $2}')
  mem_used=$(free | awk '/Mem/ {print $3}')
  mem_usage=$(echo "scale=2; $mem_used/$mem_total * 100.0" | bc)
  if [ $(echo "$mem_usage < 25" | bc) -eq 1 ]; then
    target_mem_usage=$(echo "scale=0; $mem_total * 0.25 / 1" | bc)
    stress_mem=$(echo "$target_mem_usage - $mem_used" | bc)
    stress_mem_in_gb=$(echo "scale=0; $stress_mem / 1024 / 1024" | bc)
    fallocate -l "${stress_mem_in_gb}G" /dev/shm/file
    sleep 300
    rm /dev/shm/file
  else
    sleep 300
  fi
done

rm "${pid_file}"
