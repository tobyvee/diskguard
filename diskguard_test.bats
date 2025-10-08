#!/usr/bin/env bats

# Setup and teardown
setup() {
  export SCRIPT_DIR
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
  export DISKGUARD="$SCRIPT_DIR/diskguard.sh"
  export TEST_TMP_DIR="/tmp/diskguard_test"
  mkdir -p "$TEST_TMP_DIR"
}

teardown() {
  rm -rf "$TEST_TMP_DIR"
}

# Test help option
@test "displays help message" {
  run "$DISKGUARD" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "--help" ]]
  [[ "$output" =~ "--version" ]]
}

@test "displays help with -h flag" {
  run "$DISKGUARD" -h
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}

# Test version option
@test "displays version information" {
  run "$DISKGUARD" --version
  [ "$status" -eq 0 ]
  [[ "$output" =~ 1.0.0 ]]
}

@test "displays version with -v flag" {
  run "$DISKGUARD" -v
  [ "$status" -eq 0 ]
  [[ "$output" =~ 1.0.0 ]]
}

# Test Darwin check (mock uname for testing)
@test "fails on non-Darwin systems" {
  # Create a mock uname that returns Linux
  # shellcheck disable=2028
  echo '#!/bin/bash\necho "Linux"' > "$TEST_TMP_DIR/uname"
  chmod +x "$TEST_TMP_DIR/uname"
    
  # Temporarily modify PATH to use our mock uname
  PATH="$TEST_TMP_DIR:$PATH" run "$DISKGUARD" -l
  [ "$status" -eq 1 ]
  [[ "$output" =~ "only supported on macOS" ]]
}

# Test utility functions by sourcing them directly
@test "fatal function exits with error" {
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/utils/errors/fatal.sh"
  run fatal "Test error message"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Test error message" ]]
}

@test "timestamp function returns numeric value" {
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/utils/datetime/timestamp.sh"
  run timestamp
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+$ ]]
}

@test "color functions work correctly" {
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/utils/strings/colors.sh"
  run red "test"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "test" ]]
}

# Test disk parsing functions (mock diskutil output)
@test "get_disk_volume_name extracts volume name" {
  # shellcheck source=/dev/null
  source "$DISKGUARD"
    
  # Mock diskutil info output
  mock_output="Volume Name:                  TestVolume"
  result=$(get_disk_volume_name "$mock_output")
  [ "$result" = "TestVolume" ]
}

@test "get_disk_size extracts disk size" {
  # shellcheck source=/dev/null
  source "$DISKGUARD"
    
  mock_output="Disk Size:                    64.0 GB (64023257088 Bytes) (exactly 125045424 512-Byte-Units)"
  result=$(get_disk_size "$mock_output")
  [ "$result" = "64.0 GB" ]
}

@test "get_disk_fs extracts file system" {
  # shellcheck source=/dev/null
  source "$DISKGUARD"
    
  mock_output="File System Personality:      ExFAT"
  result=$(get_disk_fs "$mock_output")
  [ "$result" = "ExFAT" ]
}

@test "get_volume_mount extracts mount point" {
  # shellcheck source=/dev/null
  source "$DISKGUARD"
    
  mock_output="Mount Point:                  /Volumes/TestDisk"
  result=$(get_volume_mount "$mock_output")
  [ "$result" = "/Volumes/TestDisk" ]
}

@test "get_disk_mount extracts device node" {
  # shellcheck source=/dev/null
  source "$DISKGUARD"
    
  mock_output="Device Node:                  /dev/disk2s1"
  result=$(get_disk_mount "$mock_output")
  [ "$result" = "/dev/disk2s1" ]
}

# Test readonly status checking
@test "is_readonly returns true for readonly disk" {
  # shellcheck source=/dev/null
  source "$DISKGUARD"
    
  # Mock diskutil info to return readonly status
  # shellcheck disable=2329
  function diskutil() {
    if [[ "$1" == "info" ]]; then
      echo "Volume Read-Only:             Yes"
    fi
  }
  export -f diskutil
    
  run is_readonly "disk2s1"
  [ "$status" -eq 0 ]
}

@test "is_readonly returns false for writable disk" {
  # shellcheck source=/dev/null
  source "$DISKGUARD"
  
  # shellcheck disable=2329
  function diskutil() {
    if [[ "$1" == "info" ]]; then
      echo "Volume Read-Only:             No"
    fi
  }
  export -f diskutil
    
  run is_readonly "disk2s1"
  [ "$status" -eq 1 ]
}

# Test mount status checking
@test "is_mounted returns true for mounted disk" {
  # shellcheck source=/dev/null
  source "$DISKGUARD"
  
  # shellcheck disable=2329
  function diskutil() {
    if [[ "$1" == "info" ]]; then
      echo "Mounted:                      Yes"
    fi
  }
  export -f diskutil
    
  run is_mounted "disk2s1"
  [ "$status" -eq 0 ]
}

@test "is_mounted returns false for unmounted disk" {
  # shellcheck source=/dev/null
  source "$DISKGUARD"
    
  function diskutil() {
    if [[ "$1" == "info" ]]; then
      echo "Mounted:                      No"
    fi
  }
  export -f diskutil
    
  run is_mounted "disk2s1"
  [ "$status" -eq 1 ]
}

# Test directory and file creation functions
@test "ensure_dir creates directory if not exists" {
  # shellcheck source=/dev/null
  source "$DISKGUARD"
    
  test_dir="$TEST_TMP_DIR/test_ensure_dir"
  ensure_dir "$test_dir"
  [ -d "$test_dir" ]
}

@test "ensure_file creates file if not exists" {
  # shellcheck source=/dev/null
  source "$DISKGUARD"
    
  test_file="$TEST_TMP_DIR/test_ensure_file"
  ensure_file "$test_file"
  [ -f "$test_file" ]
}

# Test error handling for block_one function
@test "block_one fails with empty disk identifier" {
  # shellcheck source=/dev/null
  source "$DISKGUARD"
    
  run block_one ""
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Disk identifier is required" ]]
}