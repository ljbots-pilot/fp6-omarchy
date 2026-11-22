# Vendored tools

## tools/mkbootimg.py
- What: AOSP `mkbootimg` (boot image header v0-v4 builder), Python 3, unmodified.
- License: Apache-2.0 (header in the file: "Copyright 2015, The Android Open Source Project").
- Source: AOSP platform/system/tools/mkbootimg, as shipped in the android-platform-tools 34.0.5 drop (Ubuntu package mkbootimg 1:34.0.5-12build1, /usr/bin/mkbootimg).
- sha256: b682574d42fd5c5cb852e7e76996b0e460808f10f47d81fc01e7f6db1697da4e
- Why this drop: it is a single self-contained file. Newer AOSP master (sha256 37d84b3d162e0bc62e36c1f4e1c63c85ea0caa9f29be023eb2f8efe006ad948c) imports the `gki` package and does not start without it. For our header-v2 args both produce byte-identical boot.img (checked).
- Check: `sha256sum tools/mkbootimg.py` must equal the value above; tests may rely on it.
