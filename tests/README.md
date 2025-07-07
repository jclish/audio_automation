# Audio Automation Test Suite

This directory contains a comprehensive test suite for the audio automation tool using BATS (Bash Automated Testing System).

## Overview

The test suite is organized into several specialized test files:

- **`test_suite.bats`** - Main test suite covering basic functionality, parameter validation, and core features
- **`test_kenburns.bats`** - Tests for Ken Burns effect module functionality
- **`test_resolution.bats`** - Tests for custom resolution and framerate features
- **`test_integration.bats`** - Integration tests for complete workflows and real-world scenarios

## Prerequisites

### Required Dependencies

1. **BATS** - Bash Automated Testing System
   ```bash
   # macOS
   brew install bats-core
   
   # Linux
   sudo apt-get install bats
   
   # Manual installation
   git clone https://github.com/bats-core/bats-core.git
   cd bats-core
   sudo ./install.sh /usr/local
   ```

2. **FFmpeg** - For video processing
   ```bash
   # macOS
   brew install ffmpeg
   
   # Linux
   sudo apt-get install ffmpeg
   ```

3. **ImageMagick** - For image processing
   ```bash
   # macOS
   brew install imagemagick
   
   # Linux
   sudo apt-get install imagemagick
   ```

### Optional Dependencies

- **bc** - For floating-point calculations in tests (usually pre-installed)

## Running Tests

### Quick Start

Run all tests:
```bash
cd tests
./run_tests.sh
```

### Specific Test Categories

Run only Ken Burns tests:
```bash
./run_tests.sh kenburns
```

Run only resolution/framerate tests:
```bash
./run_tests.sh resolution
```

Run only integration tests:
```bash
./run_tests.sh integration
```

### Direct BATS Usage

Run individual test files:
```bash
bats test_suite.bats
bats test_kenburns.bats
bats test_resolution.bats
bats test_integration.bats
```

Run all test files:
```bash
bats *.bats
```

## Test Coverage

### Core Functionality Tests

- **Parameter Validation**: Tests all command-line parameter bounds and validation
- **Basic Operations**: Tests script execution with valid and invalid inputs
- **Output Generation**: Verifies that videos are created with correct properties
- **Error Handling**: Tests graceful handling of missing files and invalid inputs

### Ken Burns Effect Tests

- **Module Loading**: Tests that the Ken Burns module loads correctly
- **Function Availability**: Verifies all Ken Burns functions are defined
- **Parameter Validation**: Tests zoom and pan parameter validation
- **Output Quality**: Verifies Ken Burns effects are applied correctly
- **Edge Cases**: Tests extreme zoom values and different pan directions

### Resolution and Framerate Tests

- **Common Formats**: Tests standard resolutions (1920x1080, 1280x720, etc.)
- **Common Framerates**: Tests standard framerates (24, 25, 30, 60 fps)
- **Parameter Validation**: Tests resolution and framerate bounds
- **Combinations**: Tests resolution and framerate combinations
- **Compatibility**: Verifies output is compatible with common players

### Integration Tests

- **Complete Workflows**: Tests end-to-end scenarios with different audio lengths
- **Real-world Scenarios**: Tests social media formats, cinematic formats, etc.
- **Performance**: Tests parallel processing and resource usage
- **Error Recovery**: Tests graceful handling of missing or corrupted media
- **File Management**: Tests temporary file cleanup and retention

## Test Structure

Each test file follows this structure:

```bash
#!/usr/bin/env bats

setup() {
    # Create test environment
    # Set up test files and directories
}

teardown() {
    # Clean up test environment
    # Remove temporary files
}

@test "test description" {
    # Test implementation
    # Assertions
}
```

## Test Environment

Tests run in isolated temporary directories to prevent interference:

- Each test gets a fresh temporary directory
- Test files are created dynamically (audio, images)
- Scripts and modules are copied to test directory
- Cleanup happens automatically after each test

## Adding New Tests

### Guidelines

1. **Test Naming**: Use descriptive test names that explain what is being tested
2. **Isolation**: Each test should be independent and not rely on other tests
3. **Cleanup**: Always clean up after tests in the `teardown()` function
4. **Assertions**: Use clear assertions that test specific behavior
5. **Documentation**: Add comments explaining complex test logic

### Example Test

```bash
@test "validates custom resolution parameters" {
    run bash makevid.sh test_audio.wav --width 640 --height 480
    [ "$status" -eq 0 ]
    [ -f "output_with_audio.mp4" ]
    
    # Check output resolution
    run ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 output_with_audio.mp4
    [ "$output" = "640,480" ]
}
```

## Troubleshooting

### Common Issues

1. **BATS not found**: Install BATS using the instructions above
2. **FFmpeg not found**: Install FFmpeg for video processing
3. **ImageMagick not found**: Install ImageMagick for image processing
4. **Permission denied**: Make sure test files are executable (`chmod +x tests/*.bats`)

### Debug Mode

Run tests with verbose output:
```bash
bats --verbose *.bats
```

Run a single test:
```bash
bats --filter "test name" test_suite.bats
```

### Test Output

Successful tests show:
```
 ✓ test description
```

Failed tests show:
```
 ✗ test description
   (in test file test_suite.bats, line 123)
     `[ "$status" -eq 0 ]' failed
```

## Continuous Integration

The test suite is designed to work in CI environments:

- Tests are self-contained and don't require external dependencies
- Temporary files are cleaned up automatically
- Exit codes are properly set for CI systems
- Tests can run in parallel (with proper isolation)

## Performance Considerations

- Tests create temporary files and run video processing
- Some tests may take several seconds to complete
- High-resolution tests use more memory and CPU
- Consider running tests on a machine with adequate resources

## Contributing

When adding new features to the main script:

1. Add corresponding tests to the appropriate test file
2. Test both success and failure cases
3. Test edge cases and boundary conditions
4. Update this README if adding new test categories
5. Ensure all tests pass before committing changes 