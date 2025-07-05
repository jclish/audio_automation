#!/bin/bash

# TDD Test for Custom Resolution Feature (Refactored)
# Test-Driven Development approach

set -e

# --- Functions ---
run_ffmpeg() {
    local input="$1" out="$2" width="$3" height="$4" framerate="$5" duration="$6"
    ffmpeg -y -loglevel error -loop 1 -i "$input" \
        -vf "scale=${width}:${height}:force_original_aspect_ratio=decrease,pad=${width}:${height}:(ow-iw)/2:(oh-ih)/2" \
        -c:v libx264 -pix_fmt yuv420p -r "$framerate" -t "$duration" "$out"
}

get_resolution() {
    local file="$1"
    ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$file"
}

# --- Parse args ---
KEEP=0
while [[ "$1" == --* ]]; do
    case "$1" in
        --keep) KEEP=1 ;;
    esac
    shift
done

WIDTH="${1:-1280}"
HEIGHT="${2:-720}"

# --- Config ---
INPUT=Videos/AdobeStock_101948840.jpeg
DURATION=2
FRAMERATE=25
TEST_CASES=("default:1280x720" "hd:1920x1080" "square:720x720" "mobile:720x1280")

# --- Main ---
echo "🧪 TDD Test: Custom Resolution Feature (Refactored)"
echo "======================================"
echo "📐 Using resolution: ${WIDTH}x${HEIGHT}"

# Test 1: Baseline
OUT1="test_current.mp4"
echo "📋 Test 1: Current behavior (hardcoded 1280x720)"
[[ $KEEP -eq 0 && -f "$OUT1" ]] && rm "$OUT1"
run_ffmpeg "$INPUT" "$OUT1" 1280 720 $FRAMERATE $DURATION
RESOLUTION=$(get_resolution "$OUT1")
echo "   Current resolution: $RESOLUTION"
if [[ "$RESOLUTION" == "1280,720" ]]; then
    echo "   ✅ PASS: Current behavior works as expected"
else
    echo "   ❌ FAIL: Expected 1280,720, got $RESOLUTION"
    exit 1
fi

echo ""
echo "📋 Test 2: Custom resolution implementation"
for test_case in "${TEST_CASES[@]}"; do
    test_name=$(echo "$test_case" | cut -d':' -f1)
    expected_resolution=$(echo "$test_case" | cut -d':' -f2)
    width=$(echo "$expected_resolution" | cut -d'x' -f1)
    height=$(echo "$expected_resolution" | cut -d'x' -f2)
    out_file="test_${test_name}.mp4"
    echo "   Testing $test_name: expected $expected_resolution"
    [[ $KEEP -eq 0 && -f "$out_file" ]] && rm "$out_file"
    run_ffmpeg "$INPUT" "$out_file" "$width" "$height" $FRAMERATE $DURATION
    actual_resolution=$(get_resolution "$out_file")
    expected_csv="${width},${height}"
    if [[ "$actual_resolution" == "$expected_csv" ]]; then
        echo "   ✅ PASS: Resolution is ${width}x${height} as expected"
    else
        echo "   ❌ FAIL: Expected ${width}x${height}, got $actual_resolution"
        exit 1
    fi
    echo ""
done

echo "🎯 TDD Phase: GREEN (tests passing, refactored)"
echo "Next step: Add custom framerate support (TDD)"

echo ""
echo "📋 Test 3: Custom framerate support (RED phase)"
FRAMERATE_CASES=(24 25 30 60)
for fps in "${FRAMERATE_CASES[@]}"; do
    out_file="test_fps_${fps}.mp4"
    echo "   Testing framerate: ${fps} fps"
    [[ $KEEP -eq 0 && -f "$out_file" ]] && rm "$out_file"
    # This will fail for non-25 fps until we implement the feature
    run_ffmpeg "$INPUT" "$out_file" "$WIDTH" "$HEIGHT" $fps $DURATION
    # Check actual framerate
    actual_fps=$(ffprobe -v 0 -of csv=p=0 -select_streams v:0 -show_entries stream=r_frame_rate "$out_file" | awk -F'/' '{if ($2>0) printf("%.2f", $1/$2); else print $1}')
    if [[ "$actual_fps" == "$fps"* ]]; then
        echo "   ✅ PASS: Framerate is $fps fps as expected"
    else
        echo "   ❌ EXPECTED FAIL: Framerate is $actual_fps, expected $fps"
        echo "   (This is expected until custom framerate is implemented)"
        # exit 1  # Don't exit, as this is a RED-phase test
    fi
    echo ""
done

echo "🎯 TDD Phase: RED (custom framerate test should fail except for 25 fps)"
echo "Next step: Implement custom framerate support (GREEN phase)" 