#!/bin/bash
# ADB Port Forwarding Setup Script
# Run this script when testing on USB-connected Android device

echo "🔌 Setting up ADB port forwarding..."

# Add Android SDK platform-tools to PATH
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"

# Check if device is connected
if ! adb devices | grep -q "device$"; then
    echo "❌ No Android device found!"
    echo "Make sure your device is:"
    echo "  1. Connected via USB"
    echo "  2. USB debugging is enabled"
    echo "  3. You've authorized this computer on the device"
    exit 1
fi

echo "✅ Android device found"

# Set up port forwarding
adb reverse tcp:3000 tcp:3000

if [ $? -eq 0 ]; then
    echo "✅ Port forwarding set up successfully"
    echo "📱 Device port 3000 → 💻 Computer port 3000"
    echo ""
    echo "Now your Android device can access the backend at:"
    echo "   http://localhost:3000"
    echo ""
    echo "Run your Flutter app now: flutter run"
else
    echo "❌ Failed to set up port forwarding"
    exit 1
fi




