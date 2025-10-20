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

### From source

1. Clone this repository
2. Run `chmod +x ./diskguard.sh` to make the script executable
3. Run `./diskguard.sh` (requires root permissions)

### Homebrew

You can also install diskguard via homebrew.

```
brew tap tobyvee/tap
brew install diskguard
```

## Usage

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
# List external USB drives
$ ./diskguard.sh -l

STATUS          ID              NAME            SIZE            FILE SYSTEM             MOUNT
[WRITEABLE]     disk4s1         USB0-64GB       61.5 GB         ExFAT                   /Volumes/USB0-64GB
[WRITEABLE]     disk5s1         USB-DUAL-1      30.8 GB         HFS+                    /Volumes/USB-DUAL-1
```

```bash
# Write-block a single drive
$ ./diskguard.sh disk5s1 -b

Volume USB0-64GB on disk5s1 unmounted
Volume USB0-64GB on /dev/disk5s1 mounted
Success: disk5s1 is read-only
```

```bash
# Watch for newly attached drives
$ ./diskguard.sh -w

Watching for new volumes...
New USB volume detected!
Volume USB0-64GB on disk5s1 unmounted
Volume USB0-64GB on /dev/disk5s1 mounted
Success: disk5s1 is read-only
```

## Tests

Tests are written using the [bats testing framework](https://github.com/bats-core/bats-core). To test, run the following command (requires homebrew if bats is not installed):

```bash
make test
```


