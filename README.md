# Foobaz Audio Automation Script

This project contains a Bash script that takes a WAV audio file and a directory of images and/or video clips, and produces a synchronized MP4 video where each clip matches the audio length. It includes optional shuffling, a subtle Ken Burns effect for images, and adjustable audio volume.

## Features

- Converts images (JPEG) into video clips with a zoom/pan effect
- Includes `.mov` and `.mp4` video files seamlessly
- Dynamically matches video duration to audio length
- Optional media shuffling
- Adjustable audio volume boost
- Compatible with macOS
- Modular Ken Burns effect system

## Requirements

- `ffmpeg` and `ffprobe` installed (`brew install ffmpeg` on macOS)
- `bc` for floating-point calculations (usually pre-installed)

## Usage

```bash
bash makevid.sh [audio_file.wav] [--shuffle] [--volume 3.0] [--media media_dir]
```

### Arguments

- `audio_file.wav` — Path to the WAV file to use as the soundtrack
- `--shuffle` — (Optional) Randomize media selection order
- `--volume 3.0` — (Optional) Audio volume multiplier (default: 3.0)
- `--media media_dir` — (Optional) Path to directory containing `.jpg`, `.jpeg`, `.mp4`, `.mov` files

### Examples

```bash
# Basic usage with default settings
bash makevid.sh theme.wav

# With shuffled media and custom volume
bash makevid.sh theme.wav --shuffle --volume 2.5

# With custom media directory
bash makevid.sh theme.wav --media "/Users/jclish/Downloads/Podcast Materials/Adobe Stock"

# Full example with all options
bash makevid.sh theme.wav --shuffle --volume 4.0 --media "/path/to/media"
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

