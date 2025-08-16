# Testing Checklists for Agent OS Workflows

> Created: 2025-07-30
> Version: 1.0.0
> Purpose: Standardized testing checklists for different work types

## Frontend Work Testing Checklist

**Before marking frontend work as complete:**

### Browser Testing Requirements
- [ ] **Chrome Testing:** Feature tested in Chrome browser
- [ ] **Firefox Testing:** Feature tested in Firefox browser  
- [ ] **Safari Testing:** Feature tested in Safari (if applicable)
- [ ] **Visual Verification:** UI appears correctly and matches design
- [ ] **Console Check:** No JavaScript errors in browser console

### User Interaction Testing
- [ ] **Click Testing:** All buttons and links work correctly
- [ ] **Form Testing:** Forms submit properly and handle validation
- [ ] **Navigation Testing:** All navigation flows work as expected
- [ ] **User Workflow:** Complete user scenarios tested end-to-end

### Responsive Design Testing
- [ ] **Desktop Testing:** Layout works on desktop screens (1920x1080+)
- [ ] **Tablet Testing:** Layout works on tablet screens (768px-1024px)
- [ ] **Mobile Testing:** Layout works on mobile screens (320px-767px)
- [ ] **Breakpoint Testing:** Design transitions smoothly between breakpoints

### Automated Testing
- [ ] **Component Tests:** `npm test` or `yarn test` executed and passing
- [ ] **E2E Tests:** Playwright/Cypress tests executed (if available)
- [ ] **Test Coverage:** New functionality has corresponding tests
- [ ] **Integration Tests:** Component integrates properly with existing system

### Evidence Documentation
- [ ] **Testing Evidence:** Documented proof of browser testing
- [ ] **Screenshots:** Visual evidence of functionality (if applicable)
- [ ] **Test Results:** Automated test results shown
- [ ] **User Flow Proof:** Evidence of complete user workflow testing

---

## Backend Work Testing Checklist

**Before marking backend work as complete:**

### API Testing Requirements
- [ ] **HTTP Requests:** API endpoints tested with `curl` or API client
- [ ] **Request Methods:** All HTTP methods (GET, POST, PUT, DELETE) tested
- [ ] **Status Codes:** Correct HTTP status codes returned
- [ ] **Response Format:** API returns properly formatted responses (JSON, etc.)
- [ ] **Error Responses:** Error scenarios return appropriate error messages

### Database Testing
- [ ] **Data Creation:** New records created correctly in database
- [ ] **Data Retrieval:** Data queried and returned accurately
- [ ] **Data Updates:** Existing records updated properly
- [ ] **Data Deletion:** Records deleted safely without orphans
- [ ] **Constraints:** Database constraints and validations working

### Integration Testing
- [ ] **Service Integration:** API integrates with other services
- [ ] **Authentication:** Auth flows tested (if applicable)
- [ ] **Authorization:** Permission checks working correctly
- [ ] **External APIs:** Third-party API integrations tested
- [ ] **Error Propagation:** Errors handled and propagated properly

### Automated Testing
- [ ] **Unit Tests:** Test suite executed (`pytest`, `npm test`, etc.)
- [ ] **Integration Tests:** API integration tests passing
- [ ] **Test Coverage:** New endpoints have test coverage
- [ ] **Mock Testing:** External dependencies properly mocked

### Evidence Documentation
- [ ] **API Call Examples:** `curl` commands and responses shown
- [ ] **Database Verification:** Proof of database operations
- [ ] **Test Results:** Automated test execution results
- [ ] **Error Scenario Testing:** Evidence of error handling validation

---

## Script Work Testing Checklist

**Before marking script work as complete:**

### Execution Testing
- [ ] **Basic Execution:** Script runs successfully with normal parameters
- [ ] **Output Verification:** Script produces expected output
- [ ] **Exit Codes:** Script returns appropriate exit codes (0 for success)
- [ ] **Logging:** Script provides clear status messages and logging
- [ ] **Completion Verification:** Script completes all intended operations

### Parameter Testing
- [ ] **Default Parameters:** Script works with default/no parameters
- [ ] **Custom Parameters:** Script accepts and processes custom parameters
- [ ] **Invalid Input:** Script handles invalid input gracefully
- [ ] **Edge Cases:** Script tested with boundary conditions
- [ ] **Help Documentation:** Script provides usage help (if applicable)

### Error Handling Testing
- [ ] **File Permissions:** Script handles permission errors
- [ ] **Missing Dependencies:** Script handles missing requirements
- [ ] **Network Issues:** Script handles network failures (if applicable)
- [ ] **Disk Space:** Script handles insufficient disk space
- [ ] **Cleanup:** Script cleans up properly on errors

### Environment Testing
- [ ] **Target Environment:** Script tested in intended environment
- [ ] **Cross-Platform:** Script tested on different platforms (if applicable)
- [ ] **Dependencies:** All required dependencies available
- [ ] **Configuration:** Script respects configuration files/environment variables
- [ ] **Idempotency:** Script can be run multiple times safely

### Evidence Documentation
- [ ] **Execution Output:** Complete script execution output shown
- [ ] **Success Proof:** Evidence of successful completion
- [ ] **Error Testing:** Proof of error scenario testing
- [ ] **Performance:** Script execution time and resource usage noted

---

## Mixed Work Type Testing Checklist

**For work involving multiple types (frontend + backend, etc.):**

### Integration Requirements
- [ ] **End-to-End Flow:** Complete user flow tested from frontend to backend
- [ ] **Data Flow:** Data properly flows between frontend and backend
- [ ] **Error Handling:** Errors properly handled across all components
- [ ] **State Management:** Application state consistent across components

### Component Testing
- [ ] **Frontend Checklist:** All frontend requirements met
- [ ] **Backend Checklist:** All backend requirements met
- [ ] **Script Checklist:** All script requirements met (if applicable)
- [ ] **Integration Testing:** Components work together properly

### Evidence Requirements
- [ ] **Comprehensive Evidence:** Evidence provided for all work types
- [ ] **Integration Proof:** Evidence of component integration
- [ ] **User Workflow:** Complete user workflow demonstration
- [ ] **System Testing:** Evidence of full system functionality

---

## Testing Evidence Templates

### Frontend Evidence Template
```
Tested the [feature] in browser:
• ✓ Chrome: Feature works correctly
• ✓ Firefox: Feature works correctly  
• ✓ Mobile: Responsive design verified
• ✓ User Flow: [specific workflow] completed successfully
• ✓ Tests: npm test passed (25/25)
• ✓ No console errors detected
```

### Backend Evidence Template
```bash
# API Testing Results
curl -X POST http://localhost:8000/api/endpoint -d '{data}'
HTTP/1.1 200 OK
{"status": "success", "id": 123}

# Database Verification
✓ Record created in users table
✓ All constraints satisfied
✓ Unit tests: pytest passed (15/15)
✓ Integration tests passed
```

### Script Evidence Template
```bash
$ ./script-name.sh --param value
Starting script execution...
✓ Phase 1: Initialization complete
✓ Phase 2: Processing complete  
✓ Phase 3: Cleanup complete
Script completed successfully in 2.3s
Exit code: 0
```

---

**💡 Pro Tip:** Copy and customize these templates for your specific testing evidence. The more specific and detailed your evidence, the more confident you can be in your completion claims.