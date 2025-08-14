#!/usr/bin/env python3
"""
Date Checker Subagent - Accurate date determination and time operations.

This subagent provides reliable date/time functionality for Agent OS,
ensuring consistent date formatting and preventing date-related errors
in spec folder naming and timestamp operations.
"""

import os
import time
import subprocess
from datetime import datetime, timedelta, timezone
from typing import Dict, Any, Optional, List
from pathlib import Path
import logging

logger = logging.getLogger(__name__)


class DateCheckerAgent:
    """
    Specialized agent for accurate date and time operations.
    
    Provides:
    - System date verification
    - Multiple date source fallbacks
    - Timezone-aware operations
    - Date formatting for Agent OS specs
    """
    
    def __init__(self):
        """Initialize the date checker agent."""
        self.date_formats = {
            'spec': '%Y-%m-%d',           # 2025-08-14 for spec folders
            'iso': '%Y-%m-%dT%H:%M:%S',   # ISO 8601
            'display': '%B %d, %Y',        # August 14, 2025
            'timestamp': '%Y%m%d_%H%M%S'  # 20250814_143022
        }
    
    def execute(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute a date-related task.
        
        Args:
            task: Dictionary containing date operation parameters
            
        Returns:
            Dictionary with date/time results
        """
        operation = task.get('operation', 'current')
        format_type = task.get('format', 'spec')
        
        if operation == 'current':
            return self._get_current_date(format_type)
        elif operation == 'parse':
            return self._parse_date(task.get('date_string', ''))
        elif operation == 'calculate':
            return self._calculate_date(task.get('base_date'), task.get('delta'))
        elif operation == 'validate':
            return self._validate_date(task.get('date_string', ''))
        elif operation == 'timezone':
            return self._get_timezone_info()
        else:
            return {'error': f'Unknown operation: {operation}'}
    
    def _get_current_date(self, format_type: str = 'spec') -> Dict[str, Any]:
        """
        Get current date using multiple verification methods.
        
        Args:
            format_type: Format to return date in
            
        Returns:
            Dictionary with current date information
        """
        # Method 1: Python datetime (most reliable)
        now = datetime.now()
        
        # Method 2: System date command for verification
        system_date = self._get_system_date()
        
        # Method 3: File timestamp verification
        file_date = self._get_file_timestamp_date()
        
        # Compare and validate dates
        dates_match = self._verify_dates_match(now, system_date, file_date)
        
        # Get the requested format
        date_format = self.date_formats.get(format_type, self.date_formats['spec'])
        formatted_date = now.strftime(date_format)
        
        result = {
            'success': True,
            'date': formatted_date,
            'format': format_type,
            'timestamp': now.timestamp(),
            'iso_date': now.isoformat(),
            'verification': {
                'python_date': now.strftime('%Y-%m-%d'),
                'system_date': system_date.strftime('%Y-%m-%d') if system_date else None,
                'file_date': file_date.strftime('%Y-%m-%d') if file_date else None,
                'dates_match': dates_match
            }
        }
        
        # Add additional date components for convenience
        result['components'] = {
            'year': now.year,
            'month': now.month,
            'day': now.day,
            'hour': now.hour,
            'minute': now.minute,
            'second': now.second,
            'weekday': now.strftime('%A'),
            'week_number': now.isocalendar()[1]
        }
        
        return result
    
    def _get_system_date(self) -> Optional[datetime]:
        """
        Get date from system using date command.
        
        Returns:
            datetime object or None if failed
        """
        try:
            result = subprocess.run(
                ['date', '+%Y-%m-%d %H:%M:%S'],
                capture_output=True,
                text=True,
                timeout=1
            )
            
            if result.returncode == 0:
                date_str = result.stdout.strip()
                return datetime.strptime(date_str, '%Y-%m-%d %H:%M:%S')
        except Exception as e:
            logger.warning(f"Failed to get system date: {e}")
        
        return None
    
    def _get_file_timestamp_date(self) -> Optional[datetime]:
        """
        Get date by creating a temporary file and reading its timestamp.
        
        Returns:
            datetime object or None if failed
        """
        try:
            # Create temporary file
            temp_file = Path('/tmp/.agent_os_date_check')
            temp_file.touch()
            
            # Get file modification time
            mtime = temp_file.stat().st_mtime
            file_date = datetime.fromtimestamp(mtime)
            
            # Clean up
            temp_file.unlink()
            
            return file_date
        except Exception as e:
            logger.warning(f"Failed to get file timestamp date: {e}")
        
        return None
    
    def _verify_dates_match(self, python_date: datetime, 
                           system_date: Optional[datetime],
                           file_date: Optional[datetime]) -> bool:
        """
        Verify that different date sources match.
        
        Args:
            python_date: Date from Python datetime
            system_date: Date from system command
            file_date: Date from file timestamp
            
        Returns:
            True if dates match within tolerance
        """
        # Allow 1 second tolerance for timing differences
        tolerance = timedelta(seconds=1)
        
        if system_date:
            if abs(python_date - system_date) > tolerance:
                logger.warning(f"Date mismatch: Python={python_date}, System={system_date}")
                return False
        
        if file_date:
            if abs(python_date - file_date) > tolerance:
                logger.warning(f"Date mismatch: Python={python_date}, File={file_date}")
                return False
        
        return True
    
    def _parse_date(self, date_string: str) -> Dict[str, Any]:
        """
        Parse a date string into various formats.
        
        Args:
            date_string: Date string to parse
            
        Returns:
            Dictionary with parsed date information
        """
        # Common date formats to try
        formats_to_try = [
            '%Y-%m-%d',
            '%Y/%m/%d',
            '%m/%d/%Y',
            '%d/%m/%Y',
            '%Y-%m-%d %H:%M:%S',
            '%Y-%m-%dT%H:%M:%S',
            '%B %d, %Y',
            '%b %d, %Y',
            '%d %B %Y',
            '%d %b %Y'
        ]
        
        parsed_date = None
        used_format = None
        
        for fmt in formats_to_try:
            try:
                parsed_date = datetime.strptime(date_string, fmt)
                used_format = fmt
                break
            except ValueError:
                continue
        
        if parsed_date:
            return {
                'success': True,
                'original': date_string,
                'parsed_format': used_format,
                'spec_format': parsed_date.strftime(self.date_formats['spec']),
                'iso_format': parsed_date.isoformat(),
                'timestamp': parsed_date.timestamp(),
                'components': {
                    'year': parsed_date.year,
                    'month': parsed_date.month,
                    'day': parsed_date.day
                }
            }
        else:
            return {
                'success': False,
                'error': f"Could not parse date: {date_string}",
                'tried_formats': formats_to_try
            }
    
    def _calculate_date(self, base_date: Optional[str], 
                       delta: Dict[str, int]) -> Dict[str, Any]:
        """
        Calculate a date based on a base date and delta.
        
        Args:
            base_date: Base date string or None for current date
            delta: Dictionary with days, weeks, months, years to add/subtract
            
        Returns:
            Dictionary with calculated date
        """
        # Parse base date or use current
        if base_date:
            parsed = self._parse_date(base_date)
            if not parsed['success']:
                return parsed
            base = datetime.fromtimestamp(parsed['timestamp'])
        else:
            base = datetime.now()
        
        # Apply delta
        result_date = base
        
        if delta.get('days'):
            result_date += timedelta(days=delta['days'])
        if delta.get('weeks'):
            result_date += timedelta(weeks=delta['weeks'])
        if delta.get('hours'):
            result_date += timedelta(hours=delta['hours'])
        
        # Handle months and years (approximate)
        if delta.get('months'):
            # Approximate: 30 days per month
            result_date += timedelta(days=delta['months'] * 30)
        if delta.get('years'):
            # Approximate: 365 days per year
            result_date += timedelta(days=delta['years'] * 365)
        
        return {
            'success': True,
            'base_date': base.strftime(self.date_formats['spec']),
            'delta': delta,
            'result_date': result_date.strftime(self.date_formats['spec']),
            'iso_format': result_date.isoformat(),
            'timestamp': result_date.timestamp()
        }
    
    def _validate_date(self, date_string: str) -> Dict[str, Any]:
        """
        Validate a date string for Agent OS spec naming.
        
        Args:
            date_string: Date string to validate
            
        Returns:
            Dictionary with validation results
        """
        # Check spec format (YYYY-MM-DD)
        import re
        spec_pattern = r'^\d{4}-\d{2}-\d{2}$'
        
        if not re.match(spec_pattern, date_string):
            return {
                'success': False,
                'valid': False,
                'error': 'Date must be in YYYY-MM-DD format',
                'expected_format': 'YYYY-MM-DD',
                'provided': date_string
            }
        
        # Parse and validate date values
        try:
            date_obj = datetime.strptime(date_string, '%Y-%m-%d')
            
            # Check reasonable date range (2020-2030)
            if date_obj.year < 2020 or date_obj.year > 2030:
                return {
                    'success': True,
                    'valid': False,
                    'warning': f'Year {date_obj.year} seems unusual (expected 2020-2030)',
                    'date': date_string
                }
            
            return {
                'success': True,
                'valid': True,
                'date': date_string,
                'parsed': {
                    'year': date_obj.year,
                    'month': date_obj.month,
                    'day': date_obj.day
                }
            }
            
        except ValueError as e:
            return {
                'success': False,
                'valid': False,
                'error': f'Invalid date values: {str(e)}',
                'date': date_string
            }
    
    def _get_timezone_info(self) -> Dict[str, Any]:
        """
        Get current timezone information.
        
        Returns:
            Dictionary with timezone details
        """
        try:
            # Get system timezone
            tz_result = subprocess.run(
                ['date', '+%Z %z'],
                capture_output=True,
                text=True,
                timeout=1
            )
            
            tz_info = tz_result.stdout.strip().split()
            tz_name = tz_info[0] if tz_info else 'Unknown'
            tz_offset = tz_info[1] if len(tz_info) > 1 else '+0000'
            
            # Get current time in UTC
            utc_now = datetime.now(timezone.utc)
            
            return {
                'success': True,
                'timezone': tz_name,
                'offset': tz_offset,
                'utc_time': utc_now.isoformat(),
                'local_time': datetime.now().isoformat(),
                'is_dst': time.daylight != 0
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }