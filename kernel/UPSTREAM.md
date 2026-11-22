# Kernel upstream

- tree: https://github.com/milos-mainline/linux
- branch: milos-7.3.y
- pinned commit: 939a2ad25846b29eb6c33a69aa47f41ce1b2f4fc
- commit time: 2026-10-23T14:43:27Z (SOURCE_DATE_EPOCH=1792766607)
- tip subject: arm64: dts: qcom: milos-fairphone-fp6: Enable Iris
- defconfig: `fp6_defconfig`, snapshot in `config/fp6_defconfig.base`
- toolchain used for the earlier unpinned reference build: clang 21.1.8, aarch64 binutils 2.46

## Existence check for the pin
Run: `git ls-remote https://github.com/milos-mainline/linux refs/heads/milos-7.3.y`
Expected output: `939a2ad25846b29eb6c33a69aa47f41ce1b2f4fc	refs/heads/milos-7.3.y` (rc0). Note `ls-remote` takes ref names, not commit shas: giving it a sha returns nothing and proves nothing.
If the branch has moved on (different sha), the pin may still exist. Check it with: `git init x && cd x && git fetch --depth 1 https://github.com/milos-mainline/linux 939a2ad25846b29eb6c33a69aa47f41ce1b2f4fc` (rc0 = commit exists; non-zero = not fetchable). A proxy status line such as `HTTP/1.1 200 Connection Established` from `curl -I` is the proxy's CONNECT reply, not the origin's status.

Reference values from that earlier reference build (different, non-fixed environment; NOT a baseline for this repo):
- dtb `milos-fairphone-fp6.dtb` sha256 a3c593b466a9bf7d321c3e98c3726116b66e4a2ac367ee515ee8a5b49d64212e, 85414 bytes. A dtb does not embed build time, so a reproducible build should reproduce it. If it does, record that in `results/iterations/001/change.md`.
- Image.gz a303a202... is NOT expected to match (the kernel embeds build time, user and host).

Baseline for this repo = iteration 001: two builds with identical sha256, then one independent build by a human, all three equal.
The pin moves only on a human ruling.
