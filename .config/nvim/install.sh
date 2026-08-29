#!/bin/bash

# ================================================================================================
# Neovim Config Installer
# Supports: Arch Linux, Fedora, Debian/Ubuntu
# ================================================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
# Detect if script is being piped (BASH_SOURCE will be /dev/stdin or similar)
if [[ "${BASH_SOURCE[0]}" == "/dev/stdin" ]] || [[ ! -f "${BASH_SOURCE[0]}" ]]; then
	IS_PIPED=true
	NVIM_CONFIG_SOURCE=""
else
	IS_PIPED=false
	NVIM_CONFIG_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
NVIM_CONFIG_DEST="$HOME/.config/nvim"
BACKUP_DIR="$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"

# Repo URL for piped installation
REPO_URL="https://gitlab.com/theblackdon/normie-nvim.git"

# ================================================================================================
# Helper Functions
# ================================================================================================

print_status() {
	echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
	echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
	echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

detect_os() {
	if [[ -f /etc/os-release ]]; then
		. /etc/os-release
		# Check direct ID match first
		case "$ID" in
		arch | manjaro | endeavouros | cachyos)
			echo "arch"
			return
			;;
		fedora | rhel | centos)
			echo "fedora"
			return
			;;
		debian | ubuntu | linuxmint | pop)
			echo "debian"
			return
			;;
		esac

		# Check ID_LIKE for derivative distros
		if [[ -n "$ID_LIKE" ]]; then
			case "$ID_LIKE" in
			*arch*)
				echo "arch"
				return
				;;
			*fedora* | *rhel*)
				echo "fedora"
				return
				;;
			*debian*)
				echo "debian"
				return
				;;
			esac
		fi

		echo "unknown"
	else
		echo "unknown"
	fi
}

# ================================================================================================
# Package Installation Functions
# ================================================================================================

install_packages_arch() {
	print_status "Installing dependencies on Arch Linux..."

	if ! command -v sudo &>/dev/null; then
		print_error "sudo is required but not installed"
		exit 1
	fi

	sudo pacman -Syu --noconfirm || true
	sudo pacman -S --noconfirm --needed \
		neovim \
		git \
		curl \
		tar \
		unzip \
		python \
		python-pip \
		gcc \
		ripgrep \
		fd \
		fzf \
		base-devel \
		2>&1 | grep -v "warning: " || true

	print_success "Arch packages installed"
}

install_packages_fedora() {
	print_status "Installing dependencies on Fedora..."

	if ! command -v sudo &>/dev/null; then
		print_error "sudo is required but not installed"
		exit 1
	fi

	sudo dnf update -y || true
	sudo dnf install -y \
		neovim \
		git \
		curl \
		tar \
		unzip \
		python3 \
		python3-pip \
		gcc \
		gcc-c++ \
		make \
		ripgrep \
		fd-find \
		fzf \
		2>&1 || true

	print_success "Fedora packages installed"
}

install_packages_debian() {
	print_status "Installing dependencies on Debian/Ubuntu..."

	if ! command -v sudo &>/dev/null; then
		print_error "sudo is required but not installed"
		exit 1
	fi

	sudo apt-get update || true
	sudo apt-get install -y \
		neovim \
		git \
		curl \
		tar \
		unzip \
		python3 \
		python3-pip \
		python3-venv \
		gcc \
		g++ \
		make \
		ripgrep \
		fd-find \
		fzf \
		2>&1 || true

	print_success "Debian packages installed"
}

install_packages() {
	local os=$1

	case "$os" in
	arch)
		install_packages_arch
		;;
	fedora)
		install_packages_fedora
		;;
	debian)
		install_packages_debian
		;;
	*)
		print_error "Unsupported OS: $os"
		print_status "Please install dependencies manually:"
		echo "  - neovim"
		echo "  - git"
		echo "  - curl"
		echo "  - python3 + pip"
		echo "  - gcc"
		echo "  - ripgrep"
		echo "  - fd"
		echo "  - fzf"
		exit 1
		;;
	esac
}

# ================================================================================================
# Rust Installation
# ================================================================================================

install_rustup() {
	if command -v rustc &>/dev/null; then
		print_status "Rust already installed: $(rustc --version)"
		return 0
	fi

	print_status "Installing Rust via rustup..."

	# Download and install rustup with minimal profile
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain stable

	# Source cargo environment
	source "$HOME/.cargo/env" 2>/dev/null || true

	if command -v rustc &>/dev/null; then
		print_success "Rust installed: $(rustc --version)"
	else
		print_warning "Rust installation may require restarting your shell"
	fi
}

# ================================================================================================
# Node.js Installation (via nvm)
# ================================================================================================

install_nvm() {
	if [[ -d "$HOME/.nvm" ]]; then
		print_status "nvm already installed"
		return 0
	fi

	print_status "Installing nvm..."

	# Install nvm
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

	# Source nvm
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
	[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

	print_success "nvm installed"
}

install_node() {
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

	if command -v node &>/dev/null; then
		print_status "Node.js already installed: $(node --version)"
		return 0
	fi

	print_status "Installing Node.js LTS..."

	# Install latest LTS
	nvm install --lts
	nvm use --lts
	nvm alias default lts/*

	print_success "Node.js installed: $(node --version)"
}

# ================================================================================================
# Neovim Config Installation
# ================================================================================================

backup_existing_config() {
	if [[ -d "$NVIM_CONFIG_DEST" ]]; then
		print_status "Backing up existing Neovim config to $BACKUP_DIR"
		mv "$NVIM_CONFIG_DEST" "$BACKUP_DIR"
		print_success "Backup created"
	fi
}

install_config() {
	print_status "Installing Neovim configuration..."

	# Remove destination if it exists (backup already handled)
	rm -rf "$NVIM_CONFIG_DEST"

	if [[ "$IS_PIPED" == true ]]; then
		# When piped, clone the repo directly to destination
		print_status "Downloading configuration from repository..."
		git clone --depth 1 "$REPO_URL" "$NVIM_CONFIG_DEST" 2>&1 || {
			print_error "Failed to clone repository"
			exit 1
		}
		# Remove .git directory to keep it clean
		rm -rf "$NVIM_CONFIG_DEST/.git"
	else
		# Validate that source contains actual nvim config files
		if [[ ! -f "$NVIM_CONFIG_SOURCE/init.lua" ]] && [[ ! -d "$NVIM_CONFIG_SOURCE/lua" ]]; then
			print_error "Source directory doesn't appear to contain nvim config files"
			print_status "Expected to find init.lua or lua/ directory in: $NVIM_CONFIG_SOURCE"
			exit 1
		fi
		# Copy config files from local source
		mkdir -p "$(dirname "$NVIM_CONFIG_DEST")"
		cp -r "$NVIM_CONFIG_SOURCE" "$NVIM_CONFIG_DEST"
	fi

	print_success "Configuration installed to $NVIM_CONFIG_DEST"
}

install_plugins() {
	print_status "Installing Neovim plugins (this may take a few minutes)..."
	print_status "Lazy.nvim will download and install all plugins automatically"

	# Run neovim headless to install plugins
	nvim --headless "+Lazy! sync" +qa 2>&1 || {
		print_warning "Plugin installation may have encountered issues"
		print_status "You can manually complete installation by running: nvim"
	}

	print_success "Plugins installed"
}

# ================================================================================================
# Main Installation
# ================================================================================================

main() {
	echo -e "${BLUE}"
	echo "╔════════════════════════════════════════════════════════════╗"
	echo "║         Neovim Configuration Installer                     ║"
	echo "║         Supports: Arch, Fedora, Debian/Ubuntu              ║"
	echo "╚════════════════════════════════════════════════════════════╝"
	echo -e "${NC}"

	# Detect OS
	print_status "Detecting operating system..."
	OS=$(detect_os)
	print_status "Detected: $OS"

	# Install system packages
	install_packages "$OS"

	# Install Rust
	install_rustup

	# Install nvm and Node.js
	install_nvm
	install_node

	# Backup existing config
	backup_existing_config

	# Install nvim config
	install_config

	# Install plugins
	install_plugins

	# Success message
	echo ""
	echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
	echo -e "${GREEN}  Installation Complete!                                    ${NC}"
	echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
	echo ""
	print_status "What's next:"
	echo ""
	echo "  1. Restart your shell or run: source ~/.bashrc"
	echo "     (or source ~/.zshrc if using zsh)"
	echo ""
	echo "  2. Open Neovim: nvim"
	echo ""
	echo "  3. Mason will automatically install LSP servers on first run"
	echo "     You can also run :Mason to manage them manually"
	echo ""
	echo "  4. Start coding! 🚀"
	echo ""

	if [[ -d "$BACKUP_DIR" ]]; then
		print_status "Your old config was backed up to: $BACKUP_DIR"
	fi

	echo ""
	print_status "Useful commands:"
	echo "  :checkhealth   - Verify everything is working"
	echo "  :Mason         - Manage LSP servers/tools"
	echo "  :Lazy          - Manage plugins"
	echo ""
}

# Run main function
main "$@"
