# Pixel Heart WLED

This repository is the Pixel Heart firmware fork of [WLED](https://github.com/wled/WLED). It stays based on upstream WLED releases while adding the hardware profiles and visual behavior used by Pixel Heart devices.

For WLED features, setup, documentation, supported hardware, and licensing details, see the preserved [upstream README](README.upstream.md) and the [WLED documentation](https://kno.wled.ge/).

## Fork differences

- The Pixel Heart 2D matrix effect, including sound-reactive behavior in supported builds.
- Pixel Heart hardware profiles for dig2go, ESP32-C3 MagWLED, and ESP32-S3 MagWLED Pro devices.
- Pixel Heart release binaries with the appropriate defaults and usermods for those profiles.

## Versioning

Pixel Heart releases use this format:

```text
<upstream-version>-ph<revision>
```

The Pixel Heart revision is zero-padded to four digits. For example, the first Pixel Heart release based on upstream WLED `16.0.1` is `16.0.1-ph0001`. A second Pixel Heart release that remains on the same upstream version is `16.0.1-ph0002`. The revision resets to `0001` whenever the upstream version changes.

The same version is used consistently across release metadata:

- Firmware/package version: `16.0.1-ph0001`
- Git tag: `v16.0.1-ph0001`
- GitHub release title: `Pixel Heart v16.0.1-ph0001`

The `-ph<revision>` suffix is a valid [Semantic Versioning](https://semver.org/) prerelease identifier. Its fixed width preserves revision ordering in existing WLED+ app versions, and the format is also accepted by the WLED integration used by Home Assistant.

Home Assistant follows the official WLED release channel and treats an upstream stable version as newer than a Pixel Heart prerelease with the same base version. Do not install that offered upstream update unless you intend to replace the Pixel Heart firmware.

Releases that predate this convention retain their original binary filenames and embedded firmware versions. Their Git tags and GitHub release names use the new convention so the upstream base and historical Pixel Heart revision are unambiguous.

Bare upstream tags, when mirrored in this repository, keep their original upstream names and are not Pixel Heart releases.
