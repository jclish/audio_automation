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
    
    # Calculate frame count
    local frame_count=$(printf "%.0f" "$(echo "$DEFAULT_FRAMERATE * $duration" | bc -l)")
    
    # Determine pan direction based on clip index
    local pan_x
    if (( clip_index % 2 == 0 )); then
        # Left to right pan
        pan_x="iw*(1-zoom)*on/(in-1)"
    else
        # Right to left pan
        pan_x="iw*(1-zoom)*(1 - on/(in-1))"
    fi
    
    # Build Ken Burns filter
    local kenburns_filter="zoompan=z='zoom+0.001':x='$pan_x':y=0:d=$frame_count:s=${DEFAULT_WIDTH}x${DEFAULT_HEIGHT},trim=duration=$duration,setpts=PTS-STARTPTS"
    
    echo "�� Applying Ken Burns effect: $(basename "$input_image") → $(basename "$output_video") (${duration}s)"
    echo "   Pan direction: $([ $((clip_index % 2)) -eq 0 ] && echo "left→right" || echo "right→left")"
    
    # Apply the effect using ffmpeg
    ffmpeg -y -loop 1 -framerate "$DEFAULT_FRAMERATE" -t "$duration" -i "$input_image" \
        -vf "$kenburns_filter,format=yuv420p" \
        -c:v libx264 -pix_fmt yuv420p "$output_video"
    
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        echo "✅ Ken Burns effect applied successfully"
    else
        echo "❌ Error applying Ken Burns effect (exit code: $exit_code)"
    fi
    
    return $exit_code
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
    
    # Calculate frame count
    local frame_count=$(printf "%.0f" "$(echo "$DEFAULT_FRAMERATE * $duration" | bc -l)")
    
    # Calculate zoom increment with immediate movement
    # Adjust zoom start slightly to ensure immediate pan movement
    local effective_zoom_start=$(echo "$zoom_start * 0.98" | bc -l)
    local zoom_increment=$(echo "($zoom_end - $effective_zoom_start) / $frame_count" | bc -l)
    
    # Determine pan direction based on clip index
    local pan_x
    if (( clip_index % 2 == 0 )); then
        # Left to right pan
        pan_x="iw*(1-zoom)*on/(in-1)"
    else
        # Right to left pan
        pan_x="iw*(1-zoom)*(1 - on/(in-1))"
    fi
    
    # Build Ken Burns filter with custom zoom and immediate movement
    local kenburns_filter="zoompan=z='$effective_zoom_start+$zoom_increment*on':x='$pan_x':y=0:d=$frame_count:s=${DEFAULT_WIDTH}x${DEFAULT_HEIGHT},trim=duration=$duration,setpts=PTS-STARTPTS"
    
    echo "🎬 Applying custom Ken Burns effect: $(basename "$input_image") → $(basename "$output_video") (${duration}s)"
    echo "   Zoom: ${zoom_start} → ${zoom_end}, Pan: $([ $((clip_index % 2)) -eq 0 ] && echo "left→right" || echo "right→left")"
    
    # Apply the effect using ffmpeg
    ffmpeg -y -loop 1 -framerate "$DEFAULT_FRAMERATE" -t "$duration" -i "$input_image" \
        -vf "$kenburns_filter,format=yuv420p" \
        -c:v libx264 -pix_fmt yuv420p "$output_video"
    
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        echo "✅ Custom Ken Burns effect applied successfully"
    else
        echo "❌ Error applying custom Ken Burns effect (exit code: $exit_code)"
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
apply_kenburns_with_pan() {
    local input_image="$1"
    local output_video="$2"
    local duration="$3"
    local pan_direction="$4"
    local zoom_start="${5:-$DEFAULT_ZOOM_START}"
    local zoom_end="${6:-$DEFAULT_ZOOM_END}"
    
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
    
    # Calculate frame count
    local frame_count=$(printf "%.0f" "$(echo "$DEFAULT_FRAMERATE * $duration" | bc -l)")
    
    # Calculate zoom increment with immediate movement
    # Adjust zoom start slightly to ensure immediate pan movement
    local effective_zoom_start=$(echo "$zoom_start * 0.98" | bc -l)
    local zoom_increment=$(echo "($zoom_end - $effective_zoom_start) / $frame_count" | bc -l)
    
    # Determine pan direction with immediate movement
    local pan_x
    if [[ "$pan_direction" == "left" ]]; then
        # Left to right pan - start from left edge immediately
        pan_x="iw*(1-zoom)*on/(in-1)"
    else
        # Right to left pan - start from right edge immediately  
        pan_x="iw*(1-zoom)*(1 - on/(in-1))"
    fi
    
    # Build Ken Burns filter with immediate movement
    # Use effective_zoom_start to ensure movement starts immediately
    local kenburns_filter="zoompan=z='$effective_zoom_start+$zoom_increment*on':x='$pan_x':y=0:d=$frame_count:s=${DEFAULT_WIDTH}x${DEFAULT_HEIGHT},trim=duration=$duration,setpts=PTS-STARTPTS"
    
    echo "🎬 Applying Ken Burns effect: $(basename "$input_image") → $(basename "$output_video") (${duration}s)"
    echo "   Zoom: ${zoom_start} → ${zoom_end}, Pan: ${pan_direction}→$([ "$pan_direction" == "left" ] && echo "right" || echo "left")"
    
    # Apply the effect using ffmpeg
    ffmpeg -y -loop 1 -framerate "$DEFAULT_FRAMERATE" -t "$duration" -i "$input_image" \
        -vf "$kenburns_filter,format=yuv420p" \
        -c:v libx264 -pix_fmt yuv420p "$output_video"
    
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        echo "✅ Ken Burns effect applied successfully"
    else
        echo "❌ Error applying Ken Burns effect (exit code: $exit_code)"
    fi
    
    return $exit_code
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
    
    local frame_count=$(printf "%.0f" "$(echo "$DEFAULT_FRAMERATE * $duration" | bc -l)")
    local zoom_increment=$(echo "($zoom_end - $zoom_start) / $frame_count" | bc -l)
    
    # Calculate effective zoom start for immediate movement
    local effective_zoom_start=$(echo "$zoom_start * 0.98" | bc -l)
    local zoom_increment=$(echo "($zoom_end - $effective_zoom_start) / $frame_count" | bc -l)
    
    local pan_x
    if (( clip_index % 2 == 0 )); then
        pan_x="iw*(1-zoom)*on/(in-1)"
        else
        pan_x="iw*(1-zoom)*(1 - on/(in-1))"
    fi
    
    echo "zoompan=z='$effective_zoom_start+$zoom_increment*on':x='$pan_x':y=0:d=$frame_count:s=${DEFAULT_WIDTH}x${DEFAULT_HEIGHT},trim=duration=$duration,setpts=PTS-STARTPTS"
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