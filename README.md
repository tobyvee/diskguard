# diskguard

```bash
·▄▄▄▄  ▪  .▄▄ · ▄ •▄  ▄▄ • ▄• ▄▌ ▄▄▄· ▄▄▄  ·▄▄▄▄  
 ██▪ ██ ██ ▐█ ▀. █▌▄▌▪▐█ ▀ ▪█▪██▌▐█ ▀█ ▀▄ █·██▪ ██ 
 ▐█· ▐█▌▐█·▄▀▀▀█▄▐▀▀▄·▄█ ▀█▄█▌▐█▌▄█▀▀█ ▐▀▀▄ ▐█· ▐█▌
 ██. ██ ▐█▌▐█▄▪▐█▐█.█▌▐█▄▪▐█▐█▄█▌▐█ ▪▐▌▐█•█▌██. ██ 
 ▀▀▀▀▀• ▀▀▀ ▀▀▀▀ ·▀  ▀·▀▀▀▀  ▀▀▀  ▀  ▀ .▀  ▀▀▀▀▀▀•
```

`diskguard` is a software based, USB disk write blocker for MacOS. It works by detecting when an external USB disk is mounted and then remounts it in readonly mode.

## Install

1. Clone this repository
2. Run the script (requires root) `sudo ./diskguard.sh`
3. Follow the interactive prompts

## Usage

`diskguard` provides multiple modes of functioning. When run, you can interactively select the mode most suitable for your purposes.

### 1. Write block a specific volume

In this mode, you must enter a specific disk identifier, eg. `disk2s1`.

### 2. Write block all external USB volumes

This mode will detect and remount all external USB disks in readonly mode.

### 3. Monitor for external USB volumes

This mode will watch for new volumes to be mounted and then automatically remount them in readonly mode.

### 4. Test write protection

This mode allows you to test a specific disk to see if it's mounted as readonly. You must supply a disk identifier, eg. `disk2s2`

### 5. Refresh list

This option refreshes the list of USB disks currently mounted on the system. 


