# mac-keyboard-remap

For Turkish keyboard habits carried over from Windows: **right Cmd + 7 = `{`** on external keyboards.

With the Turkish Q - PC layout on macOS, characters like `{ [ ] } \ | @` are typed with **Option**, which sits far from the space bar. This tool makes the **Cmd** key to the right of the space bar (where AltGr is on Windows) act as **Option** on the listed external keyboards.

- Left Cmd is unchanged, so shortcuts like Cmd+C / Cmd+V work with left Cmd.
- Option keeps working as before.
- The MacBook's built-in keyboard is not affected; only the listed keyboards change.

## Characters with Turkish Q - PC

| Keys | Output |
|---|---|
| right Cmd + 7 / 8 / 9 / 0 | `{  [  ]  }` |
| right Cmd + - | `\` |
| right Cmd + = | `\|` |
| right Cmd + Q | `@` |
| right Cmd + 1 | `>` |

## Supported keyboards

| Keyboard | VendorID | ProductID |
|---|---|---|
| NuPhy Air75 V2 (Bluetooth) | `0x19F5` | `0x3246` |
| Logitech MX Keys S (Bluetooth) | `0x046D` | `0xB378` |

## Installation

Building requires the Xcode Command Line Tools (`swiftc`). If you don't have them, run `xcode-select --install` first.

```sh
./install.sh
```

The script compiles the program into `~/Library/Application Support/KeyboardRemap/` and sets it up to start every time you log in. Running it again is safe; it updates the existing installation.

## Adding a keyboard

1. Connect the keyboard and find its IDs:
   ```sh
   hidutil list | grep -i <keyboard name>
   ```
   The first two columns are the VendorID and ProductID.
2. Add a line to the `keyboards` list in `keyboard-remap.swift`:
   ```swift
   Keyboard(name: "Keyboard name", vendorID: 0x1234, productID: 0x5678),
   ```
3. Run `./install.sh` again.

## How it works

1. **Key remapping:** macOS's built-in `hidutil` tool makes a keyboard report right Cmd (HID `0xE7`) as right Option (`0xE6`). This happens at the lowest level, before apps see the key, so it works everywhere. It is not persistent, though: it is lost when the keyboard reconnects or the Mac restarts.
2. **Watcher:** when a listed keyboard connects, the program gets notified by macOS (IOKit) and reapplies the mapping right away. It doesn't poll; it waits idle until notified.
3. **Auto-start:** `~/Library/LaunchAgents/local.keyboard-remap.plist` starts the watcher at login and restarts it if it exits.

## Logs

When each keyboard connected and whether the mapping was applied:

```sh
cat ~/Library/Logs/keyboard-remap.log
```

## Uninstall

```sh
./uninstall.sh
```

Keys go back to normal the next time the keyboard reconnects or the Mac restarts.
