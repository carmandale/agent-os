# Installation Scripts Best Practices - Research Summary

> Compiled: 2025-10-11
> Full Documentation: [INSTALLATION-BEST-PRACTICES.md](./INSTALLATION-BEST-PRACTICES.md)

## Quick Reference Guide

This document provides a quick overview of the comprehensive research findings. For detailed examples and implementation guidance, see the full documentation.

---

## Key Findings by Category

### 1. Shell Script Installation Patterns

**curl | bash Security (Critical)**

The widely-used `curl | bash` pattern has legitimate risks:
- **Interrupted downloads** can cause partial execution
- **No cryptographic verification** unlike package managers
- **Requires complete trust** in the script source

**Recommended Mitigations:**
```bash
# Best: Download and inspect first
curl -fsSL https://example.com/install.sh -o install.sh
less install.sh  # Review
bash install.sh  # Execute

# Essential: Wrap in functions to prevent partial execution
main() {
	# All installation logic here
}
main "$@"  # Call at end

# Always: Use proper curl flags
curl -fsSL  # -f: fail on errors, -s: silent, -S: show errors, -L: follow redirects
```

**Sources:**
- Security Stack Exchange discussions
- [Joyful Bikeshedding - curl Best Practices](https://www.joyfulbikeshedding.com/blog/2020-05-11-best-practices-when-using-curl-in-shell-scripts.html)

---

### 2. Idempotency (Must-Have)

Scripts must be safely re-runnable. Key patterns:

```bash
# Directory creation
mkdir -p ~/.myapp  # Never fails if exists

# Symbolic links
ln -sf /source ~/.myapp/link  # Overwrites existing

# Check before installing
if ! command -v myapp &gt;/dev/null; then
	install_myapp
fi

# Check before modifying config
if ! grep -q "MYAPP_CONFIG" ~/.bashrc; then
	echo 'export MYAPP_CONFIG="$HOME/.myapp"' &gt;&gt; ~/.bashrc
fi
```

**Real-World Examples:**
- **Oh My Zsh**: Creates timestamped backups (`.zshrc.pre-oh-my-zsh`)
- **NVM**: Checks existing installation, supports updates
- **Homebrew**: Validates directory permissions before modification

**Source:** [How to write idempotent Bash scripts](https://arslan.io/2019/07/03/how-to-write-idempotent-bash-scripts/)

---

### 3. Cross-Platform Compatibility

**Shell Selection for 2025:**
- **POSIX sh** (`#!/bin/sh`): Maximum portability, works everywhere, limited features
- **Bash** (`#!/usr/bin/env bash`): Enhanced features, common on Linux, available via Homebrew on macOS

**Critical Differences:**

```bash
# CoreUtils - macOS (BSD) vs Linux (GNU)
# sed
if [[ "$OSTYPE" == "darwin"* ]]; then
	sed -i '' 's/old/new/' file  # macOS
else
	sed -i 's/old/new/' file     # Linux
fi

# Platform detection
case "$(uname -s)" in
	Darwin*) echo "macOS" ;;
	Linux*)  echo "Linux" ;;
	*)       echo "Unsupported: $(uname -s)"; exit 1 ;;
esac
```

**Best Practice:** Prefer feature detection over OS detection
```bash
if command -v brew &gt;/dev/null 2&gt;&amp;1; then
	# Use Homebrew
elif command -v apt-get &gt;/dev/null 2&gt;&amp;1; then
	# Use apt
fi
```

**Sources:**
- [Apple Developer - Porting Scripts to macOS](https://developer.apple.com/library/archive/documentation/OpenSource/Conceptual/ShellScripting/PortingScriptstoMacOSX/PortingScriptstoMacOSX.html)
- Stack Overflow discussions on cross-platform scripting

---

### 4. Error Handling (Essential)

**Centralized Error Function:**
```bash
# Homebrew pattern
abort() {
	printf "%s\n" "$@" &gt;&amp;2
	exit 1
}

[ -d "$HOME" ] || abort "HOME directory not found"
```

**Trap Handlers:**
```bash
cleanup() {
	echo "Cleaning up temporary files..."
	rm -rf "$TMPDIR"
}

trap cleanup EXIT
trap 'echo "Error on line $LINENO"' ERR
```

**Actionable Error Messages:**
```bash
# Bad
echo "Error: Command failed"

# Good
cat &lt;&lt;EOF
Error: Git is not installed

MyApp requires Git for installation.

To install Git:
  • macOS: brew install git
  • Ubuntu/Debian: sudo apt-get install git
  • CentOS/RHEL: sudo yum install git

After installing Git, run this script again.
EOF
```

---

### 5. User Experience

**Progress Indication:**
```bash
# Color-coded output (Homebrew pattern)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}✓ Success${NC}"
echo -e "${YELLOW}⚠ Warning${NC}"
echo -e "${RED}✗ Error${NC}"

# Progress steps
echo "[1/5] Checking system requirements..."
echo "[2/5] Downloading components..."
# ...
```

**Interactive Prompts:**
```bash
confirm() {
	read -p "$1 [y/N]: " -n 1 -r
	echo
	[[ $REPLY =~ ^[Yy]$ ]]
}

if confirm "Install MyApp?"; then
	install_app
fi
```

**Non-Interactive Mode:**
```bash
# Support CI/CD
SKIP_PROMPTS="${MYAPP_SKIP_PROMPTS:-false}"

if [ "$SKIP_PROMPTS" = "true" ]; then
	install_dir="$HOME/.myapp"
else
	read -p "Install directory [$HOME/.myapp]: " install_dir
	install_dir="${install_dir:-$HOME/.myapp}"
fi
```

---

### 6. Version Management

**Semantic Versioning (MAJOR.MINOR.PATCH):**
```bash
# Store version
echo "1.2.3" &gt; "$HOME/.myapp/VERSION"

# Version comparison
version_ge() {
	printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

if version_ge "$INSTALLED_VERSION" "$REQUIRED_VERSION"; then
	echo "Version requirement met"
fi
```

**Update Mechanisms:**
```bash
# Self-update command
update_app() {
	echo "Checking for updates..."
	curl -fsSL https://example.com/install.sh -o /tmp/install.sh
	bash /tmp/install.sh --update
}

# Automatic update checks (weekly)
check_update_needed() {
	local last_check_file="$HOME/.myapp/last_check"
	local check_interval=$((7 * 24 * 60 * 60))  # 7 days

	if [ ! -f "$last_check_file" ]; then
		return 0  # Never checked
	fi

	local last_check=$(cat "$last_check_file")
	local now=$(date +%s)

	[ $((now - last_check)) -gt $check_interval ]
}
```

**Source:** [Semantic Versioning 2.0.0](https://semver.org/)

---

### 7. Documentation Standards

**README Installation Section:**

```markdown
# Installation

## Quick Start

```bash
curl -fsSL https://install.example.com | bash
```

## Prerequisites

- macOS 10.15+ / Ubuntu 18.04+ / Debian 10+
- bash 4.0+ or zsh 5.0+
- Git 2.0+

## Manual Installation

1. Download:
   ```bash
   curl -fsSL https://install.example.com -o install.sh
   ```

2. Review:
   ```bash
   less install.sh
   ```

3. Install:
   ```bash
   bash install.sh
   ```

## Verify

```bash
myapp --version
myapp doctor  # Health check
```

## Troubleshooting

### "command not found: myapp"

Add to PATH:
```bash
echo 'export PATH="$HOME/.myapp/bin:$PATH"' &gt;&gt; ~/.bashrc
source ~/.bashrc
```

### More help

- Docs: https://docs.example.com
- Issues: https://github.com/example/myapp/issues
```

**Sources:**
- [awesome-readme](https://github.com/matiassingers/awesome-readme)
- [readme-best-practices](https://github.com/jehna/readme-best-practices)
- [makeareadme.com](https://www.makeareadme.com/)

---

### 8. Security Best Practices

**Essential Security Measures:**

```bash
# 1. HTTPS Only
curl -fsSL https://example.com/install.sh  # Good
curl -fsSL http://example.com/install.sh   # Bad - insecure

# 2. Checksums
echo "abc123... install.sh" &gt; install.sh.sha256
sha256sum --check install.sh.sha256 || exit 1

# 3. No Hardcoded Secrets
API_KEY="${MYAPP_API_KEY:-}"
[ -z "$API_KEY" ] &amp;&amp; abort "MYAPP_API_KEY required"

# 4. Secure File Permissions
touch ~/.myapp/config
chmod 600 ~/.myapp/config  # Owner read/write only

# 5. Avoid Unnecessary sudo
INSTALL_DIR="${HOME}/.local/bin"  # User-level install
```

---

## Top 10 Implementation Priorities

Based on research of exemplary projects (Homebrew, NVM, Oh My Zsh, Rustup, Docker, Helm):

1. **Idempotent Design** - Safe to re-run, checks existing state
2. **Clear Error Messages** - Actionable errors with solutions
3. **Cross-Platform** - Works on macOS and Linux
4. **Progress Feedback** - Color-coded, step-by-step updates
5. **Security First** - HTTPS, checksums, inspection encouraged
6. **Non-Interactive Mode** - Works in CI/CD with env vars
7. **Verification** - Post-install checks and health command
8. **Documentation** - Clear prerequisites, troubleshooting, examples
9. **Version Management** - Semantic versioning, update mechanism
10. **Clean Uninstall** - Documented removal with backup preservation

---

## Exemplary Open-Source Projects

### Analyzed Installation Scripts

**Homebrew** ([install.sh](https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh))
- Centralized error handling with `abort()` function
- Color-coded user feedback
- Platform-specific logic for macOS and Linux
- Interactive prompts with confirmation

**NVM** ([install.sh](https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh))
- Automatic shell profile detection
- Idempotent installation with update support
- Flexible installation methods (git or script)
- Environment variable customization

**Oh My Zsh** ([install.sh](https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh))
- Timestamped backup strategy
- Interactive prompts for customization
- Template-based configuration
- Environment variables for automation

**Rustup** ([rustup.rs](https://rustup.rs))
- Minimal installer downloads platform binary
- Self-contained update management
- Per-project toolchain overrides
- Environment variable customization

**Docker** ([get-docker.sh](https://get.docker.com))
- Distribution detection and package manager selection
- GPG key verification
- Repository setup automation

**Helm** ([get-helm-3](https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3))
- Binary installation with checksum verification
- Architecture detection
- Version selection support

---

## Key Research Sources

### Official Documentation
- Homebrew: https://docs.brew.sh
- Rustup: https://rust-lang.github.io/rustup
- NVM: https://github.com/nvm-sh/nvm#readme
- Docker: https://docs.docker.com/engine/install
- Helm: https://helm.sh/docs

### Best Practice Guides
- [How to write idempotent Bash scripts](https://arslan.io/2019/07/03/how-to-write-idempotent-bash-scripts/)
- [Best practices when using curl in shell scripts](https://www.joyfulbikeshedding.com/blog/2020-05-11-best-practices-when-using-curl-in-shell-scripts.html)
- [Apple Developer - Porting Scripts to macOS](https://developer.apple.com/library/archive/documentation/OpenSource/Conceptual/ShellScripting/PortingScriptstoMacOSX/PortingScriptstoMacOSX.html)
- [Semantic Versioning 2.0.0](https://semver.org/)

### Community Resources
- Security Stack Exchange: curl | bash security discussions
- Stack Overflow: Cross-platform scripting, shell compatibility
- GitHub: awesome-readme, readme-best-practices, idempotent-bash

### Tools
- **ShellCheck**: https://www.shellcheck.net - Static analysis
- **BATS**: https://github.com/bats-core/bats-core - Testing
- **shfmt**: https://github.com/mvdan/sh - Formatting

---

## Implementation Checklist

Use this checklist when creating or reviewing installation scripts:

### Security
- [ ] Use HTTPS exclusively for downloads
- [ ] Provide checksums or GPG signatures
- [ ] Encourage script inspection before execution
- [ ] Avoid hardcoded secrets
- [ ] Minimize sudo requirements
- [ ] Set secure file permissions (600/700)

### Reliability
- [ ] Idempotent design (safe to re-run)
- [ ] Check existing installations
- [ ] Create backups before overwriting
- [ ] Centralized error handling
- [ ] Cleanup on failure (trap handlers)
- [ ] Meaningful exit codes

### Compatibility
- [ ] Works on macOS and Linux
- [ ] Platform/architecture detection
- [ ] Handle BSD vs GNU tool differences
- [ ] Feature detection over OS detection
- [ ] POSIX sh or widely available bash

### User Experience
- [ ] Welcome message with overview
- [ ] Color-coded progress indicators
- [ ] Clear step-by-step feedback
- [ ] Interactive prompts (with defaults)
- [ ] Non-interactive mode support
- [ ] Actionable error messages
- [ ] Completion summary with next steps

### Documentation
- [ ] Prerequisites clearly listed
- [ ] Multiple installation methods
- [ ] Quick start example
- [ ] Verification steps
- [ ] Troubleshooting section
- [ ] Uninstall instructions

### Post-Install
- [ ] Verify installation success
- [ ] Test basic functionality
- [ ] Provide health check command
- [ ] Show configuration location
- [ ] Display next steps

### Version Management
- [ ] Semantic versioning
- [ ] Version file/command
- [ ] Update mechanism
- [ ] Migration support

---

## Quick Start: Minimal Installation Script Template

```bash
#!/usr/bin/env bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Error handling
abort() {
	echo -e "${RED}Error:${NC} $*" &gt;&amp;2
	exit 1
}

# Progress messages
info() {
	echo -e "${GREEN}==&gt;${NC} $*"
}

warn() {
	echo -e "${YELLOW}Warning:${NC} $*"
}

# Main installation function
main() {
	info "Installing MyApp..."

	# Check prerequisites
	command -v git &gt;/dev/null || abort "Git is required"

	# Platform detection
	case "$(uname -s)" in
		Darwin*) PLATFORM="macos" ;;
		Linux*)  PLATFORM="linux" ;;
		*)       abort "Unsupported platform: $(uname -s)" ;;
	esac

	# Installation directory
	INSTALL_DIR="${MYAPP_HOME:-$HOME/.myapp}"

	# Idempotent directory creation
	mkdir -p "$INSTALL_DIR/bin"

	# Install files
	info "Installing to $INSTALL_DIR..."
	# ... installation logic ...

	# Configure PATH
	if ! grep -q "$INSTALL_DIR/bin" ~/.bashrc 2&gt;/dev/null; then
		echo "export PATH=\"$INSTALL_DIR/bin:\$PATH\"" &gt;&gt; ~/.bashrc
	fi

	# Verify
	if command -v myapp &gt;/dev/null 2&gt;&amp;1; then
		info "Installation complete!"
		echo "Run: source ~/.bashrc"
	else
		warn "Installation completed but myapp not found in PATH"
	fi
}

# Run main function
main "$@"
```

---

## Conclusion

The research reveals that successful installation scripts share common patterns:

1. **Security** is non-negotiable (HTTPS, verification, inspection)
2. **Idempotency** prevents repeated installation failures
3. **Cross-platform** support requires explicit handling of differences
4. **User experience** depends on clear communication and feedback
5. **Error handling** must be actionable and informative
6. **Documentation** is as important as the script itself

These patterns are consistently implemented across industry-leading projects like Homebrew, NVM, Rustup, and Docker, making them battle-tested best practices for 2025.

For detailed implementation examples and comprehensive guidance, see [INSTALLATION-BEST-PRACTICES.md](./INSTALLATION-BEST-PRACTICES.md).
