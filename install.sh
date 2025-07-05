#!/bin/bash

# Audio Automation Installation Script
# This script helps users set up the required dependencies

set -e

echo "🎬 Audio Automation - Dependency Installation"
echo "============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Function to install ffmpeg on macOS
install_ffmpeg_macos() {
    print_status $BLUE "Installing ffmpeg on macOS..."
    
    if command_exists brew; then
        print_status $YELLOW "Using Homebrew to install ffmpeg..."
        brew install ffmpeg
    else
        print_status $RED "Homebrew not found. Please install Homebrew first:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        echo ""
        print_status $YELLOW "Then run this script again."
        exit 1
    fi
}

# Function to install ffmpeg on Linux
install_ffmpeg_linux() {
    print_status $BLUE "Installing ffmpeg on Linux..."
    
    if command_exists apt-get; then
        print_status $YELLOW "Using apt-get to install ffmpeg..."
        sudo apt-get update
        sudo apt-get install -y ffmpeg
    elif command_exists yum; then
        print_status $YELLOW "Using yum to install ffmpeg..."
        sudo yum install -y ffmpeg
    elif command_exists dnf; then
        print_status $YELLOW "Using dnf to install ffmpeg..."
        sudo dnf install -y ffmpeg
    elif command_exists pacman; then
        print_status $YELLOW "Using pacman to install ffmpeg..."
        sudo pacman -S ffmpeg
    else
        print_status $RED "Could not detect package manager. Please install ffmpeg manually:"
        echo "  Visit: https://ffmpeg.org/download.html"
        exit 1
    fi
}

# Function to install ffmpeg on Windows
install_ffmpeg_windows() {
    print_status $BLUE "Installing ffmpeg on Windows..."
    print_status $YELLOW "Please download and install ffmpeg manually:"
    echo "  1. Visit: https://ffmpeg.org/download.html"
    echo "  2. Download the Windows build"
    echo "  3. Extract to C:\\ffmpeg"
    echo "  4. Add C:\\ffmpeg\\bin to your PATH environment variable"
    echo ""
    print_status $YELLOW "Alternatively, you can use Chocolatey:"
    echo "  choco install ffmpeg"
    echo ""
    print_status $YELLOW "Or use Scoop:"
    echo "  scoop install ffmpeg"
}

# Function to check and install bc
install_bc() {
    if ! command_exists bc; then
        print_status $YELLOW "bc not found. Installing..."
        
        case $(detect_os) in
            "macos")
                if command_exists brew; then
                    brew install bc
                else
                    print_status $RED "Please install bc manually or install Homebrew first."
                fi
                ;;
            "linux")
                if command_exists apt-get; then
                    sudo apt-get install -y bc
                elif command_exists yum; then
                    sudo yum install -y bc
                elif command_exists dnf; then
                    sudo dnf install -y bc
                elif command_exists pacman; then
                    sudo pacman -S bc
                else
                    print_status $RED "Please install bc manually."
                fi
                ;;
            "windows")
                print_status $YELLOW "bc is usually pre-installed on Windows. If not, please install manually."
                ;;
        esac
    else
        print_status $GREEN "✓ bc is already installed"
    fi
}

# Main installation process
main() {
    print_status $BLUE "Checking dependencies..."
    echo ""
    
    # Check OS
    OS=$(detect_os)
    print_status $BLUE "Detected OS: $OS"
    echo ""
    
    # Check and install ffmpeg
    if command_exists ffmpeg; then
        print_status $GREEN "✓ ffmpeg is already installed"
        FFMPEG_VERSION=$(ffmpeg -version | head -n1)
        print_status $BLUE "  Version: $FFMPEG_VERSION"
    else
        print_status $YELLOW "✗ ffmpeg not found"
        case $OS in
            "macos")
                install_ffmpeg_macos
                ;;
            "linux")
                install_ffmpeg_linux
                ;;
            "windows")
                install_ffmpeg_windows
                exit 0
                ;;
            *)
                print_status $RED "Unsupported OS: $OS"
                exit 1
                ;;
        esac
    fi
    
    # Check and install ffprobe
    if command_exists ffprobe; then
        print_status $GREEN "✓ ffprobe is already installed"
    else
        print_status $YELLOW "✗ ffprobe not found"
        print_status $BLUE "ffprobe should be installed with ffmpeg. If not, please install ffmpeg manually."
    fi
    
    # Check and install bc
    install_bc
    
    echo ""
    print_status $GREEN "🎉 Installation complete!"
    echo ""
    print_status $BLUE "You can now use the audio automation script:"
    echo "  bash makevid.sh [audio_file.wav] [options]"
    echo ""
    print_status $BLUE "For help and examples, see README.md"
    echo ""
    
    # Test the installation
    print_status $YELLOW "Testing installation..."
    if command_exists ffmpeg && command_exists ffprobe && command_exists bc; then
        print_status $GREEN "✓ All dependencies are working correctly!"
    else
        print_status $RED "✗ Some dependencies are still missing. Please check the installation."
        exit 1
    fi
}

# Run the installation
main "$@" 