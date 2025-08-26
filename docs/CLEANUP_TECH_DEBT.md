# Agent OS Technical Debt Cleanup

## Problem: Multiple Versioned Files

Having multiple versioned files (v1, v2, v3, etc.) in the codebase is poor practice and creates confusion.

### Issues Identified

#### 1. Workflow Enforcement Hooks (3 versions)
- `hooks/workflow-enforcement-hook.py` (v1)
- `hooks/workflow-enforcement-hook-v2.py` (currently active)
- `hooks/workflow-enforcement-hook-v3.py` (newer but not active?)

**Problems:**
- Unclear which version is active
- Maintenance burden of multiple files
- Confusion for contributors
- Potential for using wrong version

#### 2. AOS CLI Tools (3 versions)
- `tools/aos-improved`
- `tools/aos-v3`  
- `tools/aos-v4` (latest)

**Problems:**
- Multiple versions doing similar things
- Unclear upgrade path
- Wasted space and confusion

## Best Practices Violated

1. **Single Source of Truth**: There should be one authoritative version
2. **Version Control**: Git should handle versioning, not file names
3. **Clear Naming**: File names should describe function, not version
4. **Clean Codebase**: Old code should be removed, not kept alongside

## Recommended Solution

### Immediate Actions

1. **Identify Active Version**
   - Determine which workflow-enforcement-hook is actually in use
   - Confirm aos-v4 is the latest and best version

2. **Consolidate to Single Files**
   ```
   hooks/workflow-enforcement-hook.py (keep only active version)
   tools/aos (keep only v4 content)
   ```

3. **Remove Deprecated Versions**
   - Delete all v1, v2, v3 variants
   - Git history preserves old versions if needed

4. **Update References**
   - Update all configs to point to canonical names
   - Update documentation
   - Update install scripts

### Migration Strategy

1. **Create Backup Branch**
   ```bash
   git checkout -b cleanup/remove-versioned-files
   ```

2. **Rename Active Versions**
   ```bash
   # Keep the best version with the canonical name
   mv tools/aos-v4 tools/aos
   mv hooks/workflow-enforcement-hook-v2.py hooks/workflow-enforcement-hook.py
   ```

3. **Remove Old Versions**
   ```bash
   rm tools/aos-v3 tools/aos-improved
   rm hooks/workflow-enforcement-hook-v2.py hooks/workflow-enforcement-hook-v3.py
   ```

4. **Update All References**
   - Search and replace in all config files
   - Update documentation
   - Test everything still works

## Why This Matters

1. **Maintainability**: Easier to maintain one file than multiple versions
2. **Clarity**: New contributors know exactly which file to modify
3. **Git Integration**: Leverage Git's versioning instead of manual versioning
4. **Professional**: Clean codebases inspire confidence
5. **Reduced Bugs**: No risk of updating wrong version

## Alternative: If Versions Are Needed

If multiple versions truly need to coexist (e.g., for backward compatibility):

1. **Use Feature Flags**
   ```python
   if config.get('hook_version') == 2:
       # v2 behavior
   else:
       # default behavior
   ```

2. **Use Proper Versioning**
   ```
   hooks/workflow-enforcement/
   ├── __init__.py
   ├── v1.py (deprecated, with warning)
   ├── v2.py (current)
   └── v3.py (experimental)
   ```

3. **Clear Documentation**
   - Document why multiple versions exist
   - Provide migration guide
   - Set deprecation timeline

## Conclusion

The current multi-version approach is technical debt that should be addressed. Clean codebases with single, well-named files are easier to maintain and understand. Git provides version history - we don't need to manually version files.