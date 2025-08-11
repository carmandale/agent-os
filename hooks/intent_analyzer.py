#!/usr/bin/env python3
"""
Agent OS Intent Analysis Engine
===============================
Intelligent analysis system that distinguishes between maintenance work
and new development work based on user message content.

Usage:
    from intent_analyzer import IntentAnalyzer, IntentType
    
    analyzer = IntentAnalyzer()
    result = analyzer.analyze_intent("fix the failing tests")
    
    if result.intent_type == IntentType.MAINTENANCE:
        # Allow work with dirty workspace
        pass
    elif result.intent_type == IntentType.NEW_WORK:
        # Require clean workspace
        pass
"""

import os
import re
import time
from dataclasses import dataclass
from enum import Enum
from typing import List, Optional, Dict, Any

# Optional YAML import for configuration
try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False


class IntentType(Enum):
    """Enumeration of work intent types."""
    MAINTENANCE = "maintenance"
    NEW_WORK = "new_work" 
    AMBIGUOUS = "ambiguous"


@dataclass
class WorkIntentResult:
    """Result of intent analysis with detailed information."""
    intent_type: IntentType
    confidence: float
    matched_patterns: List[str]
    reasoning: str
    
    def __str__(self) -> str:
        return f"WorkIntentResult(type={self.intent_type.value}, confidence={self.confidence:.2f})"


def log_debug(message: str) -> None:
    """Write debug logs if debugging enabled."""
    if os.environ.get("AGENT_OS_DEBUG", "").lower() == "true":
        from datetime import datetime
        log_path = os.path.expanduser("~/.agent-os/logs/intent-analyzer-debug.log")
        os.makedirs(os.path.dirname(log_path), exist_ok=True)
        with open(log_path, "a") as f:
            f.write(f"[{datetime.now().isoformat()}] {message}\n")


class IntentAnalyzer:
    """
    Analyzes user messages to determine work intent (maintenance vs new development).
    
    Uses pattern matching with configurable regex patterns to classify user messages.
    Supports confidence scoring and ambiguous intent detection.
    """
    
    def __init__(self, config_path: Optional[str] = None):
        """
        Initialize the IntentAnalyzer.
        
        Args:
            config_path: Optional path to YAML configuration file
        """
        self.config_path = config_path or os.path.expanduser("~/.agent-os/config/workflow-enforcement.yaml")
        
        # Load configuration or use defaults
        self.config = self._load_configuration()
        
        # Extract patterns from configuration
        self.maintenance_patterns = self.config.get('maintenance_patterns', self._get_default_maintenance_patterns())
        self.new_work_patterns = self.config.get('new_work_patterns', self._get_default_new_work_patterns())
        
        # Confidence thresholds
        self.confidence_threshold = self.config.get('confidence_threshold', 0.6)
        self.ambiguous_threshold = self.config.get('ambiguous_threshold', 0.3)
        
        # Compile patterns for performance
        self.compiled_maintenance_patterns = self._compile_patterns(self.maintenance_patterns)
        self.compiled_new_work_patterns = self._compile_patterns(self.new_work_patterns)
        
        log_debug(f"IntentAnalyzer initialized with {len(self.maintenance_patterns)} maintenance patterns, "
                 f"{len(self.new_work_patterns)} new work patterns")
    
    def _load_configuration(self) -> Dict[str, Any]:
        """Load configuration from YAML file with error handling."""
        if not os.path.exists(self.config_path):
            log_debug(f"Configuration file not found at {self.config_path}, using defaults")
            return {}
        
        try:
            with open(self.config_path, 'r') as f:
                config = yaml.safe_load(f)
                log_debug(f"Loaded configuration from {self.config_path}")
                return config or {}
        except Exception as e:
            log_debug(f"Failed to load configuration from {self.config_path}: {e}")
            return {}
    
    def _get_default_maintenance_patterns(self) -> List[str]:
        """Get default maintenance work patterns."""
        return [
            r'\bfix\b.*\btests?\b',
            r'\bfix\b.*\bbug\b',
            r'\bfix\b.*\bissues?\b',
            r'\bfix\b.*\berrors?\b',
            r'\bfix\b.*\bfail',
            r'\bdebug\b',
            r'\bresolve\b.*\bconflicts?\b',
            r'\baddress\b.*\bci\b',
            r'\baddress\b.*\bpipeline\b',
            r'\bupdate\b.*\bdependen',
            r'\brefactor\b(?!.*\bnew\b)',
            r'\bfix\b.*\bstyles?\b',
            r'\bfix\b.*\bbrok',
            r'\bresolve\b.*\berrors?\b',
            r'\bfix\b.*\bperformance\b',
            r'\bfix\b.*\bvalidation\b',
            r'\brepair\b',
            r'\bcorrect\b',
            r'\bmend\b',
            r'\bpatch\b'
        ]
    
    def _get_default_new_work_patterns(self) -> List[str]:
        """Get default new work patterns."""
        return [
            r'\bimplement\b.*\bfeature\b',
            r'\bimplement\b.*\bfunctionality\b',
            r'\bbuild\b.*\bnew\b',
            r'\bcreate\b.*\bfeature\b',
            r'\bcreate\b.*\bcomponent\b',
            r'\bcreate\b.*\bsystem\b',
            r'\bcreate\b.*\binterface\b',
            r'\badd\b.*\bfeature\b',
            r'\badd\b.*\bfunctionality\b',
            r'\badd\b.*\bsystem\b',
            r'\bdevelop\b.*\b(feature|system|interface|component)\b',
            r'\bdesign\b.*\b(feature|system|interface|component)\b',
            r'\bbuild\b.*\b(dashboard|interface|system|feature)\b',
            r'\bimplement\b.*\b(oauth|auth|login|signup)\b',
            r'\bcreate\b.*\b(api|endpoint|service)\b',
            r'\badd\b.*\b(search|notification|integration)\b'
        ]
    
    def _compile_patterns(self, patterns: List[str]) -> List[re.Pattern]:
        """Compile regex patterns for efficient matching."""
        compiled = []
        for pattern in patterns:
            try:
                compiled.append(re.compile(pattern, re.IGNORECASE))
            except re.error as e:
                log_debug(f"Invalid regex pattern '{pattern}': {e}")
                continue
        return compiled
    
    def analyze_intent(self, user_message: str) -> WorkIntentResult:
        """
        Analyze user message to determine work intent.
        
        Args:
            user_message: The user's message describing their work intent
            
        Returns:
            WorkIntentResult with intent type, confidence, and reasoning
        """
        start_time = time.time()
        
        # Input validation and preprocessing
        if not user_message or not user_message.strip():
            return WorkIntentResult(
                intent_type=IntentType.AMBIGUOUS,
                confidence=0.0,
                matched_patterns=[],
                reasoning="Empty or whitespace-only message"
            )
        
        message = user_message.strip().lower()
        log_debug(f"Analyzing intent for message: '{message[:100]}{'...' if len(message) > 100 else ''}'")
        
        # Check for maintenance patterns
        maintenance_matches = self._find_pattern_matches(message, self.compiled_maintenance_patterns)
        maintenance_score = len(maintenance_matches) / max(1, len(self.compiled_maintenance_patterns))
        
        # Check for new work patterns  
        new_work_matches = self._find_pattern_matches(message, self.compiled_new_work_patterns)
        new_work_score = len(new_work_matches) / max(1, len(self.compiled_new_work_patterns))
        
        # Determine intent based on pattern matches
        result = self._determine_intent(
            maintenance_matches, maintenance_score,
            new_work_matches, new_work_score,
            message
        )
        
        analysis_time = time.time() - start_time
        log_debug(f"Intent analysis completed in {analysis_time:.3f}s: {result}")
        
        return result
    
    def _find_pattern_matches(self, message: str, compiled_patterns: List[re.Pattern]) -> List[str]:
        """Find all pattern matches in the message."""
        matches = []
        for pattern in compiled_patterns:
            if pattern.search(message):
                matches.append(pattern.pattern)
        return matches
    
    def _determine_intent(self, maintenance_matches: List[str], maintenance_score: float,
                         new_work_matches: List[str], new_work_score: float,
                         message: str) -> WorkIntentResult:
        """Determine final intent based on pattern analysis."""
        
        # Calculate confidence levels
        maintenance_confidence = min(1.0, maintenance_score * (1 + len(maintenance_matches) * 0.1))
        new_work_confidence = min(1.0, new_work_score * (1 + len(new_work_matches) * 0.1))
        
        # Determine intent type
        if maintenance_confidence > self.confidence_threshold and maintenance_confidence > new_work_confidence:
            return WorkIntentResult(
                intent_type=IntentType.MAINTENANCE,
                confidence=maintenance_confidence,
                matched_patterns=maintenance_matches,
                reasoning=f"Matched {len(maintenance_matches)} maintenance patterns: {', '.join(maintenance_matches[:3])}"
            )
        
        elif new_work_confidence > self.confidence_threshold and new_work_confidence > maintenance_confidence:
            return WorkIntentResult(
                intent_type=IntentType.NEW_WORK,
                confidence=new_work_confidence,
                matched_patterns=new_work_matches,
                reasoning=f"Matched {len(new_work_matches)} new work patterns: {', '.join(new_work_matches[:3])}"
            )
        
        else:
            # Ambiguous intent - either both scores are low, or they're too close together
            max_confidence = max(maintenance_confidence, new_work_confidence)
            confidence_diff = abs(maintenance_confidence - new_work_confidence)
            
            reasoning = "Ambiguous intent: "
            if max_confidence < self.confidence_threshold:
                reasoning += f"low confidence scores (maintenance: {maintenance_confidence:.2f}, new work: {new_work_confidence:.2f})"
            else:
                reasoning += f"similar confidence scores (maintenance: {maintenance_confidence:.2f}, new work: {new_work_confidence:.2f})"
            
            return WorkIntentResult(
                intent_type=IntentType.AMBIGUOUS,
                confidence=max_confidence,
                matched_patterns=maintenance_matches + new_work_matches,
                reasoning=reasoning
            )


def main():
    """Command-line interface for testing the intent analyzer."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Analyze work intent from user messages")
    parser.add_argument("message", help="User message to analyze")
    parser.add_argument("--config", help="Path to configuration file")
    parser.add_argument("--debug", action="store_true", help="Enable debug logging")
    
    args = parser.parse_args()
    
    if args.debug:
        os.environ["AGENT_OS_DEBUG"] = "true"
    
    analyzer = IntentAnalyzer(config_path=args.config)
    result = analyzer.analyze_intent(args.message)
    
    print(f"Intent Type: {result.intent_type.value}")
    print(f"Confidence: {result.confidence:.2f}")
    print(f"Reasoning: {result.reasoning}")
    if result.matched_patterns:
        print(f"Matched Patterns: {', '.join(result.matched_patterns)}")


if __name__ == "__main__":
    main()