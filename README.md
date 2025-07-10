# Foobaz Audio Automation Script

This project contains a Bash script that takes a WAV audio file and a directory of images and/or video clips, and produces a synchronized MP4 video where each clip matches the audio length. It includes optional shuffling, a subtle Ken Burns effect for images, and adjustable audio volume.

## Features

- Converts images (JPEG) into video clips with a zoom/pan effect
- Includes `.mov`, `.mp4`, `.mkv`, `.webm`, `.m4v`, `.mpg`, `.mpeg`, `.wmv`, and `.flv` video files seamlessly
- Dynamically matches video duration to audio length
- Optional media shuffling (no media file is reused until all have been used once; shuffling applies to each round)
- When video files are reused, different segments are extracted to maximize variety
- Variable clip durations with systematic variation for natural transitions
- Clean output with progress bars (verbose mode available for debugging)
- Adjustable audio volume boost
- Parallel processing for faster video generation (2-8x speed improvement)
- Compatible with macOS
- Modular Ken Burns effect system
- **Security hardened with input validation and path sanitization**
- **Comprehensive test suite with BATS framework**

## Requirements

- `ffmpeg` and `ffprobe` installed (`brew install ffmpeg` on macOS)
- `bc` for floating-point calculations (usually pre-installed)
- `bats-core` for running tests (optional, for development)

## Installation

### Quick Setup (Recommended)

Run the installation script to automatically set up dependencies:

```bash
./install.sh
```

This script will:
- Detect your operating system
- Install ffmpeg and ffprobe using your system's package manager
- Install bc if needed
- Test the installation

### Manual Installation

#### macOS
```bash
# Using Homebrew (recommended)
brew install ffmpeg

# Or download from https://ffmpeg.org/download.html
```

#### Linux
```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install ffmpeg

# CentOS/RHEL/Fedora
sudo yum install ffmpeg
# or
sudo dnf install ffmpeg

# Arch Linux
sudo pacman -S ffmpeg
```

#### Windows
1. Download from https://ffmpeg.org/download.html
2. Extract to `C:\ffmpeg`
3. Add `C:\ffmpeg\bin` to your PATH environment variable

Alternatively, use package managers:
```bash
# Chocolatey
choco install ffmpeg

# Scoop
scoop install ffmpeg
```

## Testing

The project includes a comprehensive test suite using the BATS framework:

```bash
# Run all tests
bats tests/

# Run specific test suites
bats tests/test_kenburns.bats
bats tests/test_security.bats
bats tests/test_makevid.bats
```

### Test Coverage

- **Ken Burns Effects**: Tests all Ken Burns functions with various parameters
- **Security**: Validates input sanitization, path validation, and secure file operations
- **Core Functionality**: Tests main script functionality and error handling

## Security Features

The script includes comprehensive security measures:

### Input Validation
- Path sanitization to prevent directory traversal attacks
- Input parameter validation with safe defaults
- Secure temporary directory handling
- Command injection prevention

### Security Functions
- `validate_path()`: Ensures paths are safe and accessible
- `sanitize_input()`: Removes dangerous characters from user input
- `secure_cleanup()`: Safely removes temporary files
- `validate_temp_dir()`: Validates temporary directory security

### Security Testing
All security measures are tested with the `test_security.bats` suite, covering:
- Path traversal prevention
- Command injection resistance
- Input sanitization effectiveness
- Secure file operations
- Temporary directory security

## Usage

```bash
bash makevid.sh [audio_file.wav] [--shuffle] [--volume 3.0] [--media media_dir] [--len 5] [--lenvar 10] [--verbose] [--jobs 4]
```

### Arguments

- `audio_file.wav` — Path to the WAV file to use as the soundtrack
- `--shuffle` — (Optional) Randomize media selection order (no repeats until all media used; reshuffles each round)
- `--volume 3.0` — (Optional) Audio volume multiplier (default: 3.0)
- `--media media_dir` — (Optional) Path to directory containing `.jpg`, `.jpeg`, and supported video files (`.mp4`, `.mov`, `.mkv`, `.webm`, `.m4v`, `.mpg`, `.mpeg`, `.wmv`, `.flv`)
- `--len 5` — (Optional) Base clip duration in seconds (default: 5, range: 2-10)
- `--lenvar 10` — (Optional) Clip duration variation percentage (default: 0, range: 0-100)
- `--verbose` — (Optional) Show detailed ffmpeg output for debugging
- `--jobs 4` — (Optional) Number of parallel jobs for faster processing (default: 1, range: 1-8)
- `--kb-zoom-start 1.0` — (Optional) Ken Burns starting zoom level (default: 1.0, range: 0.5-2.0)
- `--kb-zoom-end 1.1` — (Optional) Ken Burns ending zoom level (default: 1.1, range: 0.5-2.0)
- `--kb-pan alternate` — (Optional) Ken Burns pan direction: alternate, left-right, right-left, random (default: alternate)

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

# With parallel processing for faster generation
bash makevid.sh theme.wav --jobs 4 --len 5 --lenvar 15

# High-performance processing with all features
bash makevid.sh theme.wav --jobs 8 --shuffle --volume 3.0 --len 4 --lenvar 20

# Custom Ken Burns effects
bash makevid.sh theme.wav --kb-zoom-start 0.8 --kb-zoom-end 1.3 --kb-pan random
bash makevid.sh theme.wav --kb-zoom-start 1.0 --kb-zoom-end 1.2 --kb-pan left-right
bash makevid.sh theme.wav --kb-zoom-start 0.6 --kb-zoom-end 1.5
```

### Learning Examples

Run the examples script to see all features in action:

```bash
./examples.sh
```

This will show you:
- Basic usage patterns
- Advanced feature combinations
- Troubleshooting tips
- Best practices for different content types
- Professional workflows

## Output

- `video_only.mp4` — The generated video track
- `output_with_audio.mp4` — Final video merged with the audio

## Ken Burns Module

The script uses a modular Ken Burns effect system (`kenburns.sh`) that provides:

- `apply_kenburns()` — Basic Ken Burns effect with alternating pan directions
- `apply_kenburns_custom()` — Custom zoom settings
- `apply_kenburns_with_pan()` — Custom zoom and pan direction
- `get_kenburns_filter()` — Get filter string for advanced usage
- `run_kenburns_ffmpeg()` — Centralized ffmpeg execution with logging

### Ken Burns Parameters

- **Zoom Range**: 0.5-2.0 (0.5 = zoomed out, 2.0 = zoomed in)
- **Pan Modes**:
  - `alternate` (default): Alternates between left→right and right→left
  - `left-right`: All clips pan left to right
  - `right-left`: All clips pan right to left  
  - `random`: Random pan direction for each clip (deterministic based on clip index)

### Ken Burns Examples

```bash
# Dramatic zoom effect
bash makevid.sh audio.wav --kb-zoom-start 0.8 --kb-zoom-end 1.4

# Subtle zoom with consistent direction
bash makevid.sh audio.wav --kb-zoom-start 1.0 --kb-zoom-end 1.2 --kb-pan left-right

# Random pan for variety
bash makevid.sh audio.wav --kb-pan random

# Extreme zoom for dramatic effect
bash makevid.sh audio.wav --kb-zoom-start 0.6 --kb-zoom-end 1.5
```

## Development Notes

- Temporary work files are stored in `tmp_work/`
- Each run clears `tmp_work/` to avoid stale data
- Cross-platform shuffle implementation (works on macOS and Linux)
- Modular design for easy customization
- **Test-Driven Development (TDD) approach with comprehensive test coverage**
- **Security-first design with input validation and sanitization**

## Version History

### v2.0
- Refactored Ken Burns functions for DRY code
- Added comprehensive security features
- Implemented input validation and path sanitization
- Added comprehensive test suite with BATS framework
- Fixed ffmpeg hanging issues in test environment
- Enhanced error handling and logging

### v1.0
- Initial release with core functionality
- Ken Burns effects for images
- Parallel processing support
- Media shuffling and variable durations

## License

MIT or public domain — feel free to adapt and share.

---

Crafted with ❤️ and a cooling breeze from the cold aisle.