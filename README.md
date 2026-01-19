# VIC-20 One RAM Tester

A diagnostic tool for testing One ROM operating as a RAM chip on the Commodore VIC-20.

This tester is deployed as a replacement for the kernal ROM. You must install the correct PAL or NTSC version for your machine, as well as the version matching the RAM address range you want to test.

## Overview

One ROM can operate as a RAM chip for either $1000-$17FF or $1800-$1FFF. This tester performs targeted read/write tests om the entire range ($1000-$1FFF) to diagnose issues with One ROM's RAM emulation.

It does burst testing - that is writes as fast as possible to each page in the range, with incrementing values, then reads back to verify. It continues indefinitely until a failure is detected or the user resets the machine.

This has been found to be the most effective way to identify a problem with One RAM's algorithm.  However, it will not necessarily track down hardware faults.  For those, use another VIC-20 RAM tester, like [VIC-20 Dead Test](https://github.com/piersfinlayson/Vic20-dead-test).

## Build Instructions

### Install xa65

```bash
git clone https://github.com/fachat/xa65
cd xa65/xa
make  # Produces `xa` binary in the current directory
```

### Build the tester

```bash
git clone https://github.com/piersfinlayson/vic20-one-ram-test.git
cd vic20-one-ram-tester
XA65=/path/to/xa65/xa/xa make all
```

This creates 2 versions:

- `build/vic-20-one-ram-tester.pal.e0` - PAL, tests $1000-$1FFF
- `build/vic-20-one-ram-tester.ntsc.e0` - NTSC, tests $1000-$1FFF

## Usage

### Using One ROM for your Kernal

Install a One ROM 24-pin in place of your existing kernal ROM.

Modify `one-rom-config.json` to set the paths to appropriate absolute ones for your filesystem.

Then use One ROM Studio to build and flash the appropriate version - select the ROM set matching your machine (PAL/NTSC) and the RAM region you want to test.

### Manual Installation

Replace your kernal ROM with the appropriate binary for your machine.

## Test Output

The screen displays output similar to:
```
vic-20 one ram tester
----------------------
write read
 $12  $20
runs:0035
pass

v0.1.0
(c) 2026 piers.rocks
----------------------
```

Where:
- **$12** is the last page written to
- **$20** is the last page read from
- **runs** is the number of test iterations completed
- **pass** indicates the overall test result

On failure:

```
vic-20 one ram tester
----------------------
write read
 $20  $18
runs:009d
failed
addr:$1800
exp:$ab got:$18

v0.1.0
(c) 2026 piers.rocks
----------------------
```

Here:
- **addr** is the address where the failure occurred
- **exp** is the expected value
- **got** is the actual value read

The test stops on the first failure encountered.

## Acknowledgements

Based on [VIC-20 Dead Test](https://eden.mose.org.uk/gitweb/?p=dead-test.git;a=summary) by Simon Rowe, with enhancements by [Greg McCarthy](https://github.com/StormTrooper/Vic20-dead-test) and [Piers Finlayson](https://piers.rocks).

## License

This project is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for details.