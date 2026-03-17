#!/bin/bash

# ─── CONFIG ───────────────────────────────────────────────────────────────────
LOGFILE="/home/publiek/log.txt"
PIDFILE="/tmp/cafe_session.pid"
ENDTIME_FILE="/tmp/cafe_endtime"
# Password hash - to change password, run: echo -n "yourpassword" | sha256sum
PASSWORD_HASH="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
# ──────────────────────────────────────────────────────────────────────────────

z_info()    { DISPLAY=:0 zenity --info --title="Internet Cafe" --text="$1" --timeout=${2:-10} 2>/dev/null & }
z_warn()    { DISPLAY=:0 zenity --warning --title="Internet Cafe" --text="$1" --timeout=${2:-30} 2>/dev/null & }
z_error()   { DISPLAY=:0 zenity --error --title="Internet Cafe" --text="$1" --timeout=${2:-10} 2>/dev/null & }

check_password() {
  entered=$(zenity --password --title="Internet Cafe" 2>/dev/null)
  if [ $? -ne 0 ]; then exit 1; fi
  entered_hash=$(echo -n "$entered" | sha256sum | awk '{print $1}')
  if [ "$entered_hash" != "$PASSWORD_HASH" ]; then
    z_error "Incorrect password."
    exit 1
  fi
}

# ─── EXTENSION: session already running ───────────────────────────────────────
if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then

  check_password

  extra=$(zenity --entry \
    --title="Internet Cafe" \
    --text="Session is active. How many minutes to add?" \
    --entry-text="20" 2>/dev/null)

  if [ $? -ne 0 ]; then exit 1; fi

  if ! [[ "$extra" =~ ^[0-9]+$ ]] || [ "$extra" -le 0 ]; then
    z_error "Invalid number of minutes."
    exit 1
  fi

  current_end=$(cat "$ENDTIME_FILE")
  new_end=$((current_end + extra * 60))
  echo "$new_end" > "$ENDTIME_FILE"

  remaining=$(( (new_end - $(date +%s)) / 60 ))
  z_info "Session extended by ${extra} minutes.\nNew remaining time: ${remaining} minutes."
  echo "Session extended by ${extra} minutes at: $(date)" >> "$LOGFILE"
  exit 0
fi

# ─── NEW SESSION ──────────────────────────────────────────────────────────────
duration=$(zenity --entry \
  --title="Internet Cafe" \
  --text="Enter session duration in minutes:" \
  --entry-text="30" 2>/dev/null)

if [ $? -ne 0 ]; then
  z_error "Session cancelled."
  exit 1
fi

if ! [[ "$duration" =~ ^[0-9]+$ ]] || [ "$duration" -le 0 ]; then
  z_error "Invalid duration. Please enter a number greater than 0."
  exit 1
fi

# Write PID and end time
echo $$ > "$PIDFILE"
end_time=$(( $(date +%s) + duration * 60 ))
echo "$end_time" > "$ENDTIME_FILE"

echo "Session started: $(date) | Duration: ${duration} minutes" >> "$LOGFILE"
z_info "Session started. You have ${duration} minutes."

# ─── TIMER LOOP ───────────────────────────────────────────────────────────────
warning_sent=0

while true; do
  now=$(date +%s)
  end_time=$(cat "$ENDTIME_FILE")
  remaining=$((end_time - now))

  if [ "$remaining" -le 0 ]; then
    break
  fi

  # 5 minute warning (only once)
  if [ "$remaining" -le 300 ] && [ "$warning_sent" -eq 0 ]; then
    z_warn "Your session ends in 5 minutes!\nPlease save your work or it will be lost."
    warning_sent=1
  fi

  sleep 10
done

# ─── END SESSION ──────────────────────────────────────────────────────────────
echo "Session ended: $(date)" >> "$LOGFILE"
rm -f "$PIDFILE" "$ENDTIME_FILE"

pkill -TERM -u publiek
sleep 5
pkill -KILL -u publiek 2>/dev/null
