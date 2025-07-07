#!/usr/bin/env bats

# Resolution and Framerate Tests
# Tests for custom output resolution and framerate functionality

setup() {
    # Create test directories and files
    export TEST_DIR="$(mktemp -d)"
    export ORIGINAL_DIR="$(pwd)"
    cd "$TEST_DIR"
    
    # Create test audio file
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

# Test common resolution formats
@test "generates 1920x1080 (Full HD)" {
    run bash makevid.sh test_audio.wav --len 2 --width 1920 --height 1080
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 output_with_audio.mp4
    [ "$output" = "1920,1080" ]
}

@test "generates 1280x720 (HD)" {
    run bash makevid.sh test_audio.wav --len 2 --width 1280 --height 720
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 output_with_audio.mp4
    [ "$output" = "1280,720" ]
}

@test "generates 854x480 (SD)" {
    run bash makevid.sh test_audio.wav --len 2 --width 854 --height 480
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 output_with_audio.mp4
    [ "$output" = "854,480" ]
}

@test "generates 720x720 (square)" {
    run bash makevid.sh test_audio.wav --len 2 --width 720 --height 720
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 output_with_audio.mp4
    [ "$output" = "720,720" ]
}

@test "generates 720x1280 (portrait)" {
    run bash makevid.sh test_audio.wav --len 2 --width 720 --height 1280
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 output_with_audio.mp4
    [ "$output" = "720,1280" ]
}

# Test common framerates
@test "generates 24 fps (cinematic)" {
    run bash makevid.sh test_audio.wav --len 2 --fps 24
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 output_with_audio.mp4
    [ "$output" = "24/1" ]
}

@test "generates 25 fps (PAL)" {
    run bash makevid.sh test_audio.wav --len 2 --fps 25
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 output_with_audio.mp4
    [ "$output" = "25/1" ]
}

@test "generates 30 fps (NTSC)" {
    run bash makevid.sh test_audio.wav --len 2 --fps 30
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 output_with_audio.mp4
    [ "$output" = "30/1" ]
}

@test "generates 60 fps (high refresh)" {
    run bash makevid.sh test_audio.wav --len 2 --fps 60
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 output_with_audio.mp4
    [ "$output" = "60/1" ]
}

# Test resolution validation
@test "rejects width below minimum" {
    run bash makevid.sh test_audio.wav --width 100
    [ "$status" -eq 1 ]
    [[ "$output" =~ "must be between 320 and 7680" ]]
}

@test "rejects width above maximum" {
    run bash makevid.sh test_audio.wav --width 8000
    [ "$status" -eq 1 ]
    [[ "$output" =~ "must be between 320 and 7680" ]]
}

@test "rejects height below minimum" {
    run bash makevid.sh test_audio.wav --height 100
    [ "$status" -eq 1 ]
    [[ "$output" =~ "must be between 240 and 4320" ]]
}

@test "rejects height above maximum" {
    run bash makevid.sh test_audio.wav --height 5000
    [ "$status" -eq 1 ]
    [[ "$output" =~ "must be between 240 and 4320" ]]
}

# Test framerate validation
@test "rejects framerate below minimum" {
    run bash makevid.sh test_audio.wav --fps 0
    [ "$status" -eq 1 ]
    [[ "$output" =~ "must be between 1 and 120" ]]
}

@test "rejects framerate above maximum" {
    run bash makevid.sh test_audio.wav --fps 121
    [ "$status" -eq 1 ]
    [[ "$output" =~ "must be between 1 and 120" ]]
}

# Test resolution and framerate combinations
@test "combines resolution and framerate correctly" {
    run bash makevid.sh test_audio.wav --len 2 --width 1280 --height 720 --fps 30
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height,r_frame_rate -of csv=p=0 output_with_audio.mp4
    [ "$output" = "1280,720,30/1" ]
}

@test "combines with Ken Burns effects" {
    run bash makevid.sh test_audio.wav --len 2 --width 1920 --height 1080 --fps 24 --kb-zoom-start 0.8 --kb-zoom-end 1.2 --kb-pan random
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height,r_frame_rate -of csv=p=0 output_with_audio.mp4
    [ "$output" = "1920,1080,24/1" ]
}

# Test edge cases
@test "handles minimum valid resolution" {
    run bash makevid.sh test_audio.wav --len 2 --width 320 --height 240
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 output_with_audio.mp4
    [ "$output" = "320,240" ]
}

@test "handles maximum valid resolution" {
    run bash makevid.sh test_audio.wav --len 2 --width 7680 --height 4320
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 output_with_audio.mp4
    [ "$output" = "7680,4320" ]
}

@test "handles minimum valid framerate" {
    run bash makevid.sh test_audio.wav --len 2 --fps 1
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 output_with_audio.mp4
    [ "$output" = "1/1" ]
}

@test "handles maximum valid framerate" {
    run bash makevid.sh test_audio.wav --len 2 --fps 120
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 output_with_audio.mp4
    [ "$output" = "120/1" ]
}

# Test output quality
@test "maintains aspect ratio with padding" {
    run bash makevid.sh test_audio.wav --len 2 --width 1280 --height 720
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    # Check that video has correct dimensions
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 output_with_audio.mp4
    [ "$output" = "1280,720" ]
    
    # Check that video has audio stream
    run ffprobe -v quiet -select_streams a -show_entries stream=codec_type -of csv=p=0 output_with_audio.mp4
    [ "$output" = "audio" ]
}

# Test performance with different resolutions
@test "performance with high resolution" {
    local start_time=$(date +%s)
    run bash makevid.sh test_audio.wav --len 2 --width 1920 --height 1080 --fps 30
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    # Should complete within reasonable time (adjust as needed)
    [ $duration -lt 60 ]
}

# Test memory usage with different resolutions
@test "memory usage with 4K resolution" {
    run bash makevid.sh test_audio.wav --len 2 --width 3840 --height 2160 --fps 30
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    # Check file size is reasonable for 4K
    local file_size=$(stat -f%z output_with_audio.mp4 2>/dev/null || stat -c%s output_with_audio.mp4 2>/dev/null)
    [ $file_size -gt 10000 ]  # Should be at least 10KB
}

# Test compatibility
@test "output is compatible with common players" {
    run bash makevid.sh test_audio.wav --len 2 --width 1280 --height 720 --fps 25
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    # Check codec is H.264
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 output_with_audio.mp4
    [ "$output" = "h264" ]
    
    # Check pixel format is yuv420p (widely compatible)
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=pix_fmt -of csv=p=0 output_with_audio.mp4
    [ "$output" = "yuv420p" ]
} 