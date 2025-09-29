# Test Suite for Duplicate Management App

This directory contains simplified tests for the React duplicate management application, focusing on the core components.

## Test Structure

```
src/test/
├── README.md                          # This file
├── setup.ts                          # Test setup and configuration
├── mocks/
│   ├── server.ts                     # MSW server setup
│   └── handlers.ts                   # API mock handlers
└── components/
    ├── App.test.tsx                  # Main App component tests
    └── DuplicateTable.test.tsx       # DuplicateTable component tests
```

## Running Tests

### Install Dependencies

```bash
npm install
```

### Run All Tests

```bash
npm test
```

### Run Tests with UI

```bash
npm run test:ui
```

### Run Tests with Coverage

```bash
npm run test:coverage
```

### Run Specific Test Files

```bash
# Run component tests only
npm test components

# Run specific component test
npm test App.test
npm test DuplicateTable.test
```

## Test Categories

### **Component Tests** (`components/`)

- **App.test.tsx**: Tests main App component rendering, layout, and integration
- **DuplicateTable.test.tsx**: Tests table component, user interactions, and data display
- Tests React component rendering
- Tests user interactions
- Tests component state management
- Tests accessibility features

## Test Features

### 🎯 **Focused Coverage**

- **Components**: Core React components (App and DuplicateTable)
- **User Interactions**: Button clicks, data display, loading states
- **Error Handling**: API failures and edge cases
- **Accessibility**: Semantic HTML and screen reader support

### 🔧 **Mock Server (MSW)**

- Intercepts HTTP requests during tests
- Provides consistent test data
- Simulates error scenarios
- No external dependencies needed

### ♿ **Accessibility Testing**

- Tests semantic HTML structure
- Validates ARIA attributes
- Tests keyboard navigation
- Ensures screen reader compatibility

### 📱 **Responsive Design Testing**

- Tests layout at different screen sizes
- Validates CSS styling
- Tests mobile interactions

## Test Data

### Mock Duplicate Matches

```typescript
const mockDuplicateMatches = [
	{
		id: "a01XX000001234",
		customerA: {
			id: "a00XX000001111",
			firstName: "John",
			lastName: "Smith",
			email: "john.smith@example.com",
			phone: "555-1234",
		},
		customerB: {
			id: "a00XX000002222",
			firstName: "Jon",
			lastName: "Smith",
			email: "jon.smith@example.com",
			phone: "555-1234",
		},
		matchScore: 70,
		status: "Pending Review",
	},
	// ... more test data
];
```

## Testing Scenarios

### ✅ **Happy Path**

- Load and display duplicate matches
- Show customer information correctly
- Handle merge/ignore button interactions
- Display proper loading and success states

### ⚠️ **Error Scenarios**

- API failures and error messages
- Empty duplicate lists
- Network connectivity issues

### 📊 **Edge Cases**

- Missing customer data
- Various match scores (100, 70, 50)
- Different customer name formats

## Configuration

### Vitest Config (`vitest.config.ts`)

- Uses jsdom environment for DOM testing
- Includes React plugin for JSX support
- Configures coverage reporting
- Sets up test globals

### Test Setup (`setup.ts`)

- Configures MSW server
- Sets up testing-library/jest-dom matchers
- Mocks browser APIs (localStorage, location)
- Handles cleanup between tests

## Best Practices

### 🎯 **Test Organization**

- Group related tests with `describe` blocks
- Use descriptive test names
- Follow AAA pattern (Arrange, Act, Assert)

### 🔄 **Async Testing**

- Use `waitFor` for async operations
- Test loading states
- Test error boundaries

### 🎭 **Mocking**

- Mock external dependencies
- Use MSW for HTTP requests
- Mock browser APIs when needed

### 📝 **Assertions**

- Test user-visible behavior
- Avoid implementation details
- Use semantic queries (getByRole, getByText)

## Continuous Integration

These tests are designed to run in CI environments:

- No external dependencies
- Deterministic test data
- Fast execution
- Clear failure messages

## Debugging Tests

### Run Tests in Watch Mode

```bash
npm test -- --watch
```

### Debug Specific Test

```bash
npm test -- --reporter=verbose DuplicateTable
```

### View Test Coverage

```bash
npm run test:coverage
open coverage/index.html
```

## Contributing

When adding new features:

1. Focus on testing user-visible behavior
2. Test both happy path and error cases
3. Include accessibility tests
4. Update mock data if needed
5. Run tests before committing

## Simplified Test Suite

This streamlined test suite focuses on the essential component tests:

- **App.test.tsx**: Main application layout and integration
- **DuplicateTable.test.tsx**: Core table functionality and user interactions

The tests cover the most important user scenarios while keeping the test suite maintainable and fast.
