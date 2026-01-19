# VIC-20 One RAM Tester Makefile
#
# Copyright (C) 2025 Piers Finlayson <piers@piers.rocks>
#
# Creates 4 versions of the One RAM tester:
# - PAL version testing $1000-$17FF
# - PAL version testing $1800-$1FFF
# - NTSC version testing $1000-$17FF
# - NTSC version testing $1800-$1FFF
#
# Example usage:
# XA65=/path/to/xa65 make all
#
# Dependencies:
# - `xa65` assembler must be downloaded and built
#
# To download and build xa65:
# ```bash
# git clone https://github.com/fachat/xa65
# cd xa65/xa
# make  # Produces `xa` binary in the current directory
# ```

# Path to xa65 - can be overridden with make XA65=/path/to/xa65
XA65 ?= xa

# Source file
SRC = one-ram-test.s

# Build directory
BUILD_DIR = build

# Output files
TARGETS = \
	$(BUILD_DIR)/vic-20-one-ram-tester.pal.e0 \
	$(BUILD_DIR)/vic-20-one-ram-tester.ntsc.e0

# Default target builds all versions
all: $(TARGETS)

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# PAL
$(BUILD_DIR)/vic-20-one-ram-tester.pal.e0: $(SRC) Makefile | $(BUILD_DIR)
	$(XA65) -DKERNAL_ROM=1 -DPAL_VER=1 -o $@ $(SRC)

# NTSC
$(BUILD_DIR)/vic-20-one-ram-tester.ntsc.e0: $(SRC) Makefile | $(BUILD_DIR)
	$(XA65) -DKERNAL_ROM=1 -DNTSC_VER=1 -o $@ $(SRC)

# Clean up generated files
clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean