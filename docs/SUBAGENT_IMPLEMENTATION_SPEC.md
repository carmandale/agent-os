# Subagent System Implementation Specification (Revised)

> Version: 2.0
> Date: 2025-01-14
> Issue: #25
> Status: Approved with Safety Controls

## Executive Summary

Integration of Builder Methods' Specialized Subagents System with **auto-detection by default**, comprehensive safety controls, and rigorous measurement framework.

## Core Design Principles

### 1. Safe by Default
- **Auto mode** as default (not forced)
- **Security agents** always opt-in only
- **Fail-open** fallback mechanisms
- **Non-destructive** updates

### 2. Measurable Impact
- **Performance budgets** enforced
- **Token usage** tracked and reported
- **Failure rates** categorized
- **Adoption metrics** monitored

### 3. Controlled Rollout
- **Feature flag** gated
- **10% canary** initial deployment
- **Explicit rollback** criteria
- **Snapshot regression** tests

## Feature Flag Configuration

```bash
# Environment variable control
AOS_SUBAGENTS_MODE={off,auto,force}  # Default: auto

# Modes explained:
# - off:   Disable all subagent functionality
# - auto:  Intelligent detection (default)
# - force: Always use subagents when available
```

### Security Agent Controls

```yaml
# subagent-config.yaml
security_agents:
  security-analyzer:
    mode: opt-in  # Never auto-run
    require_confirmation: true
  vulnerability-scanner:
    mode: opt-in
    require_confirmation: true
```

## Performance Requirements

### Detection Latency Budgets

| Percentile | Cold Start | Warm Start | Action if Exceeded |
|------------|------------|------------|-------------------|
| p50        | < 20ms     | < 10ms     | Investigate       |
| p95        | < 100ms    | < 50ms     | Alert + Cache     |
| p99        | < 200ms    | < 100ms    | Fallback to default |

### Caching Strategy

```python
class SubagentDetector:
    def __init__(self):
        self.cache = LRUCache(maxsize=100)
        self.cache_ttl = 300  # 5 minutes
        
    def detect_agent(self, context):
        cache_key = self._compute_cache_key(context)
        if cached := self.cache.get(cache_key):
            return cached  # Warm start
        
        # Cold start detection
        with Timer() as t:
            agent = self._detect_agent_impl(context)
        
        if t.elapsed_ms > 100:  # p95 budget
            log.warning(f"Slow detection: {t.elapsed_ms}ms")
            
        self.cache.set(cache_key, agent, ttl=self.cache_ttl)
        return agent
```

## CLI Enhancements

### Extended `aos status`

```bash
$ aos status

Agent OS Status Report
======================
...existing output...

Subagents
---------
Mode:          auto (default)
Available:     5/5 agents detected
Last Detection: 12ms (cached)
Recent:        git-workflow (3m ago), test-runner (15m ago)
Feature Flag:  enabled (canary group A)
```

### New `aos doctor` Command

```bash
$ aos doctor

Agent OS Health Check
=====================
✅ Hooks installed correctly
✅ Subagents detected: 5/5
⚠️  Performance: p95 detection at 95ms (budget: 100ms)
✅ Configuration valid
✅ Upstream compatibility: aligned with v1.3.1

Suggestions:
- Consider enabling result caching for better performance
- Run 'aos update --sync-content' for latest improvements
```

## Benchmark Framework

### Test Suite Structure

```yaml
# benchmarks/suite.yaml
repositories:
  - name: small-react-app
    size: 100_files
    tasks:
      - create-component
      - fix-test
      - refactor-module
      
  - name: large-monorepo
    size: 10000_files
    tasks:
      - navigate-codebase
      - update-dependency
      - implement-feature

metrics:
  - token_usage_delta
  - workflow_failure_rate
  - detection_latency
  - end_to_end_time
```

### Weekly Metrics Report

```markdown
## Week 3 Subagent Metrics

### Token Usage
- Baseline: 45,230 tokens/task (avg)
- With Subagents: 32,410 tokens/task
- **Reduction: -28.3%** ✅ (Target: -25%)

### Workflow Failures
- Missing Tests: -45% ✅
- Hygiene Issues: -32% ✅
- Git Mistakes: -28% ⚠️
- **Overall: -35%** ✅ (Target: -30%)

### Performance
- p50 Detection: 15ms ✅ (Budget: 20ms)
- p95 Detection: 87ms ✅ (Budget: 100ms)
- Cache Hit Rate: 73%

### Adoption
- Canary Group: 10% → 25% (expanded)
- Fallback Triggers: 0.3% of requests
- Opt-outs: 2 users (investigating)
```

## Upstream Alignment Strategy

### Compatibility Preset

```yaml
# upstream-compat.yaml
version: buildermethods-v1.3.1
agent_mappings:
  context-fetcher: context-fetcher-v1
  date-checker: date-checker-v1
  file-creator: file-creator-v1
  git-workflow: git-workflow-v1
  test-runner: test-runner-v1
  
heuristics:
  use_upstream_detection: true
  preserve_role_names: true
```

### Update Synchronization

```bash
# Pull upstream improvements with review
$ aos update --sync-content

Upstream changes available:
- Updated git-workflow patterns (+15 new patterns)
- Improved context-fetcher performance
- New date-checker timezone handling

Preview changes? [Y/n]: y
[Shows diff]

Apply changes? [y/N]: y
✅ Updated 3 agents from upstream
```

## Telemetry & Privacy

### Data Collection Policy

```yaml
telemetry:
  enabled: true  # Default, with opt-out
  retention: 30_days
  
  collected:
    - agent_invocations: count only
    - token_deltas: aggregated
    - detection_timings: p50/p95/p99
    - feature_flag_state: mode only
    
  never_collected:
    - user_messages
    - file_contents
    - repository_names
    
  opt_out:
    environment: AOS_TELEMETRY=off
    config: ~/.agent-os/config/telemetry.yaml
```

### Privacy Controls

```bash
# View collected metrics
$ aos metrics --show

# Export personal data
$ aos metrics --export > my-metrics.json

# Opt out
$ aos config set telemetry.enabled false
```

## Rollback Criteria

### Automatic Rollback Triggers

1. **Performance Degradation**
   - p95 detection > 150ms for 5 minutes
   - End-to-end latency +20% sustained

2. **Error Rate Increase**
   - Workflow failures +10% over baseline
   - Fallback triggers > 5% of requests

3. **User Impact**
   - Opt-out rate > 5% of users
   - Critical bug reports > 3

### Manual Rollback

```bash
# Emergency rollback
$ aos config set subagents.mode off
$ aos restart
✅ Subagents disabled globally

# Gradual rollback
$ aos config set subagents.canary_percent 5
✅ Reduced canary to 5% of users
```

## Acceptance Criteria Checklist

- [ ] Feature flag `AOS_SUBAGENTS_MODE` implemented with default `auto`
- [ ] Security subagents marked opt-in only
- [ ] `aos status` shows Subagents section
- [ ] `aos doctor` validates environment
- [ ] Performance budgets enforced (p50 < 20ms, p95 < 100ms)
- [ ] Benchmark suite operational with weekly reporting
- [ ] Token usage reduction measured and reported
- [ ] Workflow failure categorization implemented
- [ ] Snapshot regression tests passing
- [ ] Upstream compatibility preset available
- [ ] Telemetry with opt-out implemented
- [ ] 10% canary rollout successful
- [ ] Rollback criteria defined and tested
- [ ] Non-destructive update mechanism working
- [ ] Fail-open fallback operational

## Implementation Timeline

### Week 1: Foundation
- Port 5 subagents with upstream alignment
- Implement feature flag system
- Create detection with caching
- Add telemetry framework

### Week 2: Safety & Monitoring
- Pre-flight warnings system
- Performance measurement
- `aos doctor` command
- Snapshot regression tests

### Week 3: Integration
- Instruction reorganization
- Non-destructive updates
- Upstream sync mechanism
- Benchmark suite

### Week 4: Rollout
- 10% canary deployment
- Metrics collection
- Performance optimization
- Gradual expansion based on KPIs

---

*This specification prioritizes safety, measurability, and controlled deployment while maintaining the goal of significant improvement in AI-assisted development workflows.*