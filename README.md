# fp6-omarchy

Work in progress. Notes and build recipe for a RAM boot of a mainline Linux kernel on a Fairphone Gen. 6 (SM7635 "Milos"), meant as input for the Omarchy Mobile project.

## Status
- RAM boot only: a kernel config, a minimal busybox ramdisk and a `boot.img` recipe built from pinned inputs. Nothing in this repository flashes, erases or unlocks anything, and nothing writes to the phone's internal storage. The recipes target RAM boot; SD card is the intended route for anything persistent.
- No device tree files and no kernel patches are included yet (`kernel/dts/` and `kernel/patches/` are empty). The kernel source is pinned in `kernel/UPSTREAM.md`.
- No boot logs and no build artifacts are included. `results/MANIFEST.sha256` has no rows yet.
- Two builds of the same commit are intended to give the same sha256 for every artifact. This has not been demonstrated yet, so do not read it as a claim.
- No UFS write access: any device descriptor derived from this work should leave `UFS_RW` empty (read-only) and document SD / RAM boot.

## Rules for the files in this repository
- No keys, credentials, personal data, host names, real-network IP addresses or user names. The one exception is the private USB-gadget link address in `ramboot/init/init.sh` (a fixed point-to-point address with no host identity).
- No partition-write, partition-erase, bootloader-unlock or raw-disk-write commands, not even as comments. `tests/forbid-scan.sh` checks this.
- No firmware blobs and no device captures (IMEI, serial, MAC, calibration data).
- A boot result only counts when a person adds a boot log under `results/iterations/NNN/`. Until then the claim is "builds, hashes and tests pass", nothing more.

## Layout
- `kernel/`: pinned upstream, config snapshot, `build.sh`.
- `ramboot/`: init script, ramdisk and `boot.img` scripts.
- `pmaports/`: reference copy of the postmarketOS device package files (see `THIRD-PARTY.md`).
- `tools/`: vendored `mkbootimg.py` (see `tools/SOURCES.md`).
- `tests/`: lint and scan scripts. `plan/accept/`: acceptance checks.
- `image/`: notes only; there is no SD image recipe yet.

## Reading a build result
`results/iterations/NNN/` is meant to hold `change.md` (one variable), `build.log` (tail), `manifest.sha256`, and `expected-boot-markers.txt` (copied from `results/expected-boot-markers.txt`).
`results/MANIFEST.sha256` has one row per artifact: `sha256  size  name`.

## Build inputs
`kernel/build.sh` fixes the kernel build timestamp (commit time of the pinned commit), user and host (`builder`), build version (1) and `SOURCE_DATE_EPOCH`.
`ramboot/mkramdisk.sh` sorts names, clamps mtimes to `SOURCE_DATE_EPOCH`, uses `cpio --reproducible` and `gzip -n`.

## License
MIT for our own files (`LICENSE`). Copied third-party files keep their original licenses: see `THIRD-PARTY.md`.
