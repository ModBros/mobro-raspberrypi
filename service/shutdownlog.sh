#!/bin/bash

LOG_DIR='/mobro/log'
LOG_FILE='/tmp/mobro_log'

# make sure the log dir exists
mkdir -p "$LOG_DIR"

# copy log files to preserve the previous 10 starts
if [[ -f "$LOG_FILE" ]]; then
  for i in {8..0}; do
    if [[ -f "$LOG_DIR/log_$i.txt" ]]; then
      mv -f "$LOG_DIR/log_$i.txt" "$LOG_DIR/log_$((i + 1)).txt" 2>/dev/null
    fi
  done
  cp -f "$LOG_FILE" "$LOG_DIR/log_0.txt" 2>/dev/null
fi
