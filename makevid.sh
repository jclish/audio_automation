#!/bin/bash

set -e

# Load Ken Burns module
source "$(dirname "$0")/kenburns.sh"

# === CONFIGURATION ===
AUDIO_FILE="$1"
SHUFFLE=false
MEDIA_OVERRIDE=""
VOLUME_MULTIPLIER=3.0  # default volume multiplier
CROSSFADE_DURATION=0.5  # crossfade duration in seconds
CLIP_DURATION=5  # default duration per image clip in seconds
CLIP_VARIATION=0  # default variation percentage

# Parse optional args
for ((i=2; i<=$#; i++)); do
  case "${!i}" in
    --shuffle)
      SHUFFLE=true
      ;;
    --media)
      j=$((i+1))
      MEDIA_OVERRIDE="${!j}"
      ;;
    --volume)
      j=$((i+1))
      VOLUME_MULTIPLIER="${!j}"
      ;;
    --len)
      j=$((i+1))
      CLIP_DURATION="${!j}"
      ;;
    --lenvar)
      j=$((i+1))
      CLIP_VARIATION="${!j}"
      ;;
  esac
done

TMP_DIR="tmp_work"
MEDIA_DIR="${MEDIA_OVERRIDE:-Videos}"
FINAL_VIDEO="video_only.mp4"
FINAL_OUTPUT="output_with_audio.mp4"

# Validate clip duration bounds
if (( $(echo "$CLIP_DURATION < 2" | bc -l) )); then
  echo "❌ Error: Clip duration cannot be less than 2 seconds"
  exit 1
fi
if (( $(echo "$CLIP_DURATION > 10" | bc -l) )); then
  echo "❌ Error: Clip duration cannot be more than 10 seconds"
  exit 1
fi

# Calculate variation bounds
VARIATION_AMOUNT=$(echo "$CLIP_DURATION * $CLIP_VARIATION / 100" | bc -l)
MIN_DURATION=$(echo "$CLIP_DURATION - $VARIATION_AMOUNT" | bc -l)
MAX_DURATION=$(echo "$CLIP_DURATION + $VARIATION_AMOUNT" | bc -l)

# Ensure bounds are within limits
if (( $(echo "$MIN_DURATION < 2" | bc -l) )); then
  MIN_DURATION=2
fi
if (( $(echo "$MAX_DURATION > 10" | bc -l) )); then
  MAX_DURATION=10
fi

echo "\U0001F4CF Clip duration: ${CLIP_DURATION}s ± ${CLIP_VARIATION}% (${MIN_DURATION}s - ${MAX_DURATION}s)"

# === PREPARE ===
echo "\U0001F3AC Preparing workspace..."
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

# === AUDIO LENGTH ===
AUDIO_DURATION=$(ffprobe -i "$AUDIO_FILE" -show_entries format=duration -v quiet -of csv="p=0")
echo "\U0001F50A Audio duration: ${AUDIO_DURATION%.*} seconds"

# === MEDIA LIST ===
shopt -s nullglob
IMAGE_FILES=("$MEDIA_DIR"/*.{jpg,jpeg,JPG,JPEG})
VIDEO_FILES=("$MEDIA_DIR"/*.{mp4,mov})
ALL_MEDIA_FILES=("${IMAGE_FILES[@]}" "${VIDEO_FILES[@]}")
shopt -u nullglob

# Initialize tracking arrays (compatible with older bash versions)
MEDIA_USAGE_COUNT_KEYS=()
MEDIA_USAGE_COUNT_VALUES=()
MEDIA_DURATION_KEYS=()
MEDIA_DURATION_VALUES=()

# Get video durations
for media_file in "${ALL_MEDIA_FILES[@]}"; do
  if [[ "$media_file" =~ \.(mp4|mov)$ ]]; then
    duration=$(ffprobe -i "$media_file" -show_entries format=duration -v quiet -of csv="p=0")
    MEDIA_DURATION_KEYS+=("$media_file")
    MEDIA_DURATION_VALUES+=("$duration")
  fi
done

# Helper function to get usage count
get_usage_count() {
  local media_file="$1"
  for i in "${!MEDIA_USAGE_COUNT_KEYS[@]}"; do
    if [[ "${MEDIA_USAGE_COUNT_KEYS[$i]}" == "$media_file" ]]; then
      echo "${MEDIA_USAGE_COUNT_VALUES[$i]}"
      return 0
    fi
  done
  echo "0"
}

# Helper function to set usage count
set_usage_count() {
  local media_file="$1"
  local count="$2"
  for i in "${!MEDIA_USAGE_COUNT_KEYS[@]}"; do
    if [[ "${MEDIA_USAGE_COUNT_KEYS[$i]}" == "$media_file" ]]; then
      MEDIA_USAGE_COUNT_VALUES[$i]="$count"
      return 0
    fi
  done
  MEDIA_USAGE_COUNT_KEYS+=("$media_file")
  MEDIA_USAGE_COUNT_VALUES+=("$count")
}

# Helper function to get duration
get_duration() {
  local media_file="$1"
  for i in "${!MEDIA_DURATION_KEYS[@]}"; do
    if [[ "${MEDIA_DURATION_KEYS[$i]}" == "$media_file" ]]; then
      echo "${MEDIA_DURATION_VALUES[$i]}"
      return 0
    fi
  done
  echo ""
}

# === SHUFFLE IF REQUESTED ===
if $SHUFFLE; then
  echo "\U0001F3B2 Shuffling media files..."
  shuffle_array() {
    local array=("$@")
    local n=${#array[@]}
    local shuffled=()
    local indices=()
    for i in $(seq 0 $((n-1))); do indices+=($i); done
    for ((i=n-1; i>0; i--)); do
      j=$((RANDOM % (i+1)))
      temp=${indices[i]}
      indices[i]=${indices[j]}
      indices[j]=$temp
    done
    for i in "${indices[@]}"; do shuffled+=("${array[i]}"); done
    echo "${shuffled[@]}"
  }
  ALL_MEDIA_FILES=( $(shuffle_array "${ALL_MEDIA_FILES[@]}") )
fi

NUM_MEDIA=${#ALL_MEDIA_FILES[@]}
if [ "$NUM_MEDIA" -eq 0 ]; then
  echo "❌ No media files found in $MEDIA_DIR."
  exit 1
fi

# === CALCULATE CLIP COUNTS ===
# Estimate total clips needed (will be adjusted based on actual durations)
ESTIMATED_CLIPS=$(echo "$AUDIO_DURATION / $CLIP_DURATION" | bc)
echo "\U0001F3AE Estimating $ESTIMATED_CLIPS clips with variable durations"

# === GENERATE CLIPS ===
WORKING_MEDIA=("${ALL_MEDIA_FILES[@]}")
TOTAL_GENERATED_DURATION=0
CLIP_COUNT=0

while (( $(echo "$TOTAL_GENERATED_DURATION < $AUDIO_DURATION" | bc -l) )); do
  if [ ${#WORKING_MEDIA[@]} -eq 0 ]; then
    WORKING_MEDIA=("${ALL_MEDIA_FILES[@]}")
    if $SHUFFLE; then
      WORKING_MEDIA=( $(shuffle_array "${WORKING_MEDIA[@]}") )
    fi
  fi
  MEDIA_FILE="${WORKING_MEDIA[0]}"
  WORKING_MEDIA=("${WORKING_MEDIA[@]:1}")
  
  # Track usage count
  usage_count=$(get_usage_count "$MEDIA_FILE")
  set_usage_count "$MEDIA_FILE" $((usage_count + 1))
  
  OUT_CLIP="$TMP_DIR/clip_${CLIP_COUNT}.mp4"

  EXT="${MEDIA_FILE##*.}"
  EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')

  # Calculate variable duration using systematic variation (sine wave)
  if [ "$CLIP_VARIATION" -gt 0 ]; then
    # Use sine wave for smooth variation
    SINE_VALUE=$(echo "s($CLIP_COUNT * 0.5)" | bc -l)
    VARIATION_FACTOR=$(echo "$SINE_VALUE * $VARIATION_AMOUNT" | bc -l)
    THIS_DURATION=$(echo "$CLIP_DURATION + $VARIATION_FACTOR" | bc -l)
    
    # Ensure within bounds
    if (( $(echo "$THIS_DURATION < $MIN_DURATION" | bc -l) )); then
      THIS_DURATION="$MIN_DURATION"
    fi
    if (( $(echo "$THIS_DURATION > $MAX_DURATION" | bc -l) )); then
      THIS_DURATION="$MAX_DURATION"
    fi
  else
    THIS_DURATION="$CLIP_DURATION"
  fi

  # Check if this would exceed audio duration
  REMAINING_AUDIO=$(echo "$AUDIO_DURATION - $TOTAL_GENERATED_DURATION" | bc -l)
  if (( $(echo "$THIS_DURATION > $REMAINING_AUDIO" | bc -l) )); then
    THIS_DURATION="$REMAINING_AUDIO"
  fi

  echo "\U0001F39E️ Clip $CLIP_COUNT from: $(basename "$MEDIA_FILE") for ${THIS_DURATION}s"

  if [[ "$EXT_LOWER" =~ ^(jpg|jpeg)$ ]]; then
    apply_kenburns "$MEDIA_FILE" "$OUT_CLIP" "$THIS_DURATION" "$CLIP_COUNT"
  else
    # For videos, calculate different start time based on usage count
    if [[ "$MEDIA_FILE" =~ \.(mp4|mov)$ ]]; then
      total_duration=$(get_duration "$MEDIA_FILE")
      usage_count=$(get_usage_count "$MEDIA_FILE")
      
      if [ -n "$total_duration" ] && (( $(echo "$total_duration > $THIS_DURATION" | bc -l) )); then
        total_segments=$(echo "$total_duration / $THIS_DURATION" | bc)
        segment_index=$(((usage_count - 1) % total_segments))
        start_time=$(echo "$segment_index * $THIS_DURATION" | bc)
        
        # Ensure we don't exceed video duration
        max_start=$(echo "$total_duration - $THIS_DURATION" | bc -l)
        if (( $(echo "$start_time > $max_start" | bc -l) )); then
          start_time=0
        fi
        
        echo "   Using segment $((segment_index + 1))/$total_segments (start: ${start_time}s)"
      else
        start_time=0
      fi
    else
      start_time=0
    fi
    
    ffmpeg -y -ss "$start_time" -t "$THIS_DURATION" -i "$MEDIA_FILE" \
      -vf "fps=25,scale=1280:720,setpts=PTS-STARTPTS,format=yuv420p" \
      -an -c:v libx264 -preset fast -crf 23 "$OUT_CLIP"
  fi

  TOTAL_GENERATED_DURATION=$(echo "$TOTAL_GENERATED_DURATION + $THIS_DURATION" | bc -l)
  CLIP_COUNT=$((CLIP_COUNT + 1))
done

TOTAL_CLIPS=$CLIP_COUNT
echo "\U0001F4DC Generated $TOTAL_CLIPS clips (total duration: ${TOTAL_GENERATED_DURATION}s)"

# === CREATE CROSSFADE VERSION ===
echo "\U0001F4DC Creating crossfade version..."

if [ "$TOTAL_CLIPS" -eq 1 ]; then
  # Single clip, no crossfade needed
  cp "$TMP_DIR/clip_0.mp4" "$FINAL_VIDEO"
else
  # Multiple clips, create crossfade using simpler approach
  echo "\U0001F4FC Creating crossfade video..."
  
  # Create a concat file
  CONCAT_LIST="$TMP_DIR/concat_list.txt"
  > "$CONCAT_LIST"
  
  # Add all clips
  for i in $(seq 0 $((TOTAL_CLIPS - 1))); do
    echo "file 'clip_${i}.mp4'" >> "$CONCAT_LIST"
  done
  
  # Concatenate clips normally (no crossfade for now)
  ffmpeg -y -f concat -safe 0 -i "$CONCAT_LIST" -c:v libx264 -preset fast -crf 23 -pix_fmt yuv420p "$FINAL_VIDEO"
fi

# === COMBINE WITH AUDIO ===
echo "\U0001F517 Merging with audio (volume: ${VOLUME_MULTIPLIER}x)..."
ffmpeg -y -i "$FINAL_VIDEO" -i "$AUDIO_FILE" -filter:a "volume=$VOLUME_MULTIPLIER" -c:v copy -c:a aac -shortest "$FINAL_OUTPUT"

echo "✅ Final video with audio: $FINAL_OUTPUT"


