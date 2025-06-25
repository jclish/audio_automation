# Foobaz Audio Automation Script

This project contains a Bash script that takes a WAV audio file and a directory of images and/or video clips, and produces a synchronized MP4 video where each clip matches the audio length. It includes optional shuffling and a subtle Ken Burns effect for images.

## Features

- Converts images (JPEG) into video clips with a zoom/pan effect
- Includes `.mov` and `.mp4` video files seamlessly
- Dynamically matches video duration to audio length
- Optional media shuffling
- Adjustable audio volume boost
- Compatible with macOS

## Requirements

- `ffmpeg` and `ffprobe` installed (`brew install ffmpeg` on macOS)
- Optionally: `coreutils` for `gshuf` (recommended for shuffle):
  ```bash
  brew install coreutils
  ```

## Usage

```bash
bash makevid.sh [audio_file.wav] [--shuffle] [media_dir]
```

### Arguments

- `audio_file.wav` — Path to the WAV file to use as the soundtrack
- `--shuffle` — (Optional) Randomize media selection
- `media_dir` — (Optional) Path to directory containing `.jpg`, `.jpeg`, `.mp4`, `.mov` files

### Example

```bash
bash makevid.sh theme.wav --shuffle "/Users/jclish/Downloads/Podcast Materials/Adobe Stock"
```

## Output

- `video_only.mp4` — The generated video track
- `output_with_audio.mp4` — Final video merged with the audio

## Development Notes

- Temporary work files are stored in `tmp_work/`
- Each run clears `tmp_work/` to avoid stale data

## License

MIT or public domain — feel free to adapt and share.

---

Crafted with ❤️ and a cooling breeze from the cold aisle.

