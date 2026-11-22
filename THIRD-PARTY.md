# Third-party files

Everything not listed here is original to this repository and under the MIT license in `LICENSE` (copyright "fp6-omarchy contributors").

## tools/mkbootimg.py
- Origin: AOSP `platform/system/tools/mkbootimg`, as shipped in android-platform-tools 34.0.5. Unmodified; sha256 in `tools/SOURCES.md`.
- License: Apache-2.0. The original header ("Copyright 2015, The Android Open Source Project", Apache License 2.0 notice) is kept in the file. License text: http://www.apache.org/licenses/LICENSE-2.0

## pmaports/device-fairphone-fp6/ (postmarketOS pmaports)
- Origin: https://gitlab.postmarketos.org/postmarketOS/pmaports, path `device/testing/device-fairphone-fp6/`, at commit 6c3e3bcd3c6b30b9148cbe8ff88e5e8168b78972.
- Files: `deviceinfo`, `kernel-cmdline.conf`, `modules-initfs`, `sim-wait-time.conf` (byte-identical to upstream at that commit, checked with cmp) and `APKBUILD` (one change, see below).
- License, as found in the upstream repository at that commit: the repository's top-level `LICENSE` is the GNU General Public License, version 3. None of these files carries its own license header or copyright line. `APKBUILD` declares `license="MIT"`, which is the license field of the package it describes, kept as in upstream.
- Change: `APKBUILD` line 2 (`maintainer=`) had the upstream maintainer's name and e-mail address replaced by a placeholder. Everything else is unchanged. Restore the original line from upstream if you redistribute this file.
- The `# Reference:` links in `APKBUILD` and `deviceinfo` point to postmarketos.org/devicepkg and /deviceinfo as written upstream. Today these URLs redirect (HTTP 301) to another host; the links are kept unchanged on purpose.
- `LOCAL-CHANGES.md` and `pmaports/linux-fp6/README.md` are ours (MIT).

## kernel/config/fp6_defconfig.base
- A kernel configuration snapshot (`fp6_defconfig`) from the `milos-mainline/linux` tree pinned in `kernel/UPSTREAM.md`. The Linux kernel is GPL-2.0 (with the syscall note); this config file is a list of option names and values, kept as a build input.

## Not in this repository
- busybox (GPL-2.0): not vendored. `ramboot/fetch-busybox.sh` downloads a pinned Ubuntu package at build time and checks its sha256.
