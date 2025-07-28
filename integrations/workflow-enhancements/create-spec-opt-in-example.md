# Example: Opt-In Enhancement Integration

This shows how the enhanced create-spec workflow would look with the new opt-in philosophy.

## Step 2.5: Optional Enhancement Detection and Suggestions

```xml
<step number="2.5" name="optional_enhancement_suggestions">

### Step 2.5: Optional Enhancement Suggestions

<step_metadata>
  <purpose>Suggest relevant enhancements based on context, never automatic</purpose>
  <required>false</required>
  <philosophy>Always ask, never assume</philosophy>
</step_metadata>

<enhancement_detection>
  <context_analysis>
    1. Analyze spec description for enhancement opportunities
    2. Check available subagents for applicable improvements
    3. Determine if suggestions would add genuine value
    4. Prepare respectful, dismissible suggestions
  </context_analysis>
  
  <suggestion_criteria>
    <security_suggestion>
      <triggers>
        - "authentication", "login", "user accounts"  
        - "payment", "billing", "financial"
        - "sensitive data", "personal information"
      </triggers>
      <message>
        "💡 Security analysis available for features involving user data/authentication.
         This can help with production security considerations when you're ready.
         
         Add security analysis? [y/n] (default: n)"
      </message>
    </security_suggestion>
    
    <architecture_suggestion>
      <triggers>
        - "scalability", "high performance", "distributed system"
        - "microservices", "APIs", "external integrations"
        - "complex system", "enterprise application"
      </triggers>
      <message>
        "💡 Architectural review available for complex systems and scalability planning.
         Can help validate technical approach and long-term sustainability.
         
         Add architectural analysis? [y/n] (default: n)"
      </message>
    </architecture_suggestion>
    
    <no_suggestions>
      <triggers>
        - "prototype", "learning", "tutorial", "experiment"
        - "personal project", "internal tool", "documentation"
        - "static site", "simple app", "basic functionality"
      </triggers>
      <behavior>No enhancement suggestions offered</behavior>
    </no_suggestions>
  </suggestion_criteria>
</enhancement_detection>

<suggestion_behavior>
  <presentation>
    - Brief, single-line suggestions
    - Easily dismissible with "n" (default)
    - Educational context, not pressure
    - No re-asking if dismissed
  </presentation>
  
  <respect_choice>
    - Default response is "no"
    - No follow-up questions if declined
    - No guilt or pressure language
    - Document choice and continue standard workflow
  </respect_choice>
  
  <user_responses>
    IF user_says_yes:
      INVOKE appropriate subagent with full context
      INTEGRATE results into spec creation
    ELIF user_says_no:
      LOG "Enhancement declined, continuing standard workflow"
      CONTINUE with standard create-spec process
    ELIF user_dismisses:
      CONTINUE immediately without logging
  </user_responses>
</suggestion_behavior>

<example_interactions>
  <banking_app_prototype>
    USER: /create-spec "Banking app user registration"
    
    AGENT: "💡 Security analysis available for user authentication features.
            This can help with production security when you're ready.
            
            Add security analysis? [y/n] (default: n)"
    
    USER: "n"
    
    AGENT: "✅ No problem! Focusing on core functionality.
            (Security analysis available anytime with /enhance --security)"
    
    [Continues with standard spec creation]
  </banking_app_prototype>
  
  <simple_blog>
    USER: /create-spec "Personal blog with markdown posts"
    
    AGENT: [No enhancement suggestions - clearly simple project]
           "✅ Creating spec for personal blog..."
    
    [Continues with standard spec creation]
  </simple_blog>
  
  <complex_system>
    USER: /create-spec "Distributed microservices platform"
    
    AGENT: "💡 Architectural review available for distributed systems.
            Can help with scalability planning and system design.
            
            Add architectural analysis? [y/n] (default: n)"
    
    USER: "y"
    
    AGENT: "✅ Including architectural analysis from systems-architect.
            This will enhance the technical specification with professional system design insights."
    
    [Invokes systems-architect and integrates results]
  </complex_system>
</example_interactions>

<instructions>
  ACTION: Suggest relevant enhancements based on genuine value potential
  PHILOSOPHY: Respectful suggestions, easy dismissal, no pressure
  DEFAULT: Continue standard workflow unless user explicitly opts in
  TIMING: After requirements clarification, before spec creation
</instructions>

</step>
```

## Key Principles Demonstrated

1. **Context-Aware**: Only suggests enhancements that genuinely add value
2. **Easily Dismissed**: Default is "no", single keystroke to dismiss
3. **No Pressure**: Educational framing, not enforcement language
4. **Respects Choice**: No follow-up questions or guilt if declined
5. **Available Later**: User can always add enhancements with /enhance command

This approach ensures that:
- Prototypes stay focused on core functionality
- Production systems can get professional analysis when ready
- Learning projects aren't overwhelmed with unnecessary complexity
- The developer always maintains full control over their workflow