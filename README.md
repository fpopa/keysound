# KeySound

Mechanical keyboard sounds for your Mac. Because your MacBook keyboard deserves to *clack*.

KeySound sits in your menu bar and plays realistic mechanical switch sounds every time you press a key — key-down *and* key-up, just like the real thing.

**https://keysound.filippopa.com**

## Features

- **3 sound profiles** — Cherry MX Brown, Tactile, and Clicky
- **~3ms latency** — sounds arrive with your keystrokes, not after
- **Key-down & key-up** — separate sounds for authentic mechanical feel
- **Pitch variation** — randomized per keystroke, no two presses sound the same
- **Volume control** — from subtle background texture to full mechanical clatter
- **Menu bar app** — no dock icon, no windows, no distractions

## Install

Grab the `.dmg` from the [website](https://keysound.filippopa.com) or build from source:

```
make run
```

Requires macOS 13+ and Accessibility permission (so KeySound can hear your keystrokes).

## Build

```
make build    # debug build
make ship     # release build
make dmg      # package as .dmg
make clean    # clean build artifacts
```

## License

MIT
