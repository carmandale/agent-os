# Agent OS Release Process

## Overview

Agent OS follows semantic versioning and maintains a structured release process to ensure reliable updates for users.

## Version Numbering

We use [Semantic Versioning](https://semver.org/):
- **MAJOR.MINOR.PATCH** (e.g., 2.0.0)
- **Major**: Breaking changes or architectural updates
- **Minor**: New features, backwards compatible
- **Patch**: Bug fixes and minor improvements

## Release Workflow

### 1. Prepare Release

```bash
# 1. Ensure main branch is clean
git checkout main
git pull origin main
git status  # Should be clean

# 2. Update VERSION file
echo "2.1.0" > VERSION

# 3. Update CHANGELOG.md
# Add new version section with all changes

# 4. Commit version bump
git add VERSION CHANGELOG.md
git commit -m "chore: bump version to 2.1.0"
```

### 2. Create Release Tag

```bash
# Create annotated tag
git tag -a v2.1.0 -m "Release version 2.1.0

Major features:
- Feature 1
- Feature 2

See CHANGELOG.md for details"

# Push tag to GitHub
git push origin v2.1.0
```

### 3. Create GitHub Release

1. Go to https://github.com/carmandale/agent-os/releases
2. Click "Draft a new release"
3. Select the tag you just created
4. Title: "Agent OS v2.1.0"
5. Use the release template format:

```markdown
## 🎯 Highlights
[2-3 sentence summary]

## 📦 What's New
- Feature 1
- Feature 2

## 🔧 Improvements
- Improvement 1
- Improvement 2

## 🐛 Bug Fixes
- Fix 1
- Fix 2

## 🔄 Update Instructions

### For Existing Users
\`\`\`bash
curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup.sh | bash
# Or use: aos update
\`\`\`

### For New Users
\`\`\`bash
curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup.sh | bash
\`\`\`

See [CHANGELOG.md](CHANGELOG.md) for complete details.
```

6. Publish the release

### 4. Update Installation Scripts

After creating a release, ensure the setup script writes the canonical version file (uppercase, no `v` prefix):

```bash
# In setup.sh, add version tracking
echo "2.1.0" > "$HOME/.agent-os/VERSION"
```

### 5. Test Release

```bash
# Test fresh installation
curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup.sh | bash

# Test update from previous version
aos update

# Verify version (canonical)
cat ~/.agent-os/VERSION
```

## Release Checklist

Before each release:

- [ ] All tests passing
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] VERSION file updated
- [ ] No uncommitted changes
- [ ] Tag created and pushed
- [ ] GitHub release published
- [ ] Installation tested
- [ ] Update tested

## Hotfix Process

For urgent fixes:

1. Create hotfix branch from tag
   ```bash
   git checkout -b hotfix/2.0.1 v2.0.0
   ```

2. Make fix and test

3. Update VERSION to 2.0.1

4. Update CHANGELOG.md

5. Merge to main
   ```bash
   git checkout main
   git merge hotfix/2.0.1
   ```

6. Tag and release as normal

## Version History Tracking

Users can check their version:
```bash
# Check installed version (canonical)
cat ~/.agent-os/VERSION

# Check for updates
~/.agent-os/scripts/check-updates.sh

# Or use aos
aos status
```

## Deprecation Policy

- Major version deprecations announced 1 version ahead
- Minor version deprecations announced in release notes
- Deprecated features removed in next major version

## Support Policy

- Latest major version: Full support
- Previous major version: Security fixes only for 6 months
- Older versions: No support

## Communication

- Release notes in GitHub Releases
- Major updates announced in README
- Breaking changes highlighted in release notes
- Migration guides for major version updates