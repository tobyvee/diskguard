#!/usr/bin/env bash

# ·▄▄▄▄  ▪  .▄▄ · ▄ •▄  ▄▄ • ▄• ▄▌ ▄▄▄· ▄▄▄  ·▄▄▄▄  
# ██▪ ██ ██ ▐█ ▀. █▌▄▌▪▐█ ▀ ▪█▪██▌▐█ ▀█ ▀▄ █·██▪ ██ 
# ▐█· ▐█▌▐█·▄▀▀▀█▄▐▀▀▄·▄█ ▀█▄█▌▐█▌▄█▀▀█ ▐▀▀▄ ▐█· ▐█▌
# ██. ██ ▐█▌▐█▄▪▐█▐█.█▌▐█▄▪▐█▐█▄█▌▐█ ▪▐▌▐█•█▌██. ██ 
# ▀▀▀▀▀• ▀▀▀ ▀▀▀▀ ·▀  ▀·▀▀▀▀  ▀▀▀  ▀  ▀ .▀  ▀▀▀▀▀▀•

# `diskguard` is a software based, USB disk write blocker for MacOS. 
# It works by detecting when an external USB disk is mounted and then remounts it in readonly mode.

# **IMPORTANT:** This method may not be forensically sound. 
# If chain of custody is important use a hardware based write-blocker instead of this tool.

# Use at your own risk. 
# The author is not responsible for any loss of data, financial loss or damage to your system.

set -euo pipefail

# shellcheck source=/dev/null
source 'utils/errors/fatal.sh'
# shellcheck source=/dev/null
source 'utils/strings/colors.sh'

VERSION='1.0.0'
DISK_ID=''
declare -a DISKS_ARR=()

LOG_PATH='/var/log/diskguard/'
LOG_FILE='diskguard.log'

TMP_PATH='/tmp/diskguard/'
TMP_FILE_PREV='diskguard_watch_prev'
TMP_FILE_NEXT='diskguard_watch_next'

banner() {
  echo "·▄▄▄▄  ▪  .▄▄ · ▄ •▄  ▄▄ • ▄• ▄▌ ▄▄▄· ▄▄▄  ·▄▄▄▄  ";
  echo "██▪ ██ ██ ▐█ ▀. █▌▄▌▪▐█ ▀ ▪█▪██▌▐█ ▀█ ▀▄ █·██▪ ██ ";
  echo "▐█· ▐█▌▐█·▄▀▀▀█▄▐▀▀▄·▄█ ▀█▄█▌▐█▌▄█▀▀█ ▐▀▀▄ ▐█· ▐█▌";
  echo "██. ██ ▐█▌▐█▄▪▐█▐█.█▌▐█▄▪▐█▐█▄█▌▐█ ▪▐▌▐█•█▌██. ██ ";
  echo "▀▀▀▀▀• ▀▀▀ ▀▀▀▀ ·▀  ▀·▀▀▀▀  ▀▀▀  ▀  ▀ .▀  ▀▀▀▀▀▀• ";
}

usage() {
  echo "Usage: $0 <disk identifier (optional)> [-h] [-v] [-a] [-w] [-l] [-t]"
  echo "  -h, --help    Display this help message."
  echo "  -v, --version Display version information."
  echo "  -a, --all     Set readonly all USB volumes."
  echo "  -b, --block   Write-block a single USB volume. Disk identifier argument required."
  echo "  -w, --watch   Watch for newly mounted volumes."
  echo "  -l, --list    Display all USB volumes. Default."
  echo "  -t, --test    Test a volume is readonly. Disk identifier argument required."
  exit 0
}

version() {
  echo "$VERSION"
  exit 0
}

check_permissions() {
  # Check if running as root
  if [ "$EUID" -ne 0 ]; then 
    fatal "Error: This script must be run with sudo"
  fi
}

check_darwin() {
  if [ "$(uname)" != "Darwin" ]; then
    fatal "Error: This script is only supported on macOS"
  fi
}

ensure_log_path() {
  ensure_dir "$LOG_PATH"
}

ensure_log_file() {
  ensure_file "$LOG_PATH$LOG_FILE"
}

ensure_tmp_path() {
  ensure_dir "$TMP_PATH"
}

ensure_tmp_files() {
  ensure_file "$TMP_PATH$TMP_FILE_PREV"
  ensure_file "$TMP_PATH$TMP_FILE_NEXT"
}

cleanup_tmp_files() {
  rm -f "$TMP_PATH$TMP_FILE_PREV"
  rm -f "$TMP_PATH$TMP_FILE_NEXT"
}

ensure_paths() {
  ensure_log_path
  ensure_log_file
  ensure_tmp_path
  ensure_tmp_files
}

setup() {
  check_permissions
  check_darwin
  ensure_paths
}

cleanup() {
  trap cleanup_tmp_files EXIT
}

ensure_dir() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
  fi
}

ensure_file() {
  if [ ! -f "$1" ]; then
    touch "$1"
  fi
}

# TODO: Add logging
append_log() {
  local LOG="$1"
  ensure_log_path
  ensure_log_file
  echo "$LOG" >> "$LOG_PATH$LOG_FILE"
}

info() {
  echo -e "Info: $1"
}

# TODO: Test implementation
block_all() {
  echo -e "Not implemented."
  exit 1
  # if [ ${#DISKS_ARR[@]} -gt 0 ]; then
  #   for i in "${DISKS_ARR[@]}"; do
  #     block_one "$i"
  #   done
  # else
  #   fatal "No external USB volumes found"
  # fi
}

block_one() {
  local DISK="$1"
  
  if [ -z "$DISK" ]; then
    fatal "Error: Disk identifier is required"
  fi
  if ! is_mounted "$DISK"; then
    fatal "Error: $DISK is not mounted"
  fi
  # TODO: Check disk / volume mount error
  if is_readonly "$DISK"; then 
    info "$DISK is already readonly"
  fi
  
  MOUNT=$(get_disk_mount "$DISK")
  unmount_disk "$MOUNT"
  mount_disk_readonly "$MOUNT"

  if is_readonly "$DISK"; then
    echo -e "Success: $DISK is readonly\n\n"
  fi
}

# TODO: Implementation
watch() {
  echo -e "Not implemented."
  exit 0
}

# TODO: Implementation. Make retrieving info faster by only calling diskutil once per disk.
get_disk_info() {
  local DISK_INFO
  DISK_INFO=$(diskutil info "$1" 2>/dev/null);
  echo "Not yet implemented."
  exit 1
}

get_volume_mount() {
  echo -e "$(diskutil info "$1" 2>/dev/null | grep "Mount Point:" | cut -d: -f2 | xargs)"
}

get_disk_mount() {
  echo -e "$(diskutil info "$1" 2>/dev/null | grep "Device Node:" | cut -d: -f2 | xargs)"
}

get_disk_size() {
  echo -e "$(diskutil info "$1" 2>/dev/null | grep "Disk Size:" | cut -d: -f2 | grep -oE "[0-9]+\.[0-9]+ [A-Z]{2}" | head -1)" || echo -e "Unknown"
}

get_disk_fs() {
  echo -e "$(diskutil info "$1" 2>/dev/null | grep "File System Personality:" | cut -d: -f2 | xargs)" || echo -e "Unknown"
}

get_disk_volume_name() {
  echo -e "$(diskutil info "$1" 2>/dev/null | grep "Volume Name:" | cut -d: -f2 | xargs)" || echo -e "Untitled"
}

get_disk_write_status() {
  if is_readonly "$1"; then
    echo -e "${GREEN}[READ-ONLY]${RESET}"
  else 
    echo -e "${YELLOW}[WRITEABLE]${RESET}"
  fi
}

is_mounted() {
  local MOUNTED 
  MOUNTED="$(diskutil info "$1" 2>/dev/null | grep "Mounted:" | cut -d: -f2 | xargs)"
  if [ "$MOUNTED" = "No" ]; then
    return 1
  fi 
  return 0
}

is_writable() {
  if [ "$(diskutil info "$1" | grep "Volume Read-Only:" | cut -d: -f2 | xargs)" = "Yes" ]; then
    return 1
  fi
  return 0
}

unmount_disk() {
  if ! diskutil unmount "$1"; then 
    fatal "Error: Failed to unmount $1"
  fi 
}

mount_disk_readonly() {
  if ! diskutil mount readOnly "$1"; then
    fatal "Error: Failed to mount $1 in readonly mode"
  fi
}

is_readonly() {
  if [ "$(diskutil info "$1" | grep "Volume Read-Only:" | cut -d: -f2 | xargs)" = "No" ]; then
    return 1
  fi
  return 0
}

get_disk_ids() {
  while IFS= read -r LINE; do
    DISKS_ARR+=("$(echo "$LINE" | awk '{print $NF}')")
  done < <(diskutil list external physical | grep -E "^\s+[0-9]:")
}

list() {
  if [ ${#DISKS_ARR[@]} -gt 0 ]; then

    printf "%s\t\t%s\t\t%s\t\t%s\t\t%s\t\t%s\n" "STATUS" "ID" "NAME" "SIZE" "FILE SYSTEM" "MOUNT"

    for i in "${DISKS_ARR[@]}"; do 

      ID="$i"
      STATUS=$(get_disk_write_status "$ID")
      NAME=$(get_disk_volume_name "$ID")
      SIZE=$(get_disk_size "$ID")
      FS=$(get_disk_fs "$ID") || "Unknown"
      MOUNT=$(get_volume_mount "$ID") || "Not Mounted"

      if [ "$(echo "$ID" | grep -E "^disk[0-9]+s[0-9]+")" ]; then
        printf "%s\t%s\t\t%s\t%s\t\t%s\t\t\t%s\n" "$STATUS" "$ID" "$NAME" "$SIZE" "$FS" "$MOUNT"
      fi

    done

  else
    fatal "No external USB volumes found"
  fi
  exit 0
}

test() {
  local DISK="$1"
  if [ -z "$DISK" ]; then
    fatal "Error: Disk identifier is required"
  fi
  if is_mounted "$DISK"; then
    if is_readonly "$DISK"; then
      echo -e "${GREEN}Disk $DISK is readonly.${RESET}"
    else 
      echo -e "${RED}Disk $DISK is writable.${RESET}"
    fi
  else
    fatal "Error: Disk $DISK is not mounted"
  fi
  exit 0
}

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

function main() {
    setup
    get_disk_ids
    parse_args "$@"
}

main "$@"