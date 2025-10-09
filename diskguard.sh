#!/usr/bin/env bash

# ·▄▄▄▄  ▪  .▄▄ · ▄ •▄  ▄▄ • ▄• ▄▌ ▄▄▄· ▄▄▄  ·▄▄▄▄  
# ██▪ ██ ██ ▐█ ▀. █▌▄▌▪▐█ ▀ ▪█▪██▌▐█ ▀█ ▀▄ █·██▪ ██ 
# ▐█· ▐█▌▐█·▄▀▀▀█▄▐▀▀▄·▄█ ▀█▄█▌▐█▌▄█▀▀█ ▐▀▀▄ ▐█· ▐█▌
# ██. ██ ▐█▌▐█▄▪▐█▐█.█▌▐█▄▪▐█▐█▄█▌▐█ ▪▐▌▐█•█▌██. ██ 
# ▀▀▀▀▀• ▀▀▀ ▀▀▀▀ ·▀  ▀·▀▀▀▀  ▀▀▀  ▀  ▀ .▀  ▀▀▀▀▀▀•

# `diskguard` is a software based, USB disk write blocker for MacOS. 
# It works by detecting when an external USB disk is mounted and then remounts it in read-only mode.

# **IMPORTANT:** This method may not be forensically sound. 
# If chain of custody is important use a hardware based write-blocker instead of this tool.

# Use at your own risk. 
# The author is not responsible for any loss of data, financial loss or damage to your system.

set -euo pipefail

VERSION='1.0.0'
DISK_ID=''
declare -a DISKS_ARR=()

LOG_PATH='/var/log/diskguard/'
LOG_FILE='diskguard.log'

RED='\033[91m'
YELLOW='\033[93m'
GREEN='\033[92m'
RESET='\033[0m'

# Display ASCII art banner
banner() {
  echo "·▄▄▄▄  ▪  .▄▄ · ▄ •▄  ▄▄ • ▄• ▄▌ ▄▄▄· ▄▄▄  ·▄▄▄▄  ";
  echo "██▪ ██ ██ ▐█ ▀. █▌▄▌▪▐█ ▀ ▪█▪██▌▐█ ▀█ ▀▄ █·██▪ ██ ";
  echo "▐█· ▐█▌▐█·▄▀▀▀█▄▐▀▀▄·▄█ ▀█▄█▌▐█▌▄█▀▀█ ▐▀▀▄ ▐█· ▐█▌";
  echo "██. ██ ▐█▌▐█▄▪▐█▐█.█▌▐█▄▪▐█▐█▄█▌▐█ ▪▐▌▐█•█▌██. ██ ";
  echo "▀▀▀▀▀• ▀▀▀ ▀▀▀▀ ·▀  ▀·▀▀▀▀  ▀▀▀  ▀  ▀ .▀  ▀▀▀▀▀▀• ";
}

# Display usage information
usage() {
  echo "Usage: $0 <disk identifier (optional)> [-h] [-v] [-a] [-w] [-l] [-t]"
  echo ""
  echo "  -h, --help    Display this help message."
  echo "  -v, --version Display version information."
  echo "  -a, --all     Set read-only all USB volumes."
  echo "  -b, --block   Write-block a single USB volume. Disk identifier argument required."
  echo "  -w, --watch   Watch for newly mounted volumes."
  echo "  -l, --list    Display all USB volumes. Default."
  echo "  -t, --test    Test a volume is read-only. Disk identifier argument required."
  echo ""
  exit 0
}

# Display version number
version() {
  echo "$VERSION"
  exit 0
}

# Verify script is running with root privileges
check_permissions() {
  # Check if running as root
  if [ "$EUID" -ne 0 ]; then 
    fatal "This script must be run with sudo" | append_log
  fi
}

# Verify script is running on macOS
check_darwin() {
  if [ "$(uname)" != "Darwin" ]; then
    fatal "This script is only supported on macOS" | append_log
  fi
}

# Create log directory if it doesn't exist
ensure_log_path() {
  ensure_dir "$LOG_PATH"
}

# Create log file if it doesn't exist
ensure_log_file() {
  ensure_file "$LOG_PATH$LOG_FILE"
}

# Initialize all required directories and files
ensure_paths() {
  ensure_log_path
  ensure_log_file
}

# Perform initial setup checks and initialization
setup() {
  check_permissions
  check_darwin
  ensure_paths
}

# Create directory if it doesn't exist
ensure_dir() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
  fi
}

# Create file if it doesn't exist
ensure_file() {
  if [ ! -f "$1" ]; then
    touch "$1"
  fi
}

# Display error message and exit
fatal() {
  echo -e "${RED}Error: $1${RESET}"
  exit 1
}

# Log message with timestamp to file and display clean output to stdout
# TODO: Standardise log format
append_log() {
  while IFS= read -r line; do
    echo "$(date): $line" >> "$LOG_PATH$LOG_FILE"
    echo "$line"
  done
}

# Display info message
info() {
  echo -e "${YELLOW}Info: $1${RESET}"
}

# Block all USB volumes
block_all() {
  if [ ${#DISKS_ARR[@]} -gt 0 ]; then
    for i in "${DISKS_ARR[@]}"; do
      block_one "$i"
    done
  else
    fatal "No external USB volumes found" | append_log
  fi
}

# Block a single USB volume by remounting as read-only
block_one() {
  local DISK="$1"
  local DISK_INFO
  
  if [ -z "$DISK" ]; then
    fatal "Disk identifier is required" | append_log
  fi
  if ! is_mounted "$DISK"; then
    fatal "$DISK is not mounted" | append_log
  fi
  # TODO: Check disk / volume mount error
  if is_readonly "$DISK"; then 
    info "$DISK is already read-only" | append_log
  fi
  
  DISK_INFO=$(get_disk_info "$1")
  MOUNT=$(get_disk_mount "$DISK_INFO")
  unmount_disk "$MOUNT"
  mount_disk_readonly "$MOUNT"

  if is_readonly "$DISK"; then
    echo -e "${GREEN}Success: $DISK is read-only${RESET}" | append_log
  fi
}

# Watch for newly mounted volumes
watch() {
  echo -e "Watching for new volumes... (ctrl+c to cancel)" | append_log
  local PREV_DISKS_ARR=("${DISKS_ARR[@]}")
  while true; do 
    get_disk_ids
    # TODO: Improve array comparison
    if [ ${#DISKS_ARR[@]} -gt ${#PREV_DISKS_ARR[@]} ]; then
      for i in "${DISKS_ARR[@]}"; do
        if [[ ! "${PREV_DISKS_ARR[*]}" =~ ${i} ]]; then
          echo -e "${GREEN}New USB volume detected!${RESET}" | append_log
          block_one "$i"
        fi
      done
    fi
    PREV_DISKS_ARR=("${DISKS_ARR[@]}")
    sleep 1
  done
}

# Get disk information and pass to callback function
get_disk_info() {
  diskutil info "$1" 2>/dev/null
}

# Extract volume mount point from disk info
get_volume_mount() {
  echo -e "$(echo "$1" | grep "Mount Point:" | cut -d: -f2 | xargs)"
}

# Extract device node from disk info
get_disk_mount() {
  echo -e "$(echo "$1" | grep "Device Node:" | cut -d: -f2 | xargs)"
}

# Extract disk size from disk info
get_disk_size() {
  echo -e "$(echo "$1" | grep "Disk Size:" | cut -d: -f2 | grep -oE "[0-9]+\.[0-9]+ [A-Z]{2}" | head -1)" || echo -e "Unknown"
}

# Extract file system type from disk info
get_disk_fs() {
  echo -e "$(echo "$1" | grep "File System Personality:" | cut -d: -f2 | xargs)" || echo -e "Unknown"
}

# Extract volume name from disk info
get_disk_volume_name() {
  echo -e "$(echo "$1" | grep "Volume Name:" | cut -d: -f2 | xargs)" || echo -e "Untitled"
}

# Get colored write status for disk
get_disk_write_status() {
  if is_readonly "$1"; then
    echo -e "${GREEN}[READ-ONLY]${RESET}"
  else 
    echo -e "${YELLOW}[WRITEABLE]${RESET}"
  fi
}

# Check if disk is mounted
is_mounted() {
  local MOUNTED 
  MOUNTED="$(diskutil info "$1" 2>/dev/null | grep "Mounted:" | cut -d: -f2 | xargs)"
  if [ "$MOUNTED" = "No" ]; then
    return 1
  fi 
  return 0
}

# Check if disk is writable
is_writable() {
  if [ "$(diskutil info "$1" | grep "Volume Read-Only:" | cut -d: -f2 | xargs)" = "Yes" ]; then
    return 1
  fi
  return 0
}

# Unmount disk
unmount_disk() {
  if ! diskutil unmount "$1"; then 
    fatal "Failed to unmount $1" | append_log
  fi 
}

# Mount disk in read-only mode
mount_disk_readonly() {
  if ! diskutil mount readOnly "$1"; then
    fatal "Failed to mount $1 in read-only mode" | append_log
  fi
}

# Check if disk is read-only
is_readonly() {
  if [ "$(diskutil info "$1" | grep "Volume Read-Only:" | cut -d: -f2 | xargs)" = "No" ]; then
    return 1
  fi
  return 0
}

# Populate array with external USB disk identifiers
get_disk_ids() {
  while IFS= read -r LINE; do
    local DISKS_ID
    DISKS_ID="$(echo "$LINE" | awk '{print $NF}')"
    if grep -Eq "^disk[0-9]+s[0-9]+" < <(echo "$DISKS_ID"); then
      DISKS_ARR+=("$DISKS_ID")
    fi
  done < <(diskutil list external physical | grep -E "^\s+[0-9]:")
}

# Display list of all external USB volumes
list() {
  if [ ${#DISKS_ARR[@]} -gt 0 ]; then

    printf "%s\t\t%s\t\t%s\t\t%s\t\t%s\t\t%s\n" "STATUS" "ID" "NAME" "SIZE" "FILE SYSTEM" "MOUNT" | append_log

    for i in "${DISKS_ARR[@]}"; do 

      ID="$i"
      DISK_INFO=$(get_disk_info "$ID")
      STATUS=$(get_disk_write_status "$ID")
      NAME=$(get_disk_volume_name "$DISK_INFO")
      SIZE=$(get_disk_size "$DISK_INFO")
      FS=$(get_disk_fs "$DISK_INFO")
      MOUNT=$(get_volume_mount "$DISK_INFO")

      if grep -Eq "^disk[0-9]+s[0-9]+" < <(echo "$ID"); then
        printf "%s\t%s\t\t%s\t%s\t\t%s\t\t\t%s\n" "$STATUS" "$ID" "$NAME" "$SIZE" "$FS" "$MOUNT" | append_log
      fi

    done

  else
    fatal "No external USB volumes found" | append_log
  fi
  exit 0
}

# Test if a disk is read-only
test() {
  local DISK="$1"
  if [ -z "$DISK" ]; then
    fatal "Disk identifier is required" | append_log
  fi
  if is_mounted "$DISK"; then
    if is_readonly "$DISK"; then
      echo -e "${GREEN}Disk $DISK is read-only.${RESET}" | append_log
    else 
      echo -e "${RED}Disk $DISK is writable.${RESET}" | append_log
    fi
  else
    fatal "Disk $DISK is not mounted" | append_log
  fi
  exit 0
}

# Parse command line arguments
parse_args() {
  while [ $# -gt 0 ]; do
    case $1 in 
      disk*) DISK_ID=$1 ;;
      -h|--help) usage ;;
      -v|--version) version ;;
      -a|--all) block_all ;;
      -b|--block) block_one "$DISK_ID" ;;
      -w|--watch) watch ;;
      -l|--list) list ;;
      -t|--test) test "$DISK_ID" ;;
      *) list ;;
    esac
    shift
  done
}

# Main entry point
function main() {
    setup
    get_disk_ids
    parse_args "$@"
}

main "$@"