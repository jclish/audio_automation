# TODO List

## Completed ✅

- [x] Modularize Ken Burns effect into reusable `kenburns.sh` module
- [x] Avoid reusing media files until all others have been used once
- [x] Extract different 5-second clips from video files when reusing them
- [x] Add command line option to vary clip length by percentage with systematic variation
- [x] Suppress verbose ffmpeg output and show clean progress bar with --verbose flag
- [x] Fix final video missing last 3 seconds of audio by improving final clip duration calculation
- [x] Replace Unicode escape sequences with actual emoji characters for better terminal compatibility
- [x] Create installation script (`install.sh`) to help users set up dependencies

## Planned 🔄

- [ ] Add support for more video formats (currently limited to mp4, mov, avi)
- [ ] Implement parallel processing for faster video generation
- [ ] Add option to specify custom Ken Burns effect parameters
- [ ] Create a GUI wrapper for easier usage
- [ ] Add support for audio fade in/out effects
- [ ] Implement video quality presets (low, medium, high)
- [ ] Add option to preserve original aspect ratio of images
- [ ] Create a configuration file for default settings