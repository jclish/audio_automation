#!/usr/bin/env bats

# Integration Tests
# Tests for complete workflow and real-world scenarios

setup() {
    # Create test directories and files
    export TEST_DIR="$(mktemp -d)"
    export ORIGINAL_DIR="$(pwd)"
    cd "$TEST_DIR"
    
    # Create test audio files of different lengths
    ffmpeg -f lavfi -i "anullsrc=r=44100:cl=stereo" -t 1 -q:a 9 -acodec libmp3lame short_audio.wav 2>/dev/null || true
    ffmpeg -f lavfi -i "anullsrc=r=44100:cl=stereo" -t 5 -q:a 9 -acodec libmp3lame medium_audio.wav 2>/dev/null || true
    ffmpeg -f lavfi -i "anullsrc=r=44100:cl=stereo" -t 10 -q:a 9 -acodec libmp3lame long_audio.wav 2>/dev/null || true
    
    # Create test images of different sizes
    convert -size 100x100 xc:red small_image.jpg 2>/dev/null || true
    convert -size 500x500 xc:blue medium_image.jpg 2>/dev/null || true
    convert -size 1920x1080 xc:green large_image.jpg 2>/dev/null || true
    
    # Determine project root (parent of tests directory)
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    # Copy the main script and modules
    cp "$PROJECT_ROOT/makevid.sh" .
    cp "$PROJECT_ROOT/kenburns.sh" .
    
    # Create test media directory with multiple images
    mkdir -p Videos
    cp small_image.jpg Videos/ 2>/dev/null || true
    cp medium_image.jpg Videos/ 2>/dev/null || true
    cp large_image.jpg Videos/ 2>/dev/null || true
}

teardown() {
    # Clean up test directory
    cd "$ORIGINAL_DIR"
    rm -rf "$TEST_DIR"
}

# Test complete workflow scenarios
@test "complete workflow with short audio" {
    run bash makevid.sh short_audio.wav --len 2 --verbose
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    [ -f "video_only.mp4" ]
    
    # Check video duration matches audio
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=duration -of csv=p=0 output_with_audio.mp4
    local video_duration=$(echo "$output" | bc -l)
    [ $(echo "$video_duration >= 0.8" | bc -l) -eq 1 ]
    [ $(echo "$video_duration <= 1.2" | bc -l) -eq 1 ]
}

@test "complete workflow with medium audio" {
    run bash makevid.sh medium_audio.wav --len 3 --lenvar 20 --volume 1.5
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    # Check video duration is reasonable
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=duration -of csv=p=0 output_with_audio.mp4
    local video_duration=$(echo "$output" | bc -l)
    [ $(echo "$video_duration >= 4.5" | bc -l) -eq 1 ]
    [ $(echo "$video_duration <= 5.5" | bc -l) -eq 1 ]
}

@test "complete workflow with long audio" {
    run bash makevid.sh long_audio.wav --len 4 --jobs 2 --shuffle
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    # Check video duration is reasonable
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=duration -of csv=p=0 output_with_audio.mp4
    local video_duration=$(echo "$output" | bc -l)
    [ $(echo "$video_duration >= 9.5" | bc -l) -eq 1 ]
    [ $(echo "$video_duration <= 10.5" | bc -l) -eq 1 ]
}

# Test different output formats and qualities
@test "high quality output for professional use" {
    run bash makevid.sh medium_audio.wav --len 3 --width 1920 --height 1080 --fps 30 --kb-zoom-start 0.8 --kb-zoom-end 1.2 --kb-pan random
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    # Check high quality settings
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height,r_frame_rate -of csv=p=0 output_with_audio.mp4
    [ "$output" = "1920,1080,30/1" ]
    
    # Check file size is reasonable for high quality
    local file_size=$(stat -f%z output_with_audio.mp4 2>/dev/null || stat -c%s output_with_audio.mp4 2>/dev/null)
    [ $file_size -gt 50000 ]  # Should be at least 50KB for high quality
}

@test "web-optimized output" {
    run bash makevid.sh short_audio.wav --len 2 --width 854 --height 480 --fps 25
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    # Check web-optimized settings
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height,r_frame_rate -of csv=p=0 output_with_audio.mp4
    [ "$output" = "854,480,25/1" ]
    
    # Check file size is reasonable for web
    local file_size=$(stat -f%z output_with_audio.mp4 2>/dev/null || stat -c%s output_with_audio.mp4 2>/dev/null)
    [ $file_size -lt 1000000 ]  # Should be under 1MB for web
}

@test "mobile-optimized output" {
    run bash makevid.sh short_audio.wav --len 2 --width 720 --height 1280 --fps 30
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    # Check mobile-optimized settings
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height,r_frame_rate -of csv=p=0 output_with_audio.mp4
    [ "$output" = "720,1280,30/1" ]
}

# Test parallel processing scenarios
@test "parallel processing with multiple jobs" {
    run bash makevid.sh medium_audio.wav --len 3 --jobs 4 --verbose
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    # Should complete successfully with parallel processing
    [ -f "output_with_audio.mp4" ]
}

@test "parallel processing with single job" {
    run bash makevid.sh short_audio.wav --len 2 --jobs 1
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    # Should complete successfully with single job
    [ -f "output_with_audio.mp4" ]
}

# Test Ken Burns effect variations
@test "Ken Burns with extreme zoom out" {
    run bash makevid.sh short_audio.wav --len 2 --kb-zoom-start 0.5 --kb-zoom-end 0.6 --kb-pan left
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
}

@test "Ken Burns with extreme zoom in" {
    run bash makevid.sh short_audio.wav --len 2 --kb-zoom-start 1.8 --kb-zoom-end 2.0 --kb-pan right
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
}

@test "Ken Burns with subtle movement" {
    run bash makevid.sh short_audio.wav --len 2 --kb-zoom-start 0.9 --kb-zoom-end 1.1 --kb-pan alternate
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
}

# Test audio processing scenarios
@test "audio with volume boost" {
    run bash makevid.sh short_audio.wav --len 2 --volume 3.0
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    # Check that audio is present
    run ffprobe -v quiet -select_streams a -show_entries stream=codec_type -of csv=p=0 output_with_audio.mp4
    [ "$output" = "audio" ]
}

@test "audio with volume reduction" {
    run bash makevid.sh short_audio.wav --len 2 --volume 0.5
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    # Check that audio is present
    run ffprobe -v quiet -select_streams a -show_entries stream=codec_type -of csv=p=0 output_with_audio.mp4
    [ "$output" = "audio" ]
}

# Test error recovery scenarios
@test "handles missing media gracefully" {
    rm -rf Videos
    run bash makevid.sh short_audio.wav --len 2
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
}

@test "handles corrupted media gracefully" {
    echo "not an image" > Videos/corrupted.jpg
    run bash makevid.sh short_audio.wav --len 2
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
}

# Test file management
@test "keeps temporary files when requested" {
    run bash makevid.sh short_audio.wav --len 2 --keep
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    [ -d "tmp_work" ]
}

@test "cleans up temporary files by default" {
    run bash makevid.sh short_audio.wav --len 2
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    [ ! -d "tmp_work" ]
}

# Test real-world scenarios
@test "social media vertical video" {
    run bash makevid.sh short_audio.wav --len 2 --width 1080 --height 1920 --fps 30 --kb-zoom-start 0.8 --kb-zoom-end 1.1 --kb-pan random
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    # Check vertical format
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 output_with_audio.mp4
    [ "$output" = "1080,1920" ]
}

@test "cinematic widescreen video" {
    run bash makevid.sh medium_audio.wav --len 3 --width 1920 --height 800 --fps 24 --kb-zoom-start 0.9 --kb-zoom-end 1.1 --kb-pan alternate
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    # Check widescreen format
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 output_with_audio.mp4
    [ "$output" = "1920,800" ]
}

@test "square format for Instagram" {
    run bash makevid.sh short_audio.wav --len 2 --width 1080 --height 1080 --fps 30 --kb-zoom-start 0.8 --kb-zoom-end 1.2 --kb-pan random
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    # Check square format
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 output_with_audio.mp4
    [ "$output" = "1080,1080" ]
}

# Test performance under load
@test "handles multiple concurrent runs" {
    # Start multiple processes
    bash makevid.sh short_audio.wav --len 2 --jobs 1 &
    local pid1=$!
    bash makevid.sh short_audio.wav --len 2 --jobs 1 &
    local pid2=$!
    
    # Wait for both to complete
    wait $pid1
    wait $pid2
    
    # Both should have completed successfully
    [ -f "output_with_audio.mp4" ]
}

# Test memory and resource usage
@test "memory usage with large resolution" {
    run bash makevid.sh short_audio.wav --len 2 --width 3840 --height 2160 --fps 60
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    # Check that process completed without memory issues
    [ -f "output_with_audio.mp4" ]
}

# Test compatibility with different audio formats
@test "handles different audio formats" {
    # Create MP3 audio
    ffmpeg -f lavfi -i "anullsrc=r=44100:cl=stereo" -t 1 -q:a 9 -acodec libmp3lame test_audio.mp3 2>/dev/null || true
    
    run bash makevid.sh test_audio.mp3 --len 2
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
}

# Test output validation
@test "output video is playable" {
    run bash makevid.sh short_audio.wav --len 2
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    # Test that video can be read by ffprobe
    run ffprobe -v quiet output_with_audio.mp4
    [ "$status" -eq 0 ]
    
    # Test that video has both video and audio streams
    run ffprobe -v quiet -select_streams v -show_entries stream=codec_type -of csv=p=0 output_with_audio.mp4
    [ "$output" = "video" ]
    
    run ffprobe -v quiet -select_streams a -show_entries stream=codec_type -of csv=p=0 output_with_audio.mp4
    [ "$output" = "audio" ]
} 