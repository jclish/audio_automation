#!/bin/bash

# Audio Automation Examples Script
# This script demonstrates the full power of the makevid.sh tool

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "\n${PURPLE}=== $1 ===${NC}"
}

print_example() {
    echo -e "${CYAN}$1${NC}"
}

print_description() {
    echo -e "${BLUE}$1${NC}"
}

print_command() {
    echo -e "${YELLOW}$1${NC}"
}

print_note() {
    echo -e "${GREEN}💡 $1${NC}"
}

print_warning() {
    echo -e "${RED}⚠️  $1${NC}"
}

# Check if makevid.sh exists
if [[ ! -f "makevid.sh" ]]; then
    echo -e "${RED}❌ Error: makevid.sh not found in current directory${NC}"
    echo "Please run this script from the audio_automation directory"
    exit 1
fi

# Check if audio file exists for examples
AUDIO_FILE=""
if [[ -f "example_audio.wav" ]]; then
    AUDIO_FILE="example_audio.wav"
elif [[ -f "*.wav" ]]; then
    AUDIO_FILE=$(ls *.wav | head -n1)
else
    print_warning "No WAV file found for examples. Please place a WAV file in this directory."
    echo "You can use any WAV file for testing the examples."
    echo ""
fi

echo -e "${GREEN}🎬 Audio Automation Examples${NC}"
echo "=================================="
echo ""
echo "This script demonstrates the full power of the makevid.sh tool."
echo "Each example shows different features and use cases."
echo ""

# Example 1: Basic Usage
print_header "Example 1: Basic Usage"
print_description "The simplest way to create a video from audio and media files."
print_command "bash makevid.sh audio_file.wav"
print_note "This uses default settings: 5-second clips, 3x volume boost, clean output"
echo ""

# Example 2: Verbose Output
print_header "Example 2: Verbose Output for Debugging"
print_description "Use --verbose to see detailed ffmpeg output and debug issues."
print_command "bash makevid.sh audio_file.wav --verbose"
print_note "Helpful when troubleshooting or learning how the tool works"
echo ""

# Example 3: Shuffled Media
print_header "Example 3: Shuffled Media Selection"
print_description "Randomize media file order for more variety."
print_command "bash makevid.sh audio_file.wav --shuffle"
print_note "No media file is reused until all others have been used once"
echo ""

# Example 4: Custom Volume
print_header "Example 4: Custom Audio Volume"
print_description "Adjust the volume multiplier for different audio sources."
print_command "bash makevid.sh audio_file.wav --volume 2.0"
print_command "bash makevid.sh audio_file.wav --volume 5.0"
print_note "Default is 3.0x. Use higher values for quiet audio, lower for loud audio"
echo ""

# Example 5: Custom Media Directory
print_header "Example 5: Custom Media Directory"
print_description "Use media files from a different directory."
print_command "bash makevid.sh audio_file.wav --media \"/path/to/your/media\""
print_command "bash makevid.sh audio_file.wav --media \"/Users/jclish/Downloads/Podcast Materials\""
print_note "Supports jpg, jpeg, mp4, mov, mkv, webm, m4v, mpg, mpeg, wmv, flv"
echo ""

# Example 6: Variable Clip Durations
print_header "Example 6: Variable Clip Durations"
print_description "Add natural variation to clip lengths for more dynamic videos."
print_command "bash makevid.sh audio_file.wav --len 4 --lenvar 20"
print_command "bash makevid.sh audio_file.wav --len 6 --lenvar 15"
print_note "Uses sine wave variation for smooth, natural transitions"
print_note "Duration range: 2-10 seconds, variation: 0-100%"
echo ""

# Example 6.5: Parallel Processing
print_header "Example 6.5: Parallel Processing"
print_description "Use multiple CPU cores for faster video generation."
print_command "bash makevid.sh audio_file.wav --jobs 4"
print_command "bash makevid.sh audio_file.wav --jobs 8 --len 5 --lenvar 15"
print_note "2-8x speed improvement on multi-core systems"
print_note "Use --jobs 1 for sequential processing (default)"
print_note "Recommended: 4 jobs for most systems, 8 for high-end machines"
echo ""

# Example 7: Short Clips for Fast-Paced Content
print_header "Example 7: Short Clips for Fast-Paced Content"
print_description "Use shorter clips for energetic or fast-paced audio."
print_command "bash makevid.sh audio_file.wav --len 3 --lenvar 10"
print_note "Good for music, energetic podcasts, or dynamic content"
echo ""

# Example 8: Long Clips for Relaxed Content
print_header "Example 8: Long Clips for Relaxed Content"
print_description "Use longer clips for calm, meditative, or slow-paced content."
print_command "bash makevid.sh audio_file.wav --len 8 --lenvar 5"
print_note "Good for ambient music, meditation, or relaxed narration"
echo ""

# Example 9: Combined Features
print_header "Example 9: Combined Features"
print_description "Combine multiple features for maximum customization."
print_command "bash makevid.sh audio_file.wav --shuffle --volume 4.0 --len 5 --lenvar 25 --verbose"
print_command "bash makevid.sh audio_file.wav --jobs 4 --shuffle --volume 3.0 --len 4 --lenvar 20"
print_note "This example uses all available features together"
echo ""

# Example 10: Different Audio Sources
print_header "Example 10: Different Audio Sources"
print_description "Examples for different types of audio content."
echo ""
print_command "# Podcast with moderate volume"
print_command "bash makevid.sh podcast_episode.wav --volume 2.5 --len 6 --lenvar 15"
echo ""
print_command "# Music with high volume and fast clips"
print_command "bash makevid.sh music_track.wav --volume 1.5 --len 3 --lenvar 30 --shuffle"
echo ""
print_command "# Meditation with low volume and long clips"
print_command "bash makevid.sh meditation.wav --volume 4.0 --len 8 --lenvar 5"
echo ""

# Example 11: Troubleshooting Examples
print_header "Example 11: Troubleshooting"
print_description "Common issues and how to resolve them."
echo ""
print_command "# Check if media files are found"
print_command "ls Videos/"
echo ""
print_command "# Test with verbose output"
print_command "bash makevid.sh audio_file.wav --verbose"
echo ""
print_command "# Check audio file duration"
print_command "ffprobe -i audio_file.wav -show_entries format=duration -v quiet -of csv=\"p=0\""
echo ""

# Example 12: Advanced Usage Patterns
print_header "Example 12: Advanced Usage Patterns"
print_description "Professional workflows and advanced techniques."
echo ""
print_command "# Batch processing multiple audio files"
print_command "for file in *.wav; do"
print_command "  bash makevid.sh \"\$file\" --shuffle --len 5 --lenvar 10"
print_command "done"
echo ""
print_command "# Create different versions of the same audio"
print_command "bash makevid.sh audio.wav --len 4 --lenvar 20 --shuffle"
print_command "bash makevid.sh audio.wav --len 6 --lenvar 5"
print_command "bash makevid.sh audio.wav --len 3 --lenvar 40 --volume 5.0"
echo ""

# Tips and Best Practices
print_header "Tips and Best Practices"
echo ""
print_note "Media File Organization:"
echo "  - Place all media files in the 'Videos' directory"
echo "  - Use high-quality images (1920x1080 or higher)"
echo "  - Video files should be at least 5 seconds long"
echo ""
print_note "Audio Preparation:"
echo "  - Use WAV format for best quality"
echo "  - Normalize audio levels before processing"
echo "  - Remove background noise if possible"
echo ""
print_note "Performance:"
echo "  - Longer audio files take more time to process"
echo "  - More media files provide more variety"
echo "  - Use --verbose for debugging, remove for production"
echo ""

# Feature Summary
print_header "Feature Summary"
echo ""
echo -e "${GREEN}✓ Supported Input Formats:${NC}"
echo "  Audio: WAV"
echo "  Images: JPG, JPEG"
echo "  Video: MP4, MOV, MKV, WEBM, M4V, MPG, MPEG, WMV, FLV"
echo ""
echo -e "${GREEN}✓ Command Line Options:${NC}"
echo "  --shuffle     : Randomize media selection"
echo "  --volume N    : Audio volume multiplier (default: 3.0)"
echo "  --media DIR   : Custom media directory"
echo "  --len N       : Clip duration in seconds (2-10)"
echo "  --lenvar N    : Duration variation percentage (0-100)"
echo "  --verbose     : Show detailed ffmpeg output"
echo "  --jobs N      : Number of parallel jobs (1-8, default: 1)"
echo ""
echo -e "${GREEN}✓ Output:${NC}"
echo "  video_only.mp4        : Video without audio"
echo "  output_with_audio.mp4 : Final video with audio"
echo ""

# Quick Test
if [[ -n "$AUDIO_FILE" ]]; then
    print_header "Quick Test"
    print_description "Test the tool with your audio file:"
    print_command "bash makevid.sh \"$AUDIO_FILE\" --len 4 --lenvar 10"
    echo ""
    print_note "This will create a 4-second clip with 10% variation"
    print_note "Check the output files: video_only.mp4 and output_with_audio.mp4"
    echo ""
fi

print_header "Getting Help"
echo ""
print_command "# Show script help"
print_command "bash makevid.sh"
echo ""
print_command "# Check dependencies"
print_command "./install.sh"
echo ""
print_note "For more information, see README.md"
echo ""

echo -e "${GREEN}🎉 Ready to create amazing videos!${NC}"
echo ""
print_note "Start with the basic example and experiment with different parameters."
print_note "Each combination creates unique, professional-looking videos." 