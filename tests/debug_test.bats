#!/usr/bin/env bats

setup() {
    # Create test directories and files
    export TEST_DIR="$(mktemp -d)"
    export ORIGINAL_DIR="$(pwd)"
    cd "$TEST_DIR"
    
    # Create test image
    convert -size 100x100 xc:red test_image.jpg 2>/dev/null || true
    
    # Determine project root (parent of tests directory)
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    # Copy the Ken Burns module
    cp "$PROJECT_ROOT/kenburns.sh" .
}

teardown() {
    # Clean up test directory
    cd "$ORIGINAL_DIR"
    rm -rf "$TEST_DIR"
}

# @test "debug: apply_kenburns in BATS environment" {
#     echo "DEBUG: Current directory: $(pwd)"
#     echo "DEBUG: Files in directory: $(ls -la)"
#     echo "DEBUG: kenburns.sh exists: $(test -f kenburns.sh && echo "YES" || echo "NO")"
#     
#     # Try the exact command that's hanging
#     run timeout 30 bash -c "source kenburns.sh && apply_kenburns test_image.jpg output.mp4 2"
#     echo "DEBUG: Command exit status: $status"
#     echo "DEBUG: Command output: $output"
#     
#     # For now, just check if it doesn't hang
#     [ "$status" -ne 124 ]  # 124 is timeout
# }

@test "get_kenburns_filter returns valid filter string for default params" {
    source kenburns.sh
    run get_kenburns_filter 2
    [ "$status" -eq 0 ]
    [[ "$output" =~ "zoompan" ]]
    [[ "$output" =~ "trim" ]]
}

@test "get_kenburns_filter returns valid filter string for custom zoom and index" {
    source kenburns.sh
    run get_kenburns_filter 3 1 0.8 1.2
    [ "$status" -eq 0 ]
    [[ "$output" =~ "zoompan" ]]
    [[ "$output" =~ "trim" ]]
    [[ "$output" =~ "0.8" ]]
    [[ "$output" =~ "1.2" ]]
}

@test "get_kenburns_filter returns error for missing duration" {
    source kenburns.sh
    run get_kenburns_filter
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error: Duration is required" ]]
}

@test "get_kenburns_filter handles edge case: zero duration" {
    source kenburns.sh
    run get_kenburns_filter 0
    [ "$status" -eq 0 ]
    [[ "$output" =~ "zoompan" ]]
}

@test "get_kenburns_filter handles negative duration" {
    source kenburns.sh
    run get_kenburns_filter -2
    [ "$status" -eq 0 ]
    [[ "$output" =~ "zoompan" ]]
}

# The following tests are commented out to keep debug_test.bats focused on get_kenburns_filter logic only.
# @test "apply_kenburns errors on missing parameters" { ... }
# @test "apply_kenburns errors on nonexistent input file" { ... }
# @test "apply_kenburns_custom errors on missing parameters" { ... }
# @test "apply_kenburns_custom errors on nonexistent input file" { ... }
# @test "apply_kenburns_with_pan errors on missing parameters" { ... }
# @test "apply_kenburns_with_pan errors on nonexistent input file" { ... }
# @test "apply_kenburns_with_pan errors on invalid pan direction" { ... } 