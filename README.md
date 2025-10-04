# diskguard(1)

```bash
 ·▄▄▄▄  ▪  .▄▄ · ▄ •▄  ▄▄ • ▄• ▄▌ ▄▄▄· ▄▄▄  ·▄▄▄▄  
 ██▪ ██ ██ ▐█ ▀. █▌▄▌▪▐█ ▀ ▪█▪██▌▐█ ▀█ ▀▄ █·██▪ ██ 
 ▐█· ▐█▌▐█·▄▀▀▀█▄▐▀▀▄·▄█ ▀█▄█▌▐█▌▄█▀▀█ ▐▀▀▄ ▐█· ▐█▌
 ██. ██ ▐█▌▐█▄▪▐█▐█.█▌▐█▄▪▐█▐█▄█▌▐█ ▪▐▌▐█•█▌██. ██ 
 ▀▀▀▀▀• ▀▀▀ ▀▀▀▀ ·▀  ▀·▀▀▀▀  ▀▀▀  ▀  ▀ .▀  ▀▀▀▀▀▀•
```

`diskguard` is a software based, USB disk write blocker for MacOS. It works by detecting when an external USB disk is mounted and then remounts it in readonly mode.

> **IMPORTANT:** This method may not be forensically sound. If chain of custody is important use a hardware based write-blocker instead of this tool. 

## Install

1. Clone this repository
2. Run the script (requires root) `sudo ./diskguard.sh`
3. Follow the interactive prompts

## Usage

`diskguard` provides multiple modes of functioning. When run, you can interactively select the mode most suitable for your purposes.

```
Usage: ./diskguard.sh <(optional) disk identifier> [-h] [-v] [-a] [-b] [-w] [-l] [-t]
  -h, --help    Display this help message.
  -v, --version Display version information.
  -a, --all     Set readonly all USB volumes.
  -b, --block   Write-block a single USB volume. Disk identifier argument required.
  -w, --watch   Watch for newly mounted volumes.
  -l, --list    Display all USB volumes. Default.
  -t, --test    Test a volume is readonly. Disk identifier argument required.
```

### Examples

```bash
# Write-block a single drive
$ ./diskguard.sh disk2s2 -b
```

```bash
# Watch for newly attached drives
$ ./diskguard.sh -w
```


