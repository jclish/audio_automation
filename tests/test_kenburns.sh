#!/bin/bash

# Minimal Ken Burns Test Script
# Build incrementally to isolate issues

set -e

# --- Configurable parameters ---
DURATION="${1:-3}"
PAN_DIR="${2:-left}"
FRAMERATE=25
FRAMES=$(( DURATION * FRAMERATE ))

INPUT=Videos/AdobeStock_101948840.jpeg
SCALED="scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2"

# Pan expression
if [[ "$PAN_DIR" == "left" ]]; then
    PAN_EXPR="iw*(1-zoom)*on/$((FRAMES-1))"
    PAN_DESC="left→right"
else
    PAN_EXPR="iw*(1-zoom)*(1-on/$((FRAMES-1)))"
    PAN_DESC="right→left"
fi

# ---

echo "🧪 Starting minimal Ken Burns test (duration: ${DURATION}s, frames: ${FRAMES}, pan: $PAN_DESC)..."

# Test 1: Basic static image to video (no effects)
echo "📹 Test 1: Basic static image to video"
ffmpeg -y -loop 1 -i "$INPUT" -vf "$SCALED" -c:v libx264 -pix_fmt yuv420p -r $FRAMERATE -t $DURATION test1_static.mp4

echo "✅ Test 1 complete. Check test1_static.mp4 - should be static image."

# Test 2: Simple zoom only
echo "🔍 Test 2: Simple zoom only"
ffmpeg -y -loop 1 -i "$INPUT" -vf "$SCALED,zoompan=z='1.0+0.1*on/$((FRAMES-1))':d=$FRAMES:s=1280x720" -c:v libx264 -pix_fmt yuv420p -r $FRAMERATE -t $DURATION test2_zoom.mp4

echo "✅ Test 2 complete. Check test2_zoom.mp4 - should zoom in."

# Test 3: Simple pan only
echo "🔄 Test 3: Simple pan only"
ffmpeg -y -loop 1 -i "$INPUT" -vf "$SCALED,zoompan=z=1.1:x='$PAN_EXPR':d=$FRAMES:s=1280x720" -c:v libx264 -pix_fmt yuv420p -r $FRAMERATE -t $DURATION test3_pan.mp4

echo "✅ Test 3 complete. Check test3_pan.mp4 - should pan $PAN_DESC."

# Test 4: Combined zoom and pan (our target)
echo "🎬 Test 4: Combined zoom and pan"
ffmpeg -y -loop 1 -i "$INPUT" -vf "$SCALED,zoompan=z='1.0+0.1*on/$((FRAMES-1))':x='$PAN_EXPR':d=$FRAMES:s=1280x720" -c:v libx264 -pix_fmt yuv420p -r $FRAMERATE -t $DURATION test4_kenburns.mp4

echo "✅ Test 4 complete. Check test4_kenburns.mp4 - should have Ken Burns effect ($PAN_DESC)."

# Test 5: Working version from our earlier test
echo "🎯 Test 5: Working version (exact filter from successful test)"
ffmpeg -y -loop 1 -i "$INPUT" -vf "zoompan=z='1.0+0.1*on/$((FRAMES-1))':x='$PAN_EXPR':y=0:d=$FRAMES:s=1280x720" -c:v libx264 -pix_fmt yuv420p -r $FRAMERATE -t $DURATION test5_working.mp4

echo "✅ Test 5 complete. Check test5_working.mp4 - should have working Ken Burns effect ($PAN_DESC)."

echo "🧪 All tests complete. Check each file to see which step works/fails." 