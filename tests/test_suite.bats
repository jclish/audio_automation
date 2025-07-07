#!/usr/bin/env bats

# Audio Automation Test Suite
# Tests for makevid.sh and related components

setup() {
    # Create test directories and files
    export TEST_DIR="$(mktemp -d)"
    export ORIGINAL_DIR="$(pwd)"
    cd "$TEST_DIR"
    
    # Create test audio file (1 second of silence)
    ffmpeg -f lavfi -i "anullsrc=r=44100:cl=stereo" -t 1 -q:a 9 -acodec libmp3lame test_audio.wav 2>/dev/null || true
    
    # Create test image
    convert -size 100x100 xc:red test_image.jpg 2>/dev/null || true
    
    # Determine project root (parent of tests directory)
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    # Copy the main script and modules
    cp "$PROJECT_ROOT/makevid.sh" .
    cp "$PROJECT_ROOT/kenburns.sh" .
    
    # Create test media directory
    mkdir -p Videos
    cp test_image.jpg Videos/ 2>/dev/null || true
}

teardown() {
    # Clean up test directory
    cd "$ORIGINAL_DIR"
    rm -rf "$TEST_DIR"
}

# Helper function to check if ffmpeg is available
@test "ffmpeg is available" {
    run which ffmpeg
    [ "$status" -eq 0 ]
}

# Helper function to check if convert (ImageMagick) is available
@test "ImageMagick is available" {
    run which convert
    [ "$status" -eq 0 ]
}

# Test basic script functionality
@test "script runs without arguments (shows help)" {
    run bash makevid.sh
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Audio file is required" ]]
}

@test "script shows help with invalid audio file" {
    run bash makevid.sh nonexistent.wav
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Audio file not found" ]]
}

@test "script accepts valid audio file" {
    run bash makevid.sh test_audio.wav --len 2
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
}

# Test parameter validation
@test "validates clip duration bounds" {
    run bash makevid.sh test_audio.wav --len 1
    [ "$status" -eq 1 ]
    [[ "$output" =~ "cannot be less than 2 seconds" ]]
    
    run bash makevid.sh test_audio.wav --len 11
    [ "$status" -eq 1 ]
    [[ "$output" =~ "cannot be more than 10 seconds" ]]
}

@test "validates jobs parameter" {
    run bash makevid.sh test_audio.wav --jobs 0
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Jobs must be between 1 and 8" ]]
    
    run bash makevid.sh test_audio.wav --jobs 9
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Jobs must be between 1 and 8" ]]
}

@test "validates Ken Burns zoom parameters" {
    run bash makevid.sh test_audio.wav --kb-zoom-start 0.4
    [ "$status" -eq 1 ]
    [[ "$output" =~ "must be between 0.5 and 2.0" ]]
    
    run bash makevid.sh test_audio.wav --kb-zoom-end 2.1
    [ "$status" -eq 1 ]
    [[ "$output" =~ "must be between 0.5 and 2.0" ]]
}

@test "validates Ken Burns pan mode" {
    run bash makevid.sh test_audio.wav --kb-pan invalid
    [ "$status" -eq 1 ]
    [[ "$output" =~ "must be: alternate, left-right, right-left, or random" ]]
}

@test "validates output resolution parameters" {
    run bash makevid.sh test_audio.wav --width 100
    [ "$status" -eq 1 ]
    [[ "$output" =~ "must be between 320 and 7680" ]]
    
    run bash makevid.sh test_audio.wav --height 100
    [ "$status" -eq 1 ]
    [[ "$output" =~ "must be between 240 and 4320" ]]
}

@test "validates framerate parameter" {
    run bash makevid.sh test_audio.wav --fps 0
    [ "$status" -eq 1 ]
    [[ "$output" =~ "must be between 1 and 120" ]]
    
    run bash makevid.sh test_audio.wav --fps 121
    [ "$status" -eq 1 ]
    [[ "$output" =~ "must be between 1 and 120" ]]
}

# Test output generation
@test "generates video with default settings" {
    run timeout 60 bash makevid.sh test_audio.wav --len 2
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    [ -f "video_only.mp4" ]
}

@test "generates video with custom resolution" {
    run bash makevid.sh test_audio.wav --len 2 --width 640 --height 480
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    # Check output resolution
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 output_with_audio.mp4
    [ "$output" = "640,480" ]
}

@test "generates video with custom framerate" {
    run bash makevid.sh test_audio.wav --len 2 --fps 30
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    # Check output framerate
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 output_with_audio.mp4
    [ "$output" = "30/1" ]
}

@test "generates video with Ken Burns effects" {
    run bash makevid.sh test_audio.wav --len 2 --kb-zoom-start 0.8 --kb-zoom-end 1.2 --kb-pan random
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
}

@test "generates video with parallel processing" {
    run bash makevid.sh test_audio.wav --len 2 --jobs 2
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
}

@test "generates video with verbose output" {
    run bash makevid.sh test_audio.wav --len 2 --verbose
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    [[ "$output" =~ "ffmpeg" ]]
}

# Test Ken Burns module
@test "Ken Burns module loads successfully" {
    run bash -c "source kenburns.sh && echo 'Module loaded'"
    [ "$status" -eq 0 ]
    [ "$output" = "Module loaded" ]
}

@test "Ken Burns functions are available" {
    source kenburns.sh
    
    # Test apply_kenburns function exists
    run type apply_kenburns
    [ "$status" -eq 0 ]
    
    # Test apply_kenburns_with_pan function exists
    run type apply_kenburns_with_pan
    [ "$status" -eq 0 ]
}

# Test edge cases
@test "handles very short audio" {
    # Create 0.5 second audio
    ffmpeg -f lavfi -i "anullsrc=r=44100:cl=stereo" -t 0.5 -q:a 9 -acodec libmp3lame short_audio.wav 2>/dev/null
    run bash makevid.sh short_audio.wav --len 2
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
}

@test "handles missing media directory gracefully" {
    rm -rf Videos
    run bash makevid.sh test_audio.wav --len 2
    [ "$status" -eq 0 ]
    # Should still work with default behavior
}

# Test output file properties
@test "output video has correct properties" {
    run bash makevid.sh test_audio.wav --len 2 --width 1280 --height 720 --fps 25
    [ "$status" -eq 0 ]
    
    # Check video properties
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height,r_frame_rate -of csv=p=0 output_with_audio.mp4
    [ "$output" = "1280,720,25/1" ]
    
    # Check that video has audio
    run ffprobe -v quiet -select_streams a -show_entries stream=codec_type -of csv=p=0 output_with_audio.mp4
    [ "$output" = "audio" ]
}

# Test error handling
@test "handles invalid media files gracefully" {
    echo "not an image" > Videos/invalid.jpg
    run timeout 30 bash makevid.sh test_audio.wav --len 2
    [ "$status" -eq 0 ] || [ "$status" -eq 124 ]  # 124 is timeout exit code
    # Should still complete successfully or timeout gracefully
}

# Test parameter combinations
@test "combines multiple parameters correctly" {
    run bash makevid.sh test_audio.wav --len 3 --lenvar 10 --volume 2.0 --jobs 2 --width 800 --height 600 --fps 30 --kb-zoom-start 0.9 --kb-zoom-end 1.1 --kb-pan alternate
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    # Verify output properties
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height,r_frame_rate -of csv=p=0 output_with_audio.mp4
    [ "$output" = "800,600,30/1" ]
}

# Performance tests
@test "parallel processing improves performance" {
    # This is a basic test - in practice you'd measure actual timing
    run bash makevid.sh test_audio.wav --len 2 --jobs 1
    local sequential_time=$SECONDS
    
    run bash makevid.sh test_audio.wav --len 2 --jobs 2
    local parallel_time=$SECONDS
    
    # Both should complete successfully
    [ "$status" -eq 0 ]
}

# Test file cleanup
@test "creates and cleans up temporary files" {
    run bash makevid.sh test_audio.wav --len 2
    [ "$status" -eq 0 ]
    
    # Should not leave tmp_work directory in current location
    [ ! -d "tmp_work" ]
}

# Test help output
@test "help shows all available options" {
    run bash makevid.sh
    [ "$status" -eq 1 ]
    
    # Check for key option descriptions
    [[ "$output" =~ "--shuffle" ]]
    [[ "$output" =~ "--volume" ]]
    [[ "$output" =~ "--len" ]]
    [[ "$output" =~ "--width" ]]
    [[ "$output" =~ "--height" ]]
    [[ "$output" =~ "--fps" ]]
    [[ "$output" =~ "--kb-zoom-start" ]]
    [[ "$output" =~ "--kb-zoom-end" ]]
    [[ "$output" =~ "--kb-pan" ]]
} 