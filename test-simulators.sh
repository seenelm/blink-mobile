#!/bin/bash

# Blink Dating App - Multi-Simulator Test Script
# This script builds and installs the app on two iPhone simulators for video chat testing

echo "Setting up simulators for blink-mobile video chat testing..."

# Build the app (uncomment if you need to build)
# echo "Building blink-mobile app..."
xcodebuild -scheme blink-mobile -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' build

# Simulator IDs
SIM1_ID="BB42909A-81A3-4EB2-9A9A-5123B214CC52"  # iPhone 16
SIM2_ID="3B884D0B-7D04-4250-B0EF-F933B4501EAB"  # iPhone 16 Pro

# Function to boot simulator safely
boot_simulator() {
    local sim_id=$1
    local sim_name=$2
    
    echo "Setting up $sim_name..."
    
    # Check if simulator is already booted
    if xcrun simctl list devices | grep -q "$sim_id.*Booted"; then
        echo "$sim_name is already booted"
    else
        echo "Booting $sim_name..."
        xcrun simctl boot "$sim_id"
    fi
}

# Boot both simulators
boot_simulator "$SIM1_ID" "iPhone 16"
boot_simulator "$SIM2_ID" "iPhone 16 Pro"

# Install app on both simulators
echo "Installing blink-mobile app on simulators..."
BUILD_PATH="/Users/noahgross/Library/Developer/Xcode/DerivedData/blink-mobile-bymuxjncnjczvcdwiiehhhxikxdf/Build/Products/Debug-iphonesimulator/blink-mobile.app"

xcrun simctl install "$SIM1_ID" "$BUILD_PATH"
xcrun simctl install "$SIM2_ID" "$BUILD_PATH"

# Launch app on both simulators
echo "Launching blink-mobile app on simulators..."
xcrun simctl launch "$SIM1_ID" com.blink.blink-mobile
xcrun simctl launch "$SIM2_ID" com.blink.blink-mobile

# Open Simulator app to show the simulators
echo "Opening Simulator app..."
open -a Simulator

echo "✅ Both simulators are now running with blink-mobile app!"
echo "📱 You should see two simulators in the Simulator app"
echo "🎥 You can now test video chat functionality between the two simulators"
