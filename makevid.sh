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
  esac
done

TMP_DIR="tmp_work"
MEDIA_DIR="${MEDIA_OVERRIDE:-Videos}"
CLIP_DURATION=5  # default duration per image clip in seconds
FINAL_VIDEO="video_only.mp4"
FINAL_OUTPUT="output_with_audio.mp4"

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

# Initialize tracking arrays
declare -A MEDIA_USAGE_COUNT
declare -A MEDIA_DURATION

# Get video durations
for media_file in "${ALL_MEDIA_FILES[@]}"; do
  if [[ "$media_file" =~ \.(mp4|mov)$ ]]; then
    MEDIA_DURATION["$media_file"]=$(ffprobe -i "$media_file" -show_entries format=duration -v quiet -of csv="p=0")
  fi
done

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
FULL_CLIPS=$(echo "$AUDIO_DURATION / $CLIP_DURATION" | bc)
PARTIAL_REMAINDER=$(echo "$AUDIO_DURATION - ($FULL_CLIPS * $CLIP_DURATION)" | bc)

TOTAL_CLIPS=$FULL_CLIPS
if (( $(echo "$PARTIAL_REMAINDER > 0.1" | bc -l) )); then
  TOTAL_CLIPS=$((FULL_CLIPS + 1))
fi

echo "\U0001F3AE Generating $TOTAL_CLIPS clips with ${CROSSFADE_DURATION}s crossfades"

# === GENERATE CLIPS ===
WORKING_MEDIA=("${ALL_MEDIA_FILES[@]}")
for i in $(seq 0 $((TOTAL_CLIPS - 1))); do
  if [ ${#WORKING_MEDIA[@]} -eq 0 ]; then
    WORKING_MEDIA=("${ALL_MEDIA_FILES[@]}")
    if $SHUFFLE; then
      WORKING_MEDIA=( $(shuffle_array "${WORKING_MEDIA[@]}") )
    fi
  fi
  MEDIA_FILE="${WORKING_MEDIA[0]}"
  WORKING_MEDIA=("${WORKING_MEDIA[@]:1}")
  
  # Track usage count
  MEDIA_USAGE_COUNT["$MEDIA_FILE"]=$((MEDIA_USAGE_COUNT["$MEDIA_FILE"] + 1))
  
  OUT_CLIP="$TMP_DIR/clip_${i}.mp4"

  EXT="${MEDIA_FILE##*.}"
  EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')

  if [ "$i" -eq $((TOTAL_CLIPS - 1)) ] && (( $(echo "$PARTIAL_REMAINDER > 0.1" | bc -l) )); then
    THIS_DURATION="$PARTIAL_REMAINDER"
  else
    THIS_DURATION="$CLIP_DURATION"
  fi

  echo "\U0001F39E️ Clip $i from: $(basename "$MEDIA_FILE") for $THIS_DURATION sec"

  if [[ "$EXT_LOWER" =~ ^(jpg|jpeg)$ ]]; then
    apply_kenburns "$MEDIA_FILE" "$OUT_CLIP" "$THIS_DURATION" "$i"
  else
    # For videos, calculate different start time based on usage count
    if [[ "$MEDIA_FILE" =~ \.(mp4|mov)$ ]]; then
      total_duration=${MEDIA_DURATION["$MEDIA_FILE"]}
      usage_count=${MEDIA_USAGE_COUNT["$MEDIA_FILE"]}
      
      if [ -n "$total_duration" ] && (( $(echo "$total_duration > 5" | bc -l) )); then
        total_segments=$(echo "$total_duration / 5" | bc)
        segment_index=$(((usage_count - 1) % total_segments))
        start_time=$(echo "$segment_index * 5" | bc)
        
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

done

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


