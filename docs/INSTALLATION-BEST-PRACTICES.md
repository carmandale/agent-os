# Installation Scripts and Package Management Best Practices

> Research compiled: 2025-10-11
> Sources: Official documentation, industry standards, exemplary open-source projects

## Table of Contents

1. [Shell Script Installation Patterns](#shell-script-installation-patterns)
2. [Cross-Platform Compatibility](#cross-platform-compatibility)
3. [Version Management](#version-management)
4. [User Experience](#user-experience)
5. [Documentation Standards](#documentation-standards)
6. [Security Best Practices](#security-best-practices)
7. [Real-World Examples](#real-world-examples)

---

## Shell Script Installation Patterns

### The curl | bash Pattern

**Security Considerations (2025 Standards):**

The `curl | bash` pattern is widely used but has legitimate security concerns:

- **Interrupted Downloads**: Connections can be interrupted, causing partial script execution
- **Unverified Content**: Relies solely on HTTPS security, vulnerable to server/client compromise
- **No Signature Verification**: Unlike package managers (apt, brew), lacks cryptographic verification
- **Trust Requirements**: Requires complete trust in the script source

**Best Practices:**

1. **Download and Inspect First** (Recommended)
```bash
# User downloads first
curl -fsSL https://example.com/install.sh -o install.sh

# User inspects the script
less install.sh
# or
cat install.sh

# User executes after review
bash install.sh
```

2. **Use Proper curl Flags**
```bash
curl -fsSL https://example.com/install.sh | bash
```
- `-f`: Fail silently on HTTP errors (non-2xx/3xx responses)
- `-s`: Silent mode (no progress bar)
- `-S`: Show errors even in silent mode
- `-L`: Follow redirects

3. **Wrap Code in Functions** (Anti-Interruption)
```bash
#!/usr/bin/env bash
# Wrap entire script in a function to prevent partial execution
main() {
	# All installation logic here
	echo "Starting installation..."
	# ... rest of script
}

# Call main function at the end
main "$@"
```

**Source:** [Joyful Bikeshedding - curl Best Practices](https://www.joyfulbikeshedding.com/blog/2020-05-11-best-practices-when-using-curl-in-shell-scripts.html), Security Stack Exchange discussions

---

### Idempotency Techniques

**Definition:** Scripts that can be run multiple times safely, producing the same result each time.

**Core Patterns:**

1. **Directory Creation**
```bash
# Bad: Fails if directory exists
mkdir ~/.myapp

# Good: Creates directory only if needed
mkdir -p ~/.myapp
```

2. **Symbolic Links**
```bash
# Bad: Fails if link exists
ln -s /path/to/source ~/.myapp/link

# Good: Overwrites existing link
ln -sf /path/to/source ~/.myapp/link
```

3. **Binary Installation Checks**
```bash
# Check before installing
if ! command -v myapp &gt; /dev/null; then
	echo "Installing myapp..."
	# Installation logic
else
	echo "myapp already installed, skipping..."
fi
```

4. **Configuration File Management**
```bash
# Check if configuration already present
if ! grep -q "MYAPP_CONFIG" ~/.bashrc; then
	echo 'export MYAPP_CONFIG="$HOME/.myapp"' &gt;&gt; ~/.bashrc
fi
```

5. **Preserve Existing Files**
```bash
# Create backup before overwriting
if [ -f ~/.myapprc ]; then
	cp ~/.myapprc ~/.myapprc.backup.$(date +%Y%m%d_%H%M%S)
fi
```

**Real-World Example (Oh My Zsh):**
- Checks if Oh My Zsh is already installed before proceeding
- Creates timestamped backups: `.zshrc.pre-oh-my-zsh`
- Allows `KEEP_ZSHRC` environment variable to skip overwrite
- Supports re-running installation for updates

**Source:** [How to write idempotent Bash scripts](https://arslan.io/2019/07/03/how-to-write-idempotent-bash-scripts/), [metaist/idempotent-bash](https://github.com/metaist/idempotent-bash)

---

### Error Handling

**Essential Patterns:**

1. **Set Shell Options**
```bash
#!/usr/bin/env bash
set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure
```

**Caution:** `set -e` may be too aggressive for some scripts. Consider selective error checking instead.

2. **Centralized Error Function**
```bash
# Example from Homebrew
abort() {
	printf "%s\n" "$@" &gt;&amp;2
	exit 1
}

# Usage
[ -d "$HOME" ] || abort "HOME directory not found"
```

3. **Trap Handlers**
```bash
cleanup() {
	echo "Cleaning up..."
	# Cleanup logic
}

trap cleanup EXIT
trap 'echo "Error on line $LINENO"' ERR
```

4. **Exit Codes**
```bash
# Use meaningful exit codes
exit 0   # Success
exit 1   # General error
exit 2   # Misuse of shell command
exit 126 # Command cannot execute
exit 127 # Command not found
```

5. **Error Messages**
```bash
# Bad: Silent failure
command_that_might_fail

# Good: Informative error
if ! command_that_might_fail; then
	echo "ERROR: Failed to execute command" &gt;&amp;2
	echo "Try: sudo apt-get install required-package" &gt;&amp;2
	exit 1
fi
```

**Real-World Example (Homebrew):**
- Centralized `abort()` function for consistent error messaging
- Early exit checks for unsupported environments
- Detailed error messages with context and solutions
- Trap mechanisms for cleanup operations

**Source:** [Shell Scripting Best Practices | Cycle.io](https://cycle.io/learn/shell-scripting-best-practices)

---

### Progress Indication

**User Feedback Patterns:**

1. **Color-Coded Output**
```bash
# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}✓ Success${NC}"
echo -e "${YELLOW}⚠ Warning${NC}"
echo -e "${RED}✗ Error${NC}"
```

2. **Informational Functions**
```bash
# Example from Homebrew
ohai() {
	printf "${BLUE}==&gt;${NC} %s\n" "$*"
}

warn() {
	printf "${YELLOW}Warning${NC}: %s\n" "$*" &gt;&amp;2
}

error() {
	printf "${RED}Error${NC}: %s\n" "$*" &gt;&amp;2
}
```

3. **Progress Steps**
```bash
step=1
total_steps=5

progress() {
	echo "[$step/$total_steps] $1"
	((step++))
}

progress "Checking dependencies..."
progress "Downloading files..."
progress "Installing..."
```

4. **Spinners for Long Operations**
```bash
spinner() {
	local pid=$1
	local delay=0.1
	local spinstr='|/-\'
	while ps -p $pid &gt; /dev/null; do
		local temp=${spinstr#?}
		printf " [%c]  " "$spinstr"
		spinstr=$temp${spinstr%"$temp"}
		sleep $delay
		printf "\b\b\b\b\b\b"
	done
	printf "    \b\b\b\b"
}

# Usage
long_running_command &amp;
spinner $!
```

**Real-World Example (NVM):**
- Uses `nvm_echo()` for consistent output formatting
- Provides informative progress messages at each step
- Warns about potential configuration issues
- Gives clear next-step instructions after installation

**Source:** Stack Overflow discussions, Homebrew/NVM/Oh My Zsh source code

---

## Cross-Platform Compatibility

### Shell Selection

**Recommendations for 2025:**

1. **POSIX sh for Maximum Portability**
```bash
#!/bin/sh
# Use only POSIX-compliant features
# No bash-specific features like arrays, [[, etc.
```
- Works on all Unix-like systems
- BSDs rarely have bash installed by default
- Most limited feature set

2. **Bash for Enhanced Features**
```bash
#!/usr/bin/env bash
# Use bash-specific features when needed
# Arrays, extended test syntax, etc.
```
- Most common on Linux
- Available via Homebrew on macOS
- Not guaranteed on minimal installations

3. **Shell Detection Pattern**
```bash
# Detect user's shell
if [ -n "$BASH_VERSION" ]; then
	PROFILE="$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
	PROFILE="$HOME/.zshrc"
else
	PROFILE="$HOME/.profile"
fi
```

**Source:** [Stack Overflow - Which shell for best compatibility](https://stackoverflow.com/questions/23437049/which-shell-should-be-used-for-linux-macos-unix-best-compatibility)

---

### Platform Detection

**Best Practices:**

1. **OS Detection**
```bash
case "$(uname -s)" in
	Darwin*)
		echo "Running on macOS"
		# macOS-specific logic
		;;
	Linux*)
		echo "Running on Linux"
		# Linux-specific logic
		;;
	CYGWIN*|MINGW*|MSYS*)
		echo "Running on Windows"
		# Windows-specific logic
		;;
	*)
		echo "Unknown OS: $(uname -s)"
		exit 1
		;;
esac
```

2. **Architecture Detection**
```bash
ARCH="$(uname -m)"
case "$ARCH" in
	x86_64|amd64)
		echo "64-bit x86 architecture"
		;;
	arm64|aarch64)
		echo "64-bit ARM architecture"
		;;
	*)
		echo "Unsupported architecture: $ARCH"
		exit 1
		;;
esac
```

3. **Feature Detection vs OS Detection**
```bash
# Prefer feature detection
if command -v brew &gt;/dev/null 2&gt;&amp;1; then
	# Use Homebrew
elif command -v apt-get &gt;/dev/null 2&gt;&amp;1; then
	# Use apt
elif command -v yum &gt;/dev/null 2&gt;&amp;1; then
	# Use yum
fi
```

---

### Tool Compatibility

**Common Differences Between macOS and Linux:**

1. **CoreUtils Differences**
```bash
# macOS uses BSD utilities, Linux uses GNU utilities

# sed
# BSD (macOS): sed -i '' 's/old/new/' file
# GNU (Linux):  sed -i 's/old/new/' file

# Solution:
if [[ "$OSTYPE" == "darwin"* ]]; then
	sed -i '' 's/old/new/' file
else
	sed -i 's/old/new/' file
fi
```

2. **Date Command**
```bash
# BSD (macOS): date -r 1234567890
# GNU (Linux):  date -d @1234567890

# Portable solution:
timestamp=$(date +%Y%m%d_%H%M%S)
```

3. **stat Command**
```bash
# BSD (macOS): stat -f%z file
# GNU (Linux):  stat -c%s file

# Use portable alternatives when possible
file_size=$(wc -c &lt; file | tr -d ' ')
```

4. **Install GNU Coreutils on macOS**
```bash
# For scripts that need GNU tools
if [[ "$OSTYPE" == "darwin"* ]]; then
	if ! command -v gsed &gt;/dev/null 2&gt;&amp;1; then
		echo "Installing GNU coreutils..."
		brew install coreutils gnu-sed gnu-tar
	fi
	# Use GNU versions
	alias sed='gsed'
	alias tar='gtar'
fi
```

**Real-World Example (Homebrew):**
- Separate logic paths for macOS and Linux
- Dynamic path and command detection
- Architecture-specific installation paths
- Fallback mechanisms for different system configurations

**Source:** [Apple Developer - Porting Scripts to macOS](https://developer.apple.com/library/archive/documentation/OpenSource/Conceptual/ShellScripting/PortingScriptstoMacOSX/PortingScriptstoMacOSX.html)

---

### Path Handling

**Best Practices:**

1. **Tilde Expansion**
```bash
# Bad: Tilde in quotes doesn't expand
path="~/myapp"

# Good: Use $HOME explicitly
path="$HOME/myapp"
```

2. **Spaces in Paths**
```bash
# Always quote variables with paths
install_dir="$HOME/My App"
mkdir -p "$install_dir"
cp file.txt "$install_dir/file.txt"
```

3. **Relative vs Absolute Paths**
```bash
# Get script directory (absolute path)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &amp;&amp; pwd)"

# Use absolute paths for reliability
CONFIG_DIR="$HOME/.config/myapp"
```

---

## Version Management

### Semantic Versioning

**Standard Format: MAJOR.MINOR.PATCH**

- **MAJOR**: Incompatible API changes
- **MINOR**: Backward-compatible functionality
- **PATCH**: Backward-compatible bug fixes

**Best Practices:**

1. **Version File**
```bash
# Store version in separate file
VERSION_FILE="$HOME/.myapp/VERSION"
echo "1.2.3" &gt; "$VERSION_FILE"

# Read version
INSTALLED_VERSION=$(cat "$VERSION_FILE" 2&gt;/dev/null || echo "0.0.0")
```

2. **Version Comparison**
```bash
version_ge() {
	# Returns true if $1 &gt;= $2
	printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

if version_ge "$INSTALLED_VERSION" "$REQUIRED_VERSION"; then
	echo "Version requirement met"
fi
```

3. **Update Mechanism**
```bash
check_for_updates() {
	local current_version="$1"
	local latest_version=$(curl -fsSL https://api.example.com/version)

	if [ "$current_version" != "$latest_version" ]; then
		echo "Update available: $current_version -&gt; $latest_version"
		return 0
	fi
	return 1
}
```

**Real-World Examples:**

- **rustup**: Manages Rust toolchain versions per project
- **nvm**: Manages Node.js versions with `.nvmrc` files
- **semantic-release**: Automates versioning based on commit messages

**Source:** [Semantic Versioning 2.0.0](https://semver.org/), [semantic-release](https://github.com/semantic-release/semantic-release)

---

### Backward Compatibility

**Migration Strategies:**

1. **Configuration Migration**
```bash
migrate_config() {
	local old_config="$HOME/.myapp.conf"
	local new_config="$HOME/.config/myapp/config"

	if [ -f "$old_config" ] &amp;&amp; [ ! -f "$new_config" ]; then
		echo "Migrating configuration..."
		mkdir -p "$(dirname "$new_config")"
		cp "$old_config" "$new_config"
		mv "$old_config" "$old_config.backup"
	fi
}
```

2. **Version-Specific Updates**
```bash
run_migrations() {
	local from_version="$1"
	local to_version="$2"

	# Run migrations in order
	if version_ge "$to_version" "2.0.0" &amp;&amp; ! version_ge "$from_version" "2.0.0"; then
		migrate_v2
	fi

	if version_ge "$to_version" "3.0.0" &amp;&amp; ! version_ge "$from_version" "3.0.0"; then
		migrate_v3
	fi
}
```

3. **Rollback Support**
```bash
backup_before_update() {
	local backup_dir="$HOME/.myapp/backups/$(date +%Y%m%d_%H%M%S)"
	mkdir -p "$backup_dir"
	cp -r "$HOME/.myapp/config" "$backup_dir/"
	echo "$backup_dir"
}

rollback() {
	local backup_dir="$1"
	echo "Rolling back to backup: $backup_dir"
	cp -r "$backup_dir"/* "$HOME/.myapp/"
}
```

---

### Update Mechanisms

**Common Patterns:**

1. **Self-Update Command**
```bash
# myapp update
update_app() {
	echo "Checking for updates..."
	local script_url="https://example.com/install.sh"

	# Download and verify
	if curl -fsSL "$script_url" -o /tmp/install.sh; then
		# Show what would change
		echo "Update available. Run with --apply to install"
		# Apply update
		bash /tmp/install.sh --update
	fi
}
```

2. **Automatic Update Checks**
```bash
check_update_needed() {
	local last_check_file="$HOME/.myapp/last_check"
	local check_interval=$((7 * 24 * 60 * 60))  # 7 days

	if [ ! -f "$last_check_file" ]; then
		return 0  # Never checked
	fi

	local last_check=$(cat "$last_check_file")
	local now=$(date +%s)

	if [ $((now - last_check)) -gt $check_interval ]; then
		return 0  # Time to check
	fi

	return 1  # Too soon
}
```

3. **Git-Based Updates**
```bash
update_from_git() {
	local install_dir="$HOME/.myapp"

	if [ -d "$install_dir/.git" ]; then
		cd "$install_dir"
		git fetch origin
		git reset --hard origin/main
		echo "Updated to $(git describe --tags)"
	fi
}
```

**Real-World Example (Oh My Zsh):**
- Auto-update tool checks weekly for new versions
- Users can disable automatic updates via configuration
- Manual update via `omz update` command

---

## User Experience

### Clear Messaging

**Best Practices:**

1. **Welcome Messages**
```bash
cat &lt;&lt;EOF
╔══════════════════════════════════════╗
║   MyApp Installer                    ║
║   Version 1.0.0                      ║
╚══════════════════════════════════════╝

This script will install MyApp to your system.

Installation location: $HOME/.myapp
Configuration: $HOME/.config/myapp

Press Enter to continue or Ctrl+C to abort...
EOF
read -r
```

2. **Progress Updates**
```bash
echo "[1/5] Checking system requirements..."
echo "[2/5] Downloading components..."
echo "[3/5] Installing binaries..."
echo "[4/5] Configuring environment..."
echo "[5/5] Running post-install checks..."
```

3. **Completion Messages**
```bash
cat &lt;&lt;EOF

${GREEN}✓ Installation complete!${NC}

To get started:
  1. Restart your shell or run: source ~/.bashrc
  2. Verify installation: myapp --version
  3. View help: myapp --help

Documentation: https://docs.example.com
Report issues: https://github.com/example/myapp/issues

EOF
```

**Real-World Example (Homebrew):**
- Color-coded output with ANSI escape sequences
- `ohai()` for informational messages
- `warn()` for non-fatal warnings
- Interactive prompts with bell sounds

---

### Interactive Prompts

**Best Practices:**

1. **Confirmation Prompts**
```bash
confirm() {
	local prompt="$1"
	local default="${2:-n}"

	if [ "$default" = "y" ]; then
		prompt="$prompt [Y/n]: "
	else
		prompt="$prompt [y/N]: "
	fi

	read -p "$prompt" -n 1 -r
	echo

	if [[ $REPLY =~ ^[Yy]$ ]]; then
		return 0
	fi
	return 1
}

# Usage
if confirm "Install MyApp?"; then
	install_app
fi
```

2. **Non-Interactive Mode**
```bash
# Support both interactive and CI/CD environments
INTERACTIVE=${INTERACTIVE:-true}

prompt_or_default() {
	local prompt="$1"
	local default="$2"

	if [ "$INTERACTIVE" = "false" ]; then
		echo "$default"
		return
	fi

	read -p "$prompt [$default]: " value
	echo "${value:-$default}"
}

install_dir=$(prompt_or_default "Install directory" "$HOME/.myapp")
```

3. **Environment Variable Override**
```bash
# Allow non-interactive installation
# MYAPP_INSTALL_DIR=/opt/myapp bash install.sh

INSTALL_DIR="${MYAPP_INSTALL_DIR:-$HOME/.myapp}"
SKIP_PROMPTS="${MYAPP_SKIP_PROMPTS:-false}"
```

**Real-World Example (Oh My Zsh):**
- Offers interactive prompts with confirmation
- Supports environment variables for automation
- `RUNZSH`, `KEEP_ZSHRC`, `CHSH` variables for customization

---

### Helpful Error Messages

**Best Practices:**

1. **Actionable Errors**
```bash
# Bad
echo "Error: Command failed"

# Good
cat &lt;&lt;EOF
${RED}Error${NC}: Git is not installed

MyApp requires Git for installation.

To install Git:
  • macOS: brew install git
  • Ubuntu/Debian: sudo apt-get install git
  • CentOS/RHEL: sudo yum install git

After installing Git, run this script again.
EOF
```

2. **System Information**
```bash
show_system_info() {
	cat &lt;&lt;EOF
System Information:
  OS: $(uname -s)
  Arch: $(uname -m)
  Shell: $SHELL
  Home: $HOME

This information helps diagnose issues.
EOF
}

# Show on error
trap 'show_system_info' ERR
```

3. **Common Issues Section**
```bash
show_troubleshooting() {
	cat &lt;&lt;EOF

Common Issues:
  1. Permission denied:
     Try: sudo bash install.sh

  2. Command not found after install:
     Add to PATH: export PATH="$HOME/.myapp/bin:\$PATH"

  3. Configuration not loading:
     Restart shell or: source ~/.bashrc

For more help: https://docs.example.com/troubleshooting
EOF
}
```

---

### Post-Install Verification

**Best Practices:**

1. **Verification Steps**
```bash
verify_installation() {
	local errors=0

	echo "Verifying installation..."

	# Check binary exists
	if command -v myapp &gt;/dev/null 2&gt;&amp;1; then
		echo "  ✓ Binary installed"
	else
		echo "  ✗ Binary not found in PATH"
		((errors++))
	fi

	# Check configuration
	if [ -f "$HOME/.config/myapp/config" ]; then
		echo "  ✓ Configuration present"
	else
		echo "  ✗ Configuration missing"
		((errors++))
	fi

	# Check version
	local version=$(myapp --version 2&gt;/dev/null)
	if [ -n "$version" ]; then
		echo "  ✓ Version: $version"
	else
		echo "  ✗ Cannot determine version"
		((errors++))
	fi

	if [ $errors -eq 0 ]; then
		echo -e "\n${GREEN}Installation verified successfully!${NC}"
		return 0
	else
		echo -e "\n${YELLOW}Installation completed with warnings${NC}"
		return 1
	fi
}
```

2. **Health Check Command**
```bash
# myapp doctor
health_check() {
	echo "Running health check..."

	# Check dependencies
	check_dependency() {
		if command -v "$1" &gt;/dev/null 2&gt;&amp;1; then
			echo "  ✓ $1: $(command -v "$1")"
		else
			echo "  ✗ $1: not found"
		fi
	}

	check_dependency git
	check_dependency curl
	check_dependency node

	# Check paths
	echo -e "\nPATH entries:"
	echo "$PATH" | tr ':' '\n' | while read -r p; do
		echo "  - $p"
	done
}
```

---

### Uninstall Procedures

**Best Practices:**

1. **Clean Uninstall Script**
```bash
#!/usr/bin/env bash
# uninstall.sh

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "MyApp Uninstaller"
echo "=================="
echo

if ! confirm "Remove MyApp and all its data?"; then
	echo "Uninstall cancelled"
	exit 0
fi

echo "Removing MyApp..."

# Remove binaries
rm -f "$HOME/.local/bin/myapp"

# Remove configuration
if confirm "Remove configuration? (cannot be undone)"; then
	rm -rf "$HOME/.config/myapp"
	rm -rf "$HOME/.myapp"
fi

# Remove from PATH
for profile in ~/.bashrc ~/.zshrc ~/.profile; do
	if [ -f "$profile" ]; then
		sed -i.backup '/myapp/d' "$profile"
	fi
done

echo -e "\n${GREEN}Uninstall complete${NC}"
echo "Configuration backups saved with .backup extension"
```

2. **Partial Uninstall Options**
```bash
uninstall_menu() {
	cat &lt;&lt;EOF
What would you like to remove?
  1) Binaries only (keep configuration)
  2) Configuration only (keep binaries)
  3) Everything
  4) Cancel

Choice:
EOF
	read -r choice

	case $choice in
		1) remove_binaries ;;
		2) remove_config ;;
		3) remove_everything ;;
		*) echo "Cancelled" ;;
	esac
}
```

---

## Documentation Standards

### Installation Documentation Structure

**Essential Sections:**

1. **Quick Start**
```markdown
# Quick Start

Install MyApp with a single command:

```bash
curl -fsSL https://install.example.com | bash
```

That's it! To verify:

```bash
myapp --version
```
```

2. **Prerequisites**
```markdown
# Prerequisites

Before installing, ensure you have:

- **Operating System**: macOS 10.15+, Ubuntu 18.04+, or Debian 10+
- **Shell**: bash 4.0+ or zsh 5.0+
- **Dependencies**:
  - Git 2.0+
  - curl or wget
  - 50MB free disk space

Check your system:

```bash
git --version
bash --version
```
```

3. **Installation Options**
```markdown
# Installation Methods

## Method 1: Quick Install (Recommended)

```bash
curl -fsSL https://install.example.com | bash
```

## Method 2: Manual Installation

1. Download the installer:
   ```bash
   curl -fsSL https://install.example.com -o install.sh
   ```

2. Review the script:
   ```bash
   less install.sh
   ```

3. Run the installer:
   ```bash
   bash install.sh
   ```

## Method 3: Package Managers

### macOS (Homebrew)
```bash
brew install myapp
```

### Ubuntu/Debian
```bash
sudo apt install myapp
```

### From Source
```bash
git clone https://github.com/example/myapp.git
cd myapp
make install
```
```

4. **Configuration**
```markdown
# Configuration

MyApp can be configured through:

1. **Environment Variables**
   ```bash
   export MYAPP_HOME="$HOME/.myapp"
   export MYAPP_LOG_LEVEL="debug"
   ```

2. **Configuration File** (~/.config/myapp/config.yaml)
   ```yaml
   home: ~/.myapp
   log_level: info
   auto_update: true
   ```

3. **Command-Line Flags**
   ```bash
   myapp --config /custom/path/config.yaml
   ```
```

5. **Troubleshooting**
```markdown
# Troubleshooting

## Common Issues

### "command not found: myapp"

**Cause**: Binary not in PATH

**Solution**:
1. Add to your shell profile:
   ```bash
   echo 'export PATH="$HOME/.myapp/bin:$PATH"' &gt;&gt; ~/.bashrc
   ```
2. Reload your shell:
   ```bash
   source ~/.bashrc
   ```

### "permission denied"

**Cause**: Insufficient permissions

**Solution**:
1. Ensure proper ownership:
   ```bash
   sudo chown -R $USER:$USER ~/.myapp
   ```
2. Or install in user directory (default)

### Installation hangs

**Cause**: Network issues or slow connection

**Solution**:
1. Check internet connection
2. Try manual installation method
3. Use mirror or alternative download source

## Getting Help

- **Documentation**: https://docs.example.com
- **GitHub Issues**: https://github.com/example/myapp/issues
- **Discord**: https://discord.gg/example
- **Email**: support@example.com

When reporting issues, include:
```bash
myapp doctor  # System diagnostic info
```
```

6. **Verification**
```markdown
# Verify Installation

After installation, verify everything works:

```bash
# Check version
myapp --version

# Run health check
myapp doctor

# Test basic functionality
myapp hello
```

Expected output:
```
myapp version 1.0.0
✓ All checks passed
Hello, World!
```
```

7. **Next Steps**
```markdown
# Next Steps

Now that MyApp is installed:

1. **Read the Tutorial**: https://docs.example.com/tutorial
2. **Explore Examples**: `myapp examples`
3. **Join the Community**: https://discord.gg/example
4. **Configure for your workflow**: `myapp config --help`

Quick command reference:
```bash
myapp init      # Initialize new project
myapp run       # Run your project
myapp test      # Run tests
myapp help      # Show help
```
```

---

### README Best Practices

**Structure from Exemplary Projects:**

1. **Title and Badges**
```markdown
# MyApp

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)]()
[![License](https://img.shields.io/badge/license-MIT-green.svg)]()
[![Build](https://img.shields.io/badge/build-passing-brightgreen.svg)]()

> One-line description of what your project does
```

2. **Quick Example**
```markdown
# Quick Example

```bash
# Install
curl -fsSL https://install.example.com | bash

# Use
myapp create my-project
cd my-project
myapp run
```
```

3. **Features Section**
```markdown
# Features

- 🚀 Fast and lightweight
- 📦 Zero dependencies
- 🔧 Highly configurable
- 🌍 Cross-platform (macOS, Linux, Windows)
- 📚 Comprehensive documentation
```

4. **Table of Contents (for longer READMEs)**
```markdown
# Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Configuration](#configuration)
- [Examples](#examples)
- [Contributing](#contributing)
- [License](#license)
```

**Source:** [awesome-readme](https://github.com/matiassingers/awesome-readme), [readme-best-practices](https://github.com/jehna/readme-best-practices), [makeareadme.com](https://www.makeareadme.com/)

---

## Security Best Practices

### Verification and Trust

**Best Practices:**

1. **Checksums**
```bash
# Provide checksums
echo "abc123... install.sh" &gt; install.sh.sha256

# Verify before execution
if echo "abc123...  install.sh" | sha256sum --check --status; then
	bash install.sh
else
	echo "Checksum verification failed!"
	exit 1
fi
```

2. **GPG Signatures**
```bash
# Sign release
gpg --armor --detach-sign install.sh

# Verify
gpg --verify install.sh.asc install.sh
```

3. **HTTPS Only**
```bash
# Always use HTTPS for downloads
curl -fsSL https://example.com/install.sh  # Good
curl -fsSL http://example.com/install.sh   # Bad - insecure
```

4. **Inspect Before Running**
```bash
# Encourage inspection
cat &lt;&lt;EOF
To review this script before running:
  curl -fsSL https://install.example.com -o install.sh
  less install.sh
  bash install.sh
EOF
```

---

### Sensitive Data Handling

**Best Practices:**

1. **No Hardcoded Secrets**
```bash
# Bad
API_KEY="sk-abc123secret"

# Good
API_KEY="${MYAPP_API_KEY:-}"
if [ -z "$API_KEY" ]; then
	echo "Error: MYAPP_API_KEY environment variable required"
	exit 1
fi
```

2. **Secure File Permissions**
```bash
# Create config with restricted permissions
touch ~/.myapp/config
chmod 600 ~/.myapp/config  # Owner read/write only

# Store sensitive data
echo "api_key=$API_KEY" &gt; ~/.myapp/config
```

3. **Avoid Logging Secrets**
```bash
# Bad
set -x  # Debug mode logs all commands including secrets

# Good
set -x
password="secret"
set +x  # Disable debug before sensitive operations
curl -u "user:$password" https://api.example.com
set -x
```

---

### User Permissions

**Best Practices:**

1. **Avoid Unnecessary sudo**
```bash
# Prefer user-level installation
INSTALL_DIR="${HOME}/.local/bin"

# Only require sudo when truly necessary
if [ ! -w "/usr/local/bin" ]; then
	echo "Note: System-wide install requires sudo"
	sudo cp myapp /usr/local/bin/
else
	cp myapp /usr/local/bin/
fi
```

2. **Check Permissions**
```bash
# Verify write permissions
if [ ! -w "$INSTALL_DIR" ]; then
	echo "Error: Cannot write to $INSTALL_DIR"
	echo "Either run with sudo or choose a different directory"
	exit 1
fi
```

3. **Temporary Files**
```bash
# Use secure temporary directory
TMPDIR=$(mktemp -d)
trap "rm -rf '$TMPDIR'" EXIT

# Set restrictive permissions
chmod 700 "$TMPDIR"
```

---

## Real-World Examples

### Homebrew

**GitHub:** https://github.com/Homebrew/install
**Install Script:** https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh

**Key Patterns:**
- **Error Handling**: Centralized `abort()` function for consistent messaging
- **User Feedback**: Color-coded output with ANSI codes, `ohai()` for info messages
- **Platform Detection**: Separate logic for macOS and Linux
- **Interactive**: Prompts for confirmation before making system changes
- **Verification**: Checks system requirements before installation
- **Cleanup**: Trap handlers for cleanup on exit

**Notable Techniques:**
```bash
# Homebrew's abort function
abort() {
	printf "%s\n" "$@" &gt;&amp;2
	exit 1
}

# Platform-specific logic
case "$HOMEBREW_OS" in
	Darwin)
		HOMEBREW_PREFIX="/opt/homebrew"
		;;
	Linux)
		HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
		;;
esac
```

---

### NVM (Node Version Manager)

**GitHub:** https://github.com/nvm-sh/nvm
**Install Script:** https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh

**Key Patterns:**
- **Idempotency**: Checks if NVM already installed, supports updates
- **Shell Detection**: Automatically detects and modifies correct shell profile
- **Feature Detection**: Checks for git, curl, or wget availability
- **Flexible**: Supports installation via git clone or curl
- **Non-Interactive**: Works in CI/CD with environment variables

**Notable Techniques:**
```bash
# NVM's profile detection
nvm_detect_profile() {
	if [ -n "${PROFILE}" ] &amp;&amp; [ -f "${PROFILE}" ]; then
		echo "${PROFILE}"
		return
	fi

	case "${SHELL}" in
		*/bash)
			if [ -f "$HOME/.bashrc" ]; then
				echo "$HOME/.bashrc"
			elif [ -f "$HOME/.bash_profile" ]; then
				echo "$HOME/.bash_profile"
			fi
			;;
		*/zsh)
			echo "$HOME/.zshrc"
			;;
	esac
}
```

---

### Oh My Zsh

**GitHub:** https://github.com/ohmyzsh/ohmyzsh
**Install Script:** https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh

**Key Patterns:**
- **Backup Strategy**: Creates timestamped backups of existing config
- **Interactive**: Prompts for shell change and config overwrite
- **Customizable**: Environment variables control installation behavior
- **Colorful**: Extensive use of color for user feedback
- **Template System**: Provides default `.zshrc` template

**Notable Techniques:**
```bash
# Oh My Zsh's backup strategy
if [ -f ~/.zshrc ]; then
	ZSHRC_BACKUP=~/.zshrc.pre-oh-my-zsh
	if [ -f "$ZSHRC_BACKUP" ]; then
		ZSHRC_BACKUP="$ZSHRC_BACKUP.$(date +%Y%m%d%H%M%S)"
	fi
	mv ~/.zshrc "$ZSHRC_BACKUP"
fi
```

---

### Rustup

**GitHub:** https://github.com/rust-lang/rustup
**Website:** https://rustup.rs

**Key Patterns:**
- **Minimal Installer**: Downloads and runs platform-specific binary
- **Self-Contained**: Manages own updates and component installation
- **Environment Variables**: `CARGO_HOME`, `RUSTUP_HOME` for customization
- **Per-Project**: Supports per-directory toolchain overrides
- **Comprehensive**: Handles multiple architectures and targets

**Notable Techniques:**
```bash
# Rustup's platform detection and binary selection
main() {
	downloader --check
	need_cmd uname

	get_architecture || return 1
	local _arch="$RETVAL"

	local _url="${RUSTUP_UPDATE_ROOT}/dist/${_arch}/rustup-init"

	local _file="$TMPDIR/rustup-init"

	ensure downloader "$_url" "$_file"
	ensure chmod u+x "$_file"
	"$_file" "$@"
}
```

---

### Docker's get-docker.sh

**Script:** https://get.docker.com

**Key Patterns:**
- **Distribution Detection**: Identifies Linux distribution and version
- **Package Manager**: Uses appropriate package manager (apt, yum, etc.)
- **Repository Setup**: Adds Docker's official repository
- **Verification**: Verifies GPG keys before installation
- **Post-Install**: Configures user permissions

**Notable Techniques:**
```bash
# Docker's distro detection
get_distribution() {
	lsb_dist=""
	if [ -r /etc/os-release ]; then
		lsb_dist="$(. /etc/os-release &amp;&amp; echo "$ID")"
	fi
	echo "$lsb_dist"
}
```

---

### Helm's get-helm-3

**Script:** https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

**Key Patterns:**
- **Binary Installation**: Downloads pre-built binary for platform
- **Architecture Detection**: Supports multiple architectures
- **Verification**: Checks checksum of downloaded file
- **Simple**: Minimal dependencies, fast installation
- **Versioning**: Can install specific versions

**Notable Techniques:**
```bash
# Helm's version selection
if [ -z "$DESIRED_VERSION" ]; then
	# Get latest version
	DESIRED_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | grep tag_name | cut -d '"' -f 4)
fi
```

---

## Summary: Top 10 Best Practices

Based on this research, here are the most critical best practices for 2025:

1. **Security First**
   - Use HTTPS exclusively
   - Provide checksums/signatures
   - Encourage script inspection before execution
   - Avoid requiring unnecessary sudo

2. **Idempotent Design**
   - Safe to run multiple times
   - Check existing installations
   - Create backups before overwriting
   - Use `mkdir -p`, `ln -sf`, `command -v` checks

3. **Cross-Platform Compatible**
   - Use POSIX sh or widely available bash
   - Detect platform and adapt behavior
   - Prefer feature detection over OS detection
   - Handle BSD vs GNU tool differences

4. **Clear User Communication**
   - Color-coded output for different message types
   - Progress indicators for long operations
   - Actionable error messages with solutions
   - Welcome and completion summaries

5. **Robust Error Handling**
   - Centralized error functions
   - Early validation of requirements
   - Trap handlers for cleanup
   - Meaningful exit codes

6. **Version Management**
   - Follow semantic versioning
   - Provide update mechanisms
   - Support migration between versions
   - Store version information

7. **Flexible Installation**
   - Support interactive and non-interactive modes
   - Allow customization via environment variables
   - Provide multiple installation methods
   - Respect user's existing configuration

8. **Comprehensive Documentation**
   - Quick start for immediate use
   - Detailed installation options
   - Troubleshooting section
   - Clear next steps after installation

9. **Post-Install Verification**
   - Verify installation success
   - Provide health check command
   - Test basic functionality
   - Show configuration status

10. **Easy Uninstallation**
	- Provide uninstall script
	- Document manual removal steps
	- Create backups before removing config
	- Clean up modified shell profiles

---

## Additional Resources

### Official Documentation

- **Homebrew**: https://docs.brew.sh
- **Rustup**: https://rust-lang.github.io/rustup
- **NVM**: https://github.com/nvm-sh/nvm#readme
- **Oh My Zsh**: https://ohmyz.sh
- **Docker**: https://docs.docker.com/engine/install
- **Helm**: https://helm.sh/docs

### Style Guides and Standards

- **Google Shell Style Guide**: https://google.github.io/styleguide/shellguide.html
- **Bash Best Practices**: https://bertvv.github.io/cheat-sheets/Bash.html
- **POSIX Standard**: https://pubs.opengroup.org/onlinepubs/9699919799

### Tools and Validators

- **ShellCheck**: https://www.shellcheck.net - Shell script static analysis
- **BATS**: https://github.com/bats-core/bats-core - Bash testing framework
- **shfmt**: https://github.com/mvdan/sh - Shell script formatter

### Community Resources

- **awesome-readme**: https://github.com/matiassingers/awesome-readme
- **readme-best-practices**: https://github.com/jehna/readme-best-practices
- **idempotent-bash**: https://github.com/metaist/idempotent-bash

---

*Research compiled from official documentation, industry best practices, and analysis of exemplary open-source projects including Homebrew, NVM, Oh My Zsh, Rustup, Docker, and Helm.*
