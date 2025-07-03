# Foobaz Audio Automation Script

This project contains a Bash script that takes a WAV audio file and a directory of images and/or video clips, and produces a synchronized MP4 video where each clip matches the audio length. It includes optional shuffling, a subtle Ken Burns effect for images, and adjustable audio volume.

## Features

- Converts images (JPEG) into video clips with a zoom/pan effect
- Includes `.mov` and `.mp4` video files seamlessly
- Dynamically matches video duration to audio length
- Optional media shuffling (no media file is reused until all have been used once; shuffling applies to each round)
- When video files are reused, different segments are extracted to maximize variety
- Variable clip durations with systematic variation for natural transitions
- Clean output with progress bars (verbose mode available for debugging)
- Adjustable audio volume boost
- Compatible with macOS
- Modular Ken Burns effect system

## Requirements

- `ffmpeg` and `ffprobe` installed (`brew install ffmpeg` on macOS)
- `bc` for floating-point calculations (usually pre-installed)

## Usage

```bash
bash makevid.sh [audio_file.wav] [--shuffle] [--volume 3.0] [--media media_dir] [--len 5] [--lenvar 10] [--verbose]
```

### Arguments

- `audio_file.wav` — Path to the WAV file to use as the soundtrack
- `--shuffle` — (Optional) Randomize media selection order (no repeats until all media used; reshuffles each round)
- `--volume 3.0` — (Optional) Audio volume multiplier (default: 3.0)
- `--media media_dir` — (Optional) Path to directory containing `.jpg`, `.jpeg`, `.mp4`, `.mov` files
- `--len 5` — (Optional) Base clip duration in seconds (default: 5, range: 2-10)
- `--lenvar 10` — (Optional) Clip duration variation percentage (default: 0, range: 0-100)
- `--verbose` — (Optional) Show detailed ffmpeg output for debugging

### Examples

```bash
# Basic usage with default settings (clean output)
bash makevid.sh theme.wav

# With verbose output for debugging
bash makevid.sh theme.wav --verbose

# With shuffled media and custom volume
bash makevid.sh theme.wav --shuffle --volume 2.5

# With variable clip durations (5s ± 15%)
bash makevid.sh theme.wav --len 5 --lenvar 15

# With custom media directory and variable durations
bash makevid.sh theme.wav --media "/Users/jclish/Downloads/Podcast Materials/Adobe Stock" --len 6 --lenvar 10

# Full example with all options
bash makevid.sh theme.wav --shuffle --volume 4.0 --media "/path/to/media" --len 4 --lenvar 20 --verbose
```

## Output

- `video_only.mp4` — The generated video track
- `output_with_audio.mp4` — Final video merged with the audio

## Ken Burns Module

The script uses a modular Ken Burns effect system (`kenburns.sh`) that provides:

- `apply_kenburns()` — Basic Ken Burns effect with alternating pan directions
- `apply_kenburns_custom()` — Custom zoom settings
- `get_kenburns_filter()` — Get filter string for advanced usage

## Development Notes

- Temporary work files are stored in `tmp_work/`
- Each run clears `tmp_work/` to avoid stale data
- Cross-platform shuffle implementation (works on macOS and Linux)
- Modular design for easy customization

## License

MIT or public domain — feel free to adapt and share.

---

Crafted with ❤️ and a cooling breeze from the cold aisle.

