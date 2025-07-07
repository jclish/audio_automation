#!/bin/bash

# Ken Burns effect module for video creation
# Usage: source kenburns.sh
# Then call: apply_kenburns <input_image> <output_video> <duration> [clip_index]

# Default settings
DEFAULT_WIDTH=1280
DEFAULT_HEIGHT=720
DEFAULT_FRAMERATE=25
DEFAULT_ZOOM_START=1.0
DEFAULT_ZOOM_END=1.1

# Apply Ken Burns effect to an image
# Parameters:
#   $1 - input image file
#   $2 - output video file
#   $3 - duration in seconds
#   $4 - clip index (optional, for alternating pan directions)
apply_kenburns() {
    local input_image="$1"
    local output_video="$2"
    local duration="$3"
    local clip_index="${4:-0}"
    
    # Validate inputs
    if [[ -z "$input_image" || -z "$output_video" || -z "$duration" ]]; then
        echo "❌ Error: Missing required parameters for apply_kenburns"
        echo "Usage: apply_kenburns <input_image> <output_video> <duration> [clip_index]"
        return 1
    fi
    
    if [[ ! -f "$input_image" ]]; then
        echo "❌ Error: Input image file not found: $input_image"
        return 1
    fi
    
    echo "DEBUG: input_image=$input_image, output_video=$output_video, duration=$duration, clip_index=$clip_index"
    # Calculate frame count
    local frame_count=$(printf "%.0f" "$(echo "$DEFAULT_FRAMERATE * $duration" | bc -l)")
    echo "DEBUG: frame_count=$frame_count"
    
    # Determine pan direction based on clip index
    local pan_x
    if (( clip_index % 2 == 0 )); then
        # Left to right pan
        pan_x="iw*(1-zoom)*on/(in-1)"
    else
        # Right to left pan
        pan_x="iw*(1-zoom)*(1 - on/(in-1))"
    fi
    echo "DEBUG: pan_x=$pan_x"
    
    # Build Ken Burns filter
    local kenburns_filter="zoompan=z='1.0+0.1*on/(in-1)':x='$pan_x':y=0:d=$frame_count:s=${DEFAULT_WIDTH}x${DEFAULT_HEIGHT},trim=duration=$duration,setpts=PTS-STARTPTS"
    echo "DEBUG: kenburns_filter=$kenburns_filter"
    
    # Debug: Echo the ffmpeg command
    echo "ffmpeg -y -nostdin -loop 1 -i '$input_image' -vf '$kenburns_filter' -c:v libx264 -pix_fmt yuv420p -r '$DEFAULT_FRAMERATE' '$output_video' < /dev/null > ffmpeg.log 2>&1"
    # Use the helper for ffmpeg invocation
    if run_kenburns_ffmpeg "$input_image" "$output_video" "$kenburns_filter" "$DEFAULT_FRAMERATE" ffmpeg.log; then
        echo "✅ Ken Burns effect applied: $output_video"
    else
        echo "❌ Error applying Ken Burns effect to $input_image (see ffmpeg.log)"
        return 1
    fi
}

# Apply Ken Burns effect with custom zoom settings
# Parameters:
#   $1 - input image file
#   $2 - output video file
#   $3 - duration in seconds
#   $4 - clip index (optional)
#   $5 - zoom start (optional, default: 1.0)
#   $6 - zoom end (optional, default: 1.1)
apply_kenburns_custom() {
    local input_image="$1"
    local output_video="$2"
    local duration="$3"
    local clip_index="${4:-0}"
    local zoom_start="${5:-$DEFAULT_ZOOM_START}"
    local zoom_end="${6:-$DEFAULT_ZOOM_END}"
    
    # Validate inputs
    if [[ -z "$input_image" || -z "$output_video" || -z "$duration" ]]; then
        echo "❌ Error: Missing required parameters for apply_kenburns_custom"
        echo "Usage: apply_kenburns_custom <input_image> <output_video> <duration> [clip_index] [zoom_start] [zoom_end]"
        return 1
    fi
    
    if [[ ! -f "$input_image" ]]; then
        echo "❌ Error: Input image file not found: $input_image"
        return 1
    fi
    
    echo "DEBUG: input_image=$input_image, output_video=$output_video, duration=$duration, clip_index=$clip_index, zoom_start=$zoom_start, zoom_end=$zoom_end"
    # Calculate frame count
    local frame_count=$(printf "%.0f" "$(echo "$DEFAULT_FRAMERATE * $duration" | bc -l)")
    echo "DEBUG: frame_count=$frame_count"
    
    # Calculate zoom increment for immediate movement
    local zoom_range=$(echo "$zoom_end - $zoom_start" | bc -l)
    local zoom_increment=$(echo "$zoom_range / $frame_count" | bc -l)
    
    # Determine pan direction based on clip index
    local pan_x
    if (( clip_index % 2 == 0 )); then
        # Left to right pan
        pan_x="iw*(1-zoom)*on/(in-1)"
    else
        # Right to left pan
        pan_x="iw*(1-zoom)*(1 - on/(in-1))"
    fi
    echo "DEBUG: pan_x=$pan_x"
    
    # Build Ken Burns filter
    local kenburns_filter="zoompan=z='$zoom_start+$zoom_increment*on/(in-1)':x='$pan_x':y=0:d=$frame_count:s=${DEFAULT_WIDTH}x${DEFAULT_HEIGHT},trim=duration=$duration,setpts=PTS-STARTPTS"
    echo "DEBUG: kenburns_filter=$kenburns_filter"
    
    echo "ffmpeg -y -nostdin -loop 1 -framerate '$DEFAULT_FRAMERATE' -t '$duration' -i '$input_image' -vf '$kenburns_filter,format=yuv420p' -c:v libx264 -pix_fmt yuv420p '$output_video' < /dev/null > ffmpeg_custom.log 2>&1"
    # Use the helper for ffmpeg invocation
    local filter_with_format="$kenburns_filter,format=yuv420p"
    run_kenburns_ffmpeg "$input_image" "$output_video" "$filter_with_format" "$DEFAULT_FRAMERATE" ffmpeg_custom.log
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        echo "✅ Custom Ken Burns effect applied successfully"
    else
        echo "❌ Error applying custom Ken Burns effect (exit code: $exit_code, see ffmpeg_custom.log)"
    fi
    return $exit_code
}

# Apply Ken Burns effect with custom zoom and pan direction
# Parameters:
#   $1 - input image file
#   $2 - output video file
#   $3 - duration in seconds
#   $4 - pan direction: "left" or "right"
#   $5 - zoom start (optional, default: 1.0)
#   $6 - zoom end (optional, default: 1.1)
#   $7 - width (optional, default: DEFAULT_WIDTH)
#   $8 - height (optional, default: DEFAULT_HEIGHT)
#   $9 - framerate (optional, default: DEFAULT_FRAMERATE)
apply_kenburns_with_pan() {
    local input_image="$1"
    local output_video="$2"
    local duration="$3"
    local pan_direction="$4"
    local zoom_start="${5:-$DEFAULT_ZOOM_START}"
    local zoom_end="${6:-$DEFAULT_ZOOM_END}"
    local width="${7:-$DEFAULT_WIDTH}"
    local height="${8:-$DEFAULT_HEIGHT}"
    local framerate="${9:-$DEFAULT_FRAMERATE}"
    
    # Validate inputs
    if [[ -z "$input_image" || -z "$output_video" || -z "$duration" || -z "$pan_direction" ]]; then
        echo "❌ Error: Missing required parameters for apply_kenburns_with_pan"
        echo "Usage: apply_kenburns_with_pan <input_image> <output_video> <duration> <pan_direction> [zoom_start] [zoom_end]"
        return 1
    fi
    
    if [[ ! -f "$input_image" ]]; then
        echo "❌ Error: Input image file not found: $input_image"
        return 1
    fi
    
    if [[ "$pan_direction" != "left" && "$pan_direction" != "right" ]]; then
        echo "❌ Error: Pan direction must be 'left' or 'right'"
        return 1
    fi
    
    echo "DEBUG: input_image=$input_image, output_video=$output_video, duration=$duration, pan_direction=$pan_direction, zoom_start=$zoom_start, zoom_end=$zoom_end, width=$width, height=$height, framerate=$framerate"
    # Calculate frame count
    local frame_count=$(printf "%.0f" "$(echo "$framerate * $duration" | bc -l)")
    echo "DEBUG: frame_count=$frame_count"
    
    # Calculate zoom increment for immediate movement
    local zoom_range=$(echo "$zoom_end - $zoom_start" | bc -l)
    local zoom_increment=$(echo "$zoom_range / $frame_count" | bc -l)
    
    # Determine pan direction with immediate movement
    local pan_x
    if [[ "$pan_direction" == "left" ]]; then
        # Left to right pan
        pan_x="iw*(1-zoom)*on/(in-1)"
    else
        # Right to left pan
        pan_x="iw*(1-zoom)*(1 - on/(in-1))"
    fi
    echo "DEBUG: pan_x=$pan_x"
    
    # Build Ken Burns filter
    local kenburns_filter="zoompan=z='$zoom_start+$zoom_increment*on/(in-1)':x='$pan_x':y=0:d=$frame_count:s=${width}x${height},trim=duration=$duration,setpts=PTS-STARTPTS"
    echo "DEBUG: kenburns_filter=$kenburns_filter"
    
    echo "ffmpeg -y -nostdin -loop 1 -i '$input_image' -vf '$kenburns_filter' -c:v libx264 -pix_fmt yuv420p -r '$framerate' '$output_video' < /dev/null > ffmpeg_pan.log 2>&1"
    # Use the helper for ffmpeg invocation
    if run_kenburns_ffmpeg "$input_image" "$output_video" "$kenburns_filter" "$framerate" ffmpeg_pan.log; then
        echo "✅ Ken Burns effect applied: $output_video"
    else
        echo "❌ Error applying Ken Burns effect to $input_image (see ffmpeg_pan.log)"
        return 1
    fi
}

# Get Ken Burns filter string (for advanced usage)
# Parameters:
#   $1 - duration in seconds
#   $2 - clip index (optional)
#   $3 - zoom start (optional)
#   $4 - zoom end (optional)
get_kenburns_filter() {
    local duration="$1"
    local clip_index="${2:-0}"
    local zoom_start="${3:-$DEFAULT_ZOOM_START}"
    local zoom_end="${4:-$DEFAULT_ZOOM_END}"
    
    if [[ -z "$duration" ]]; then
        echo "❌ Error: Duration is required for get_kenburns_filter"
        return 1
    fi
    
    echo "DEBUG: duration=$duration, clip_index=$clip_index, zoom_start=$zoom_start, zoom_end=$zoom_end"
    local frame_count=$(printf "%.0f" "$(echo "$DEFAULT_FRAMERATE * $duration" | bc -l)")
    echo "DEBUG: frame_count=$frame_count"
    local zoom_range=$(echo "$zoom_end - $zoom_start" | bc -l)
    local zoom_increment=$(echo "$zoom_range / $frame_count" | bc -l)
    
    local pan_x
    if (( clip_index % 2 == 0 )); then
        pan_x="iw*(1-zoom)*on/(in-1)"
    else
        pan_x="iw*(1-zoom)*(1 - on/(in-1))"
    fi
    echo "DEBUG: pan_x=$pan_x"
    
    echo "zoompan=z='$zoom_start+$zoom_increment*on/(in-1)':x='$pan_x':y=0:d=$frame_count:s=${DEFAULT_WIDTH}x${DEFAULT_HEIGHT},trim=duration=$duration,setpts=PTS-STARTPTS"
}

# Helper: Run ffmpeg for Ken Burns effect
# Arguments: input_image, output_video, filter, framerate, log_file
run_kenburns_ffmpeg() {
    local input_image="$1"
    local output_video="$2"
    local filter="$3"
    local framerate="$4"
    local log_file="$5"
    ffmpeg -y -nostdin -loop 1 -i "$input_image" -vf "$filter" -c:v libx264 -pix_fmt yuv420p -r "$framerate" "$output_video" < /dev/null > "$log_file" 2>&1
    return $?
}

# Export functions for use in other scripts
export -f apply_kenburns
export -f apply_kenburns_custom
export -f apply_kenburns_with_pan
export -f get_kenburns_filter

echo "🎬 Ken Burns module loaded successfully"
echo "Available functions:"
echo "  - apply_kenburns <input> <output> <duration> [clip_index]"
echo "  - apply_kenburns_custom <input> <output> <duration> [clip_index] [zoom_start] [zoom_end]"
echo "  - apply_kenburns_with_pan <input> <output> <duration> <pan_direction> [zoom_start] [zoom_end]"
echo "  - get_kenburns_filter <duration> [clip_index] [zoom_start] [zoom_end]" 