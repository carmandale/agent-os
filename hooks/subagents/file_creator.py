#!/usr/bin/env python3
"""
File Creator Subagent - Template-based file generation and scaffolding.

This subagent provides intelligent file creation with templates,
reducing boilerplate and ensuring consistent file structure across
Agent OS projects.
"""

import os
import re
import json
from typing import Dict, Any, Optional, List
from pathlib import Path
import logging

logger = logging.getLogger(__name__)


class FileCreatorAgent:
    """
    Specialized agent for template-based file generation.
    
    Provides:
    - Smart template selection based on file type
    - Component scaffolding for common frameworks
    - Consistent file headers and structure
    - Agent OS spec file generation
    """
    
    def __init__(self):
        """Initialize the file creator agent with templates."""
        self.templates = self._load_templates()
    
    def execute(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute a file creation task.
        
        Args:
            task: Dictionary containing file creation parameters
            
        Returns:
            Dictionary with creation results
        """
        file_type = task.get('type', 'generic')
        file_path = task.get('path', '')
        file_name = task.get('name', '')
        parameters = task.get('parameters', {})
        
        if file_type == 'spec':
            return self._create_spec_file(file_name, parameters)
        elif file_type == 'component':
            return self._create_component(file_name, parameters)
        elif file_type == 'test':
            return self._create_test_file(file_name, parameters)
        elif file_type == 'config':
            return self._create_config_file(file_name, parameters)
        elif file_type == 'script':
            return self._create_script_file(file_name, parameters)
        else:
            return self._create_generic_file(file_path, file_name, parameters)
    
    def _load_templates(self) -> Dict[str, str]:
        """
        Load file templates for various file types.
        
        Returns:
            Dictionary of templates by type
        """
        templates = {
            'python_class': '''#!/usr/bin/env python3
"""
{description}
"""

import logging
from typing import Dict, Any, Optional, List

logger = logging.getLogger(__name__)


class {class_name}:
    """
    {class_description}
    """
    
    def __init__(self):
        """Initialize the {class_name}."""
        pass
    
    def execute(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute the main task.
        
        Args:
            task: Task parameters
            
        Returns:
            Task results
        """
        return {{'success': True}}
''',
            
            'react_component': '''import React from 'react';

interface {component_name}Props {{
  {props}
}}

export const {component_name}: React.FC<{component_name}Props> = ({{ {prop_names} }}) => {{
  return (
    <div className="{component_class}">
      {{/* Component content */}}
    </div>
  );
}};
''',
            
            'test_file': '''#!/usr/bin/env python3
"""
Test suite for {module_name}.
"""

import unittest
from unittest.mock import Mock, patch
from pathlib import Path
import sys

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from {module_name} import {class_name}


class Test{class_name}(unittest.TestCase):
    """Test cases for {class_name}."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.instance = {class_name}()
    
    def test_initialization(self):
        """Test that {class_name} initializes correctly."""
        self.assertIsNotNone(self.instance)
    
    def test_execute(self):
        """Test execute method."""
        result = self.instance.execute({{}})
        self.assertTrue(result.get('success'))


if __name__ == '__main__':
    unittest.main(verbosity=2)
''',
            
            'bash_script': '''#!/bin/bash

# {description}
# Created: {date}
# Agent OS Script

set -e  # Exit on error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/{relative_root}" && pwd)"

# Colors for output
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
NC='\\033[0m' # No Color

# Functions
log_info() {{
    echo -e "${{GREEN}}✓${{NC}} $1"
}}

log_error() {{
    echo -e "${{RED}}✗${{NC}} $1"
}}

log_warning() {{
    echo -e "${{YELLOW}}⚠${{NC}} $1"
}}

# Main logic
main() {{
    log_info "Starting {script_name}..."
    
    # TODO: Add main logic here
    
    log_info "Completed successfully!"
}}

# Run main function
main "$@"
''',
            
            'agent_os_spec': '''# {spec_type}

> Spec: {spec_name}
> Created: {date}
> Version: 1.0.0

## Overview

{overview}

## Requirements

{requirements}

## Implementation

{implementation}

## Testing

{testing}

## Notes

{notes}
''',
            
            'config_json': '''{{
  "name": "{name}",
  "version": "1.0.0",
  "description": "{description}",
  "configuration": {{
    {config_items}
  }}
}}
''',
            
            'config_yaml': '''# {name} Configuration
# Created: {date}

name: {name}
version: 1.0.0
description: {description}

configuration:
{config_items}
''',
            
            'markdown': '''# {title}

> Created: {date}
> Version: 1.0.0

## Overview

{overview}

## Details

{details}

## References

{references}
'''
        }
        
        return templates
    
    def _create_spec_file(self, name: str, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Create an Agent OS spec file.
        
        Args:
            name: File name
            params: Parameters for the spec
            
        Returns:
            File content and metadata
        """
        from datetime import datetime
        
        template = self.templates['agent_os_spec']
        content = template.format(
            spec_type=params.get('spec_type', 'Specification'),
            spec_name=params.get('spec_name', name),
            date=datetime.now().strftime('%Y-%m-%d'),
            overview=params.get('overview', 'TODO: Add overview'),
            requirements=params.get('requirements', '- TODO: Add requirements'),
            implementation=params.get('implementation', 'TODO: Add implementation details'),
            testing=params.get('testing', 'TODO: Add testing strategy'),
            notes=params.get('notes', 'TODO: Add additional notes')
        )
        
        return {
            'success': True,
            'file_name': name,
            'content': content,
            'type': 'spec',
            'template_used': 'agent_os_spec'
        }
    
    def _create_component(self, name: str, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Create a component file (React, Python class, etc.).
        
        Args:
            name: Component name
            params: Component parameters
            
        Returns:
            Component file content
        """
        component_type = params.get('component_type', 'python')
        
        if component_type == 'react':
            template = self.templates['react_component']
            props = params.get('props', {})
            prop_definitions = '\n  '.join([f'{k}: {v};' for k, v in props.items()])
            prop_names = ', '.join(props.keys())
            
            content = template.format(
                component_name=name,
                props=prop_definitions if prop_definitions else '// No props',
                prop_names=prop_names if prop_names else '',
                component_class=params.get('class_name', 'component')
            )
            
            file_name = f"{name}.tsx"
            
        else:  # Python class
            template = self.templates['python_class']
            content = template.format(
                description=params.get('description', f'{name} module'),
                class_name=name,
                class_description=params.get('class_description', f'{name} implementation')
            )
            
            file_name = f"{name.lower()}.py"
        
        return {
            'success': True,
            'file_name': file_name,
            'content': content,
            'type': 'component',
            'component_type': component_type,
            'template_used': f'{component_type}_component'
        }
    
    def _create_test_file(self, name: str, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Create a test file with proper structure.
        
        Args:
            name: Test file name
            params: Test parameters
            
        Returns:
            Test file content
        """
        module_name = params.get('module_name', name.replace('test_', ''))
        class_name = params.get('class_name', 
                               ''.join(w.capitalize() for w in module_name.split('_')))
        
        template = self.templates['test_file']
        content = template.format(
            module_name=module_name,
            class_name=class_name
        )
        
        file_name = f"test_{module_name}.py" if not name.startswith('test_') else f"{name}.py"
        
        return {
            'success': True,
            'file_name': file_name,
            'content': content,
            'type': 'test',
            'template_used': 'test_file'
        }
    
    def _create_config_file(self, name: str, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Create a configuration file (JSON, YAML, etc.).
        
        Args:
            name: Config file name
            params: Configuration parameters
            
        Returns:
            Config file content
        """
        from datetime import datetime
        
        config_type = params.get('format', 'json')
        config_items = params.get('config', {})
        
        if config_type == 'yaml':
            template = self.templates['config_yaml']
            # Format config items for YAML
            formatted_items = '\n'.join([
                f"  {k}: {v}" for k, v in config_items.items()
            ])
            
            content = template.format(
                name=name,
                date=datetime.now().strftime('%Y-%m-%d'),
                description=params.get('description', 'Configuration file'),
                config_items=formatted_items
            )
            
            file_name = f"{name}.yaml"
            
        else:  # JSON
            template = self.templates['config_json']
            # Format config items for JSON
            formatted_items = ',\n    '.join([
                f'"{k}": {json.dumps(v)}' for k, v in config_items.items()
            ])
            
            content = template.format(
                name=name,
                description=params.get('description', 'Configuration file'),
                config_items=formatted_items if formatted_items else ''
            )
            
            file_name = f"{name}.json"
        
        return {
            'success': True,
            'file_name': file_name,
            'content': content,
            'type': 'config',
            'format': config_type,
            'template_used': f'config_{config_type}'
        }
    
    def _create_script_file(self, name: str, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Create a shell script file.
        
        Args:
            name: Script name
            params: Script parameters
            
        Returns:
            Script file content
        """
        from datetime import datetime
        
        template = self.templates['bash_script']
        
        # Calculate relative path to project root
        script_depth = params.get('depth', 0)
        relative_root = '/'.join(['..'] * script_depth) if script_depth > 0 else '.'
        
        content = template.format(
            description=params.get('description', f'{name} script'),
            date=datetime.now().strftime('%Y-%m-%d'),
            script_name=name,
            relative_root=relative_root
        )
        
        file_name = f"{name}.sh" if not name.endswith('.sh') else name
        
        return {
            'success': True,
            'file_name': file_name,
            'content': content,
            'type': 'script',
            'template_used': 'bash_script',
            'executable': True
        }
    
    def _create_generic_file(self, path: str, name: str, 
                            params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Create a generic file with basic structure.
        
        Args:
            path: File path
            name: File name
            params: File parameters
            
        Returns:
            File content and metadata
        """
        from datetime import datetime
        
        # Determine file type by extension
        ext = Path(name).suffix.lower()
        
        if ext == '.md':
            template = self.templates['markdown']
            content = template.format(
                title=params.get('title', name.replace('.md', '')),
                date=datetime.now().strftime('%Y-%m-%d'),
                overview=params.get('overview', ''),
                details=params.get('details', ''),
                references=params.get('references', '')
            )
        else:
            # Basic file with header comment
            content = params.get('content', '')
            if not content:
                content = f"# {name}\n# Created: {datetime.now().strftime('%Y-%m-%d')}\n\n"
        
        return {
            'success': True,
            'file_name': name,
            'file_path': path,
            'content': content,
            'type': 'generic',
            'extension': ext
        }