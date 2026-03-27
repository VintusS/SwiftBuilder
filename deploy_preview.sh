#!/bin/bash
set -euo pipefail

# deploy_preview.sh — Build, install, and launch PreviewRunner on iOS Simulator
# Usage: ./deploy_preview.sh [simulator_udid]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
BUNDLE_ID="com.vintuss.PreviewRunner"
OUTPUT_DIR="/tmp/AlphaPreviewRunnerBuild"
EXPECTED_APP="$OUTPUT_DIR/PreviewRunner.app"
DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"

if [ ! -d "$DEVELOPER_DIR" ]; then
    DEVELOPER_DIR="$(xcode-select -p 2>/dev/null || echo /Applications/Xcode.app/Contents/Developer)"
fi
export DEVELOPER_DIR

XCODEBUILD="$DEVELOPER_DIR/usr/bin/xcodebuild"
SIMCTL="$DEVELOPER_DIR/usr/bin/simctl"

if [ ! -f "$XCODEBUILD" ]; then
    XCODEBUILD="$(xcrun --find xcodebuild 2>/dev/null || echo /usr/bin/xcodebuild)"
fi
if [ ! -f "$SIMCTL" ]; then
    SIMCTL="$(xcrun --find simctl 2>/dev/null || echo /usr/bin/xcrun simctl)"
fi

echo "[deploy] Project: $PROJECT_DIR"
echo "[deploy] Output:  $OUTPUT_DIR"

# Find simulator UDID
if [ -n "${1:-}" ]; then
    SIM_UDID="$1"
else
    SIM_UDID=$("$SIMCTL" list devices booted -j 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    if 'iOS' in runtime:
        for d in devices:
            if 'iPhone' in d.get('name','') and d.get('state') == 'Booted':
                print(d['udid']); sys.exit(0)
for runtime, devices in data.get('devices', {}).items():
    for d in devices:
        if 'iPhone' in d.get('name','') and d.get('state') == 'Booted':
            print(d['udid']); sys.exit(0)
" 2>/dev/null || true)

    if [ -z "$SIM_UDID" ]; then
        echo "[deploy] No booted simulator found, booting first available iPhone..."
        SIM_UDID=$("$SIMCTL" list devices available -j 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    if 'iOS' in runtime:
        for d in devices:
            if 'iPhone' in d.get('name',''):
                print(d['udid']); sys.exit(0)
" 2>/dev/null || true)
        if [ -z "$SIM_UDID" ]; then
            echo "[deploy] ERROR: No iPhone simulator found"
            exit 1
        fi
        open -a Simulator
        "$SIMCTL" boot "$SIM_UDID" 2>/dev/null || true
        sleep 3
    fi
fi

echo "[deploy] Simulator: $SIM_UDID"

# Mirror latest SavedProjects JSON to ~/Documents for PreviewRunner host access
SAVED_DIR="$PROJECT_DIR/SavedProjects"
DOCS_DIR="$HOME/Documents/SwiftUIBuilderProjects"
if [ -d "$SAVED_DIR" ]; then
    mkdir -p "$DOCS_DIR"
    LATEST_JSON=$(ls -t "$SAVED_DIR"/*.json 2>/dev/null | head -1 || true)
    if [ -n "$LATEST_JSON" ]; then
        cp "$LATEST_JSON" "$DOCS_DIR/"
        BASENAME=$(basename "$LATEST_JSON")
        echo "[deploy] Mirrored $BASENAME to ~/Documents/SwiftUIBuilderProjects/"
    fi
fi

# Clean and build PreviewRunner from scratch
echo "[deploy] Cleaning build directory..."
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "[deploy] Building PreviewRunner (clean build)..."
"$XCODEBUILD" \
    -project "$PROJECT_DIR/alpha.xcodeproj" \
    -target PreviewRunner \
    -sdk iphonesimulator \
    -configuration Debug \
    "CONFIGURATION_BUILD_DIR=$OUTPUT_DIR" \
    "OBJROOT=$OUTPUT_DIR/Intermediates" \
    "SYMROOT=$OUTPUT_DIR/Products" \
    clean build 2>&1 || true

# RegisterExecutionPolicyException can cause non-zero exit even on success
if [ ! -d "$EXPECTED_APP" ]; then
    echo "[deploy] ERROR: Build failed — $EXPECTED_APP not found"
    exit 1
fi

SIZE=$(wc -c < "$EXPECTED_APP/PreviewRunner" | tr -d ' ')
echo "[deploy] Built: $EXPECTED_APP ($SIZE bytes)"

# Verify binary has navigation code
NAV_COUNT=$(strings "$EXPECTED_APP/PreviewRunner" | grep -c "nav target" || true)
OLD_COUNT=$(strings "$EXPECTED_APP/PreviewRunner" | grep -c "Button tapped successfully" || true)
echo "[deploy] Binary check: nav_target_refs=$NAV_COUNT old_alert_refs=$OLD_COUNT"

if [ "$OLD_COUNT" -gt 0 ]; then
    echo "[deploy] WARNING: Binary still contains old alert string!"
fi

# Uninstall, install, launch
echo "[deploy] Installing..."
"$SIMCTL" terminate "$SIM_UDID" "$BUNDLE_ID" 2>/dev/null || true
"$SIMCTL" uninstall "$SIM_UDID" "$BUNDLE_ID" 2>/dev/null || true
"$SIMCTL" install "$SIM_UDID" "$EXPECTED_APP"

echo "[deploy] Launching with ALPHA_PROJECT_DIR..."
SIMCTL_CHILD_ALPHA_PROJECT_DIR="$SAVED_DIR" "$SIMCTL" launch "$SIM_UDID" "$BUNDLE_ID"

echo "[deploy] Done! PreviewRunner is running on simulator."
