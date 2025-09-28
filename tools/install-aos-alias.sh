#!/bin/bash

set -euo pipefail

trap 'echo "❌ Agent OS alias installation failed at line $LINENO." >&2' ERR

MARK_START="# BEGIN AGENT_OS_ALIAS"
MARK_END="# END AGENT_OS_ALIAS"
ALIAS_URL="https://raw.githubusercontent.com/carmandale/agent-os/main/tools/agentos-alias.sh"

NON_INTERACTIVE=false
FORCE_CLEANUP=false
DRY_RUN=false
RC_PATH_OVERRIDE=""

usage() {
	cat <<'EOF'
Usage: install-aos-alias.sh [OPTIONS]

Options:
	-y, --non-interactive   Skip prompts and accept defaults.
	--force                 Remove legacy 'aos' definitions without prompting.
	--rc-path FILE          Modify the specified shell rc file instead of auto-detecting.
	--dry-run               Show planned actions without making changes.
	-h, --help              Show this help message and exit.
EOF
}

info()    { printf 'ℹ️  %s\n' "$*"; }
warn()    { printf '⚠️  %s\n' "$*" >&2; }
success() { printf '✅ %s\n' "$*"; }

require_cmd() {
	local cmd="$1"
	local hint="$2"
	if ! command -v "$cmd" >/dev/null 2>&1; then
	warn "Required command '$cmd' not found. $hint"
	exit 1
	fi
}

resolve_rc_path() {
	if [[ -n "$RC_PATH_OVERRIDE" ]]; then
	printf '%s\n' "$RC_PATH_OVERRIDE"
	return 0
	fi

	local shell_name="${SHELL##*/}"
	case "$shell_name" in
	zsh)  printf '%s\n' "$HOME/.zshrc"; return 0 ;;
	bash) printf '%s\n' "$HOME/.bashrc"; return 0 ;;
	fish)
		warn "Detected fish shell. Add 'source ~/.agent-os/tools/agentos-alias.sh' to your fish config manually."
		exit 0
		;;
	esac

	if [[ -f "$HOME/.zshrc" ]]; then
	printf '%s\n' "$HOME/.zshrc"
	elif [[ -f "$HOME/.bashrc" ]]; then
	printf '%s\n' "$HOME/.bashrc"
	else
	printf '%s\n' "$HOME/.zshrc"
	fi
}

legacy_exists() {
	local rc="$1"
	[[ -f "$rc" ]] || return 1
	grep -Eq '\bfunction[[:space:]]+aos[[:space:]]*\(\)' "$rc" 2>/dev/null && return 0
	grep -Eq '\baos[[:space:]]*\(\)[[:space:]]*\{' "$rc" 2>/dev/null && return 0
	grep -Eq 'alias[[:space:]]+aos=' "$rc" 2>/dev/null && return 0
	grep -Eq 'alias[[:space:]]+agentos=' "$rc" 2>/dev/null && return 0
	return 1
}

backup_rc() {
	local rc="$1"
	local backup="${rc}.agentos.bak.$(date +%Y%m%d%H%M%S)"
	cp "$rc" "$backup"
	info "Created backup: $backup"
}

remove_legacy_definitions() {
	local rc="$1"
	local tmp
	tmp=$(mktemp)

	python3 <<'PY' "$rc" "$tmp"
import re
import sys
from pathlib import Path

src = Path(sys.argv[1])
dst = Path(sys.argv[2])

if not src.exists():
	dst.write_text('', encoding='utf-8')
	sys.exit(0)

lines = src.read_text(encoding='utf-8').splitlines()
out = []
skip_block = False
brace_depth = 0
func_pattern = re.compile(r'\s*(function\s+)?aos\s*\(\)\s*\{')
alias_pattern = re.compile(r'\s*alias\s+(aos|agentos)=')

for line in lines:
	stripped = line.lstrip()
	if skip_block:
		brace_depth += stripped.count('{') - stripped.count('}')
		if brace_depth <= 0:
			skip_block = False
		continue
	if func_pattern.match(stripped):
		brace_depth = stripped.count('{') - stripped.count('}')
		if brace_depth > 0:
			skip_block = True
		continue
	if alias_pattern.match(stripped):
		continue
	out.append(line)

dst.write_text('\n'.join(out) + ('\n' if out else ''), encoding='utf-8')
PY

	mv "$tmp" "$rc"
}

ensure_marker_block() {
	local rc="$1"

	if grep -Fq "$MARK_START" "$rc" 2>/dev/null; then
	info "Alias block already present in $rc"
	return 0
    fi

	if [[ "$DRY_RUN" == true ]]; then
	info "[DRY RUN] Would append alias block to $rc"
	return 0
	fi

	if [[ -s "$rc" ]]; then
	local last_char
	last_char=$(tail -c 1 "$rc" 2>/dev/null || printf '')
	if [[ "$last_char" != $'\n' ]]; then
		printf '\n' >> "$rc"
	fi
	fi

	{
	printf '%s\n' "$MARK_START"
	printf 'if [ -f "$HOME/.agent-os/tools/agentos-alias.sh" ]; then\n'
	printf '  source "$HOME/.agent-os/tools/agentos-alias.sh"\n'
	printf 'fi\n'
	printf '%s\n' "$MARK_END"
	} >> "$rc"
	info "Added alias block to $rc"
}

download_alias_file() {
	local dest="$HOME/.agent-os/tools/agentos-alias.sh"

	if [[ "$DRY_RUN" == true ]]; then
	info "[DRY RUN] Would download alias script to $dest"
	return 0
	fi

	mkdir -p "$HOME/.agent-os/tools"
	local tmp
	tmp=$(mktemp)
	if ! curl -fSL --retry 3 --retry-delay 1 -o "$tmp" "$ALIAS_URL"; then
	rm -f "$tmp"
	warn "Failed to download alias script from $ALIAS_URL"
	exit 1
	fi
	mv "$tmp" "$dest"
	chmod +x "$dest" 2>/dev/null || true
	info "Alias script installed to $dest"
}

while [[ $# -gt 0 ]]; do
	case "$1" in
	-y|--non-interactive)
		NON_INTERACTIVE=true
		shift
		;;
	--force)
		FORCE_CLEANUP=true
		shift
		;;
	--rc-path)
		if [[ $# -lt 2 ]]; then
		warn "--rc-path requires a file argument."
		usage
		exit 1
		fi
		RC_PATH_OVERRIDE="$2"
		shift 2
		;;
	--dry-run)
		DRY_RUN=true
		shift
		;;
	-h|--help)
		usage
		exit 0
		;;
	*)
		warn "Unknown option: $1"
		usage
		exit 1
		;;
	esac
done

echo "🚀 Agent OS Alias Installer"
echo "==========================="
echo ""

require_cmd curl "Install curl to download the alias file."
RC_PATH="$(resolve_rc_path)"
info "Using shell configuration: $RC_PATH"

if [[ "$DRY_RUN" == false ]] && [[ ! -f "$RC_PATH" ]]; then
	info "Creating shell configuration file at $RC_PATH"
	mkdir -p "$(dirname "$RC_PATH")"
	touch "$RC_PATH"
fi

if legacy_exists "$RC_PATH"; then
	if [[ "$DRY_RUN" == true ]]; then
	info "[DRY RUN] Legacy 'aos' definitions detected; would remove them."
	else
	require_cmd python3 "Needed to clean up legacy alias definitions."
	if [[ "$FORCE_CLEANUP" == true || "$NON_INTERACTIVE" == true ]]; then
		backup_rc "$RC_PATH"
		info "Removing legacy 'aos' definitions..."
		remove_legacy_definitions "$RC_PATH"
	else
		warn "Legacy 'aos' definitions detected in $RC_PATH."
		read -r -p "Remove legacy definitions and continue? [y/N] " answer
		if [[ "$answer" =~ ^[Yy]$ ]]; then
		backup_rc "$RC_PATH"
		info "Removing legacy 'aos' definitions..."
		remove_legacy_definitions "$RC_PATH"
		else
		warn "Aborting without changes. Re-run with --force to override."
		exit 0
		fi
	fi
	fi
fi

ensure_marker_block "$RC_PATH"
download_alias_file

if [[ "$DRY_RUN" == false ]]; then
	success "Alias installation complete."
	info "Run 'source $RC_PATH' or open a new shell to activate the alias."
else
	info "[DRY RUN] Completed without applying changes."
fi