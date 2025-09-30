# ShopNow Duplicate Management - Salesforce Backend

This Salesforce project provides the backend infrastructure for ShopNow's customer duplicate detection and management system.

## What This Project Does

The system automatically identifies and helps resolve duplicate customer records in Salesforce using intelligent matching algorithms. When customers sign up multiple times with slight variations in their information, this system finds those duplicates and provides tools to merge them.

## Key Features

### **Automatic Duplicate Detection**

-   Scans customer records to find potential duplicates
-   Uses multiple matching rules with confidence scores:
    -   **Email matches** (100% confidence) - Same email address
    -   **Phone + name similarity** (70% confidence) - Same phone with similar names
    -   **Phone + last name** (50% confidence) - Same phone with matching last name

### **Smart Customer Merging**

-   Intelligently consolidates duplicate customer data
-   Keeps the best information from both records (longer names, earlier signup dates)
-   Maintains audit trail of merge operations

### **Management Interface**

-   REST API for the React frontend to display duplicate matches
-   Allows users to review and resolve duplicates (merge or ignore)
-   Tracks resolution status and history

## Project Structure

```
force-app/main/default/
├── classes/
│   ├── services/              # Core business logic
│   │   ├── batchable-dup-scan/    # Automated duplicate detection
│   │   ├── customer-merger/       # Customer merge functionality
│   │   └── similarity-scorer/     # Name matching algorithms
│   ├── utilities/             # Helper classes
│   └── resources/             # API endpoints (removed)
├── objects/                   # Custom Salesforce objects
│   ├── Customer__c/               # Customer records
│   └── Duplicate_Match__c/        # Duplicate pair tracking
├── lwc/                       # Lightning Web Components
│   └── testDataGenerator/        # Test data creation tool
└── permissionsets/            # Security and access control
```

## How It Works

1. **Data Collection**: Customer information is stored in `Customer__c` custom objects
2. **Batch Processing**: `BatchDuplicateScan` runs periodically to find potential duplicates
3. **Match Scoring**: Algorithm assigns confidence scores to potential duplicate pairs
4. **Review Process**: Matches are stored in `Duplicate_Match__c` for human review
5. **Resolution**: Users can merge duplicates using `CustomerMerger` service
6. **Audit Trail**: System tracks what was merged and when

## Testing & Data Management

-   **Test Data Generator**: Lightning component to create sample customer data
-   **Comprehensive Test Suite**: Full test coverage for all services
-   **Multiple Test Scenarios**: Covers edge cases and various duplicate patterns

## Integration

This Salesforce backend integrates with:

-   **React Frontend**: Provides REST API for duplicate management UI
-   **Node.js Proxy Server**: Handles authentication and API routing
-   **External Systems**: Ready for future integrations with other customer data sources

The system is designed to be scalable and maintainable, with clear separation of concerns and comprehensive error handling.
