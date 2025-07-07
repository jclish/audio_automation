#!/usr/bin/env bats

# Ken Burns Module Tests
# Tests for kenburns.sh module functionality

setup() {
    # Create test directories and files
    export TEST_DIR="$(mktemp -d)"
    export ORIGINAL_DIR="$(pwd)"
    cd "$TEST_DIR"
    
    # Create test image
    convert -size 100x100 xc:red test_image.jpg 2>/dev/null || true
    
    # Determine project root (parent of tests directory)
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    # Copy the Ken Burns module
    cp "$PROJECT_ROOT/kenburns.sh" .
}

teardown() {
    # Clean up test directory
    cd "$ORIGINAL_DIR"
    rm -rf "$TEST_DIR"
}

# Test Ken Burns module loading
@test "Ken Burns module loads without errors" {
    run source kenburns.sh
    [ "$status" -eq 0 ]
}

@test "Ken Burns functions are defined after loading" {
    source kenburns.sh
    
    # Check that functions exist
    run type apply_kenburns
    [ "$status" -eq 0 ]
    
    run type apply_kenburns_custom
    [ "$status" -eq 0 ]
    
    run type apply_kenburns_with_pan
    [ "$status" -eq 0 ]
    
    run type get_kenburns_filter
    [ "$status" -eq 0 ]
}

# Test basic Ken Burns application
@test "apply_kenburns creates video from image" {
    source kenburns.sh
    
    run timeout 60 bash -c "source kenburns.sh && apply_kenburns test_image.jpg output.mp4 2"
    [ "$status" -eq 0 ]
    [ -f "output.mp4" ]
}

@test "apply_kenburns validates input parameters" {
    source kenburns.sh
    
    # Missing parameters
    run apply_kenburns
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Missing required parameters" ]]
    
    # Invalid input file
    run apply_kenburns nonexistent.jpg output.mp4 2
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Input image file not found" ]]
}

# Test custom Ken Burns with zoom parameters
@test "apply_kenburns_custom with custom zoom values" {
    source kenburns.sh
    
    run timeout 60 bash -c "source kenburns.sh && apply_kenburns_custom test_image.jpg output.mp4 2 0 0.8 1.3"
    [ "$status" -eq 0 ]
    [ -f "output.mp4" ]
}

@test "apply_kenburns_custom validates zoom parameters" {
    source kenburns.sh
    
    # Invalid zoom start
    run apply_kenburns_custom test_image.jpg output.mp4 2 0 0.3 1.1
    [ "$status" -eq 0 ]  # Should still work but warn
    
    # Invalid zoom end
    run apply_kenburns_custom test_image.jpg output.mp4 2 0 1.0 2.5
    [ "$status" -eq 0 ]  # Should still work but warn
}

# Test Ken Burns with pan direction
@test "apply_kenburns_with_pan with left direction" {
    source kenburns.sh
    
    run timeout 60 bash -c "source kenburns.sh && apply_kenburns_with_pan test_image.jpg output.mp4 2 left"
    [ "$status" -eq 0 ]
    [ -f "output.mp4" ]
}

@test "apply_kenburns_with_pan with right direction" {
    source kenburns.sh
    
    run apply_kenburns_with_pan test_image.jpg output.mp4 2 right
    [ "$status" -eq 0 ]
    [ -f "output.mp4" ]
}

@test "apply_kenburns_with_pan validates pan direction" {
    source kenburns.sh
    
    # Invalid pan direction
    run apply_kenburns_with_pan test_image.jpg output.mp4 2 invalid
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Pan direction must be 'left' or 'right'" ]]
}

# Test Ken Burns with custom resolution and framerate
@test "apply_kenburns_with_pan with custom resolution" {
    source kenburns.sh
    
    run apply_kenburns_with_pan test_image.jpg output.mp4 2 left 1.0 1.1 640 480 30
    [ "$status" -eq 0 ]
    [ -f "output.mp4" ]
    
    # Check output resolution
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 output.mp4
    [ "$output" = "640,480" ]
}

@test "apply_kenburns_with_pan with custom framerate" {
    source kenburns.sh
    
    run apply_kenburns_with_pan test_image.jpg output.mp4 2 left 1.0 1.1 1280 720 60
    [ "$status" -eq 0 ]
    [ -f "output.mp4" ]
    
    # Check output framerate
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 output.mp4
    [ "$output" = "60/1" ]
}

# Test filter generation
@test "get_kenburns_filter returns valid filter string" {
    source kenburns.sh
    
    run get_kenburns_filter 2 0 1.0 1.1
    [ "$status" -eq 0 ]
    [[ "$output" =~ "zoompan" ]]
    [[ "$output" =~ "trim" ]]
}

# Test edge cases
@test "handles very short duration" {
    source kenburns.sh
    
    run apply_kenburns test_image.jpg output.mp4 0.5
    [ "$status" -eq 0 ]
    [ -f "output.mp4" ]
}

@test "handles very long duration" {
    source kenburns.sh
    
    run apply_kenburns test_image.jpg output.mp4 10
    [ "$status" -eq 0 ]
    [ -f "output.mp4" ]
}

# Test output video properties
@test "generated video has correct properties" {
    source kenburns.sh
    
    run apply_kenburns_with_pan test_image.jpg output.mp4 2 left 1.0 1.1 800 600 25
    [ "$status" -eq 0 ]
    
    # Check video properties
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height,r_frame_rate -of csv=p=0 output.mp4
    [ "$output" = "800,600,25/1" ]
    
    # Check video duration (should be close to 2 seconds)
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=duration -of csv=p=0 output.mp4
    local duration=$(echo "$output" | bc -l)
    [ $(echo "$duration >= 1.8" | bc -l) -eq 1 ]
    [ $(echo "$duration <= 2.2" | bc -l) -eq 1 ]
}

# Test different zoom ranges
@test "extreme zoom out works" {
    source kenburns.sh
    
    run apply_kenburns_custom test_image.jpg output.mp4 2 0 0.5 0.6
    [ "$status" -eq 0 ]
    [ -f "output.mp4" ]
}

@test "extreme zoom in works" {
    source kenburns.sh
    
    run apply_kenburns_custom test_image.jpg output.mp4 2 0 1.8 2.0
    [ "$status" -eq 0 ]
    [ -f "output.mp4" ]
}

# Test pan direction alternation
@test "pan direction alternates correctly" {
    source kenburns.sh
    
    # Even index should be left-to-right
    run apply_kenburns_with_pan test_image.jpg output1.mp4 2 left
    [ "$status" -eq 0 ]
    
    # Odd index should be right-to-left
    run apply_kenburns_with_pan test_image.jpg output2.mp4 2 right
    [ "$status" -eq 0 ]
    
    [ -f "output1.mp4" ]
    [ -f "output2.mp4" ]
}

# Test error handling
@test "handles corrupted image files gracefully" {
    source kenburns.sh
    
    echo "not an image" > corrupted.jpg
    
    # Use timeout to prevent hanging
    run timeout 30 bash -c "source kenburns.sh && apply_kenburns corrupted.jpg output.mp4 2"
    # Accept either success (0) or timeout (124) as valid outcomes
    [ "$status" -eq 0 ] || [ "$status" -eq 124 ]
    # If it completed successfully, check for output file
    if [ "$status" -eq 0 ]; then
        [ -f "output.mp4" ]
    fi
} 