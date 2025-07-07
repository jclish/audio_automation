#!/bin/bash

# Audio Automation Test Runner
# Runs the comprehensive test suite for the audio automation tool

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if BATS is installed
check_bats() {
    if ! command -v bats >/dev/null 2>&1; then
        print_error "BATS is not installed. Please install it first:"
        echo "  macOS: brew install bats-core"
        echo "  Linux: sudo apt-get install bats"
        echo "  Or: git clone https://github.com/bats-core/bats-core.git && cd bats-core && sudo ./install.sh /usr/local"
        exit 1
    fi
    print_success "BATS is available"
}

# Check dependencies
check_dependencies() {
    print_header "Checking Dependencies"
    
    local missing_deps=()
    
    if ! command -v ffmpeg >/dev/null 2>&1; then
        missing_deps+=("ffmpeg")
    fi
    
    if ! command -v convert >/dev/null 2>&1; then
        missing_deps+=("ImageMagick")
    fi
    
    if [ ${#missing_deps[@]} -eq 0 ]; then
        print_success "All dependencies are available"
    else
        print_warning "Missing dependencies: ${missing_deps[*]}"
        echo "Some tests may fail. Install missing dependencies for full test coverage."
    fi
}

# Run all tests
run_all_tests() {
    print_header "Running All Tests"
    
    local test_files=(
        "test_suite.bats"
        "test_kenburns.bats"
        "test_resolution.bats"
        "test_integration.bats"
    )
    
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    
    for test_file in "${test_files[@]}"; do
        if [ -f "$test_file" ]; then
            print_header "Running $test_file"
            if bats "$test_file"; then
                print_success "$test_file passed"
                ((passed_tests++))
            else
                print_error "$test_file failed"
                ((failed_tests++))
            fi
            ((total_tests++))
        fi
    done
    
    print_header "Test Summary"
    echo "Total test files: $total_tests"
    echo "Passed: $passed_tests"
    echo "Failed: $failed_tests"
    
    if [ $failed_tests -eq 0 ]; then
        print_success "All tests passed!"
        exit 0
    else
        print_error "Some tests failed"
        exit 1
    fi
}

# Run specific test category
run_category() {
    local category="$1"
    local test_file="test_${category}.bats"
    
    if [ ! -f "$test_file" ]; then
        print_error "Test file $test_file not found"
        exit 1
    fi
    
    print_header "Running $category tests"
    bats "$test_file"
}

# Show help
show_help() {
    echo "Audio Automation Test Runner"
    echo "==========================="
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  all                    Run all tests (default)"
    echo "  kenburns              Run Ken Burns effect tests"
    echo "  resolution            Run resolution/framerate tests"
    echo "  integration           Run integration tests"
    echo "  help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run all tests"
    echo "  $0 kenburns          # Run only Ken Burns tests"
    echo "  $0 resolution        # Run only resolution tests"
}

# Main execution
main() {
    local action="${1:-all}"
    
    case "$action" in
        "help"|"-h"|"--help")
            show_help
            exit 0
            ;;
        "all")
            check_bats
            check_dependencies
            run_all_tests
            ;;
        "kenburns"|"resolution"|"integration")
            check_bats
            check_dependencies
            run_category "$action"
            ;;
        *)
            print_error "Unknown action: $action"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 