# CustomerMerger Service

A robust Salesforce service for merging duplicate customer records with intelligent data consolidation and comprehensive audit trails.

## Overview

The `CustomerMerger` service handles the complex process of merging two Customer\_\_c records by consolidating their data, marking the loser record as merged, and maintaining data integrity throughout the process. It uses merge strategies to determine the best values for each field.

## Features

-   **Intelligent Data Consolidation**: Uses smart merge strategies (prefer longer names, earlier dates, etc.)
-   **Comprehensive Validation**: Prevents invalid merges (same record, already merged, non-existent records)
-   **Transaction Safety**: Uses savepoints for rollback on errors
-   **Detailed Logging**: Comprehensive debug logging for monitoring and troubleshooting

## Usage

### Basic Merge Operation

```apex
// Merge customer B into customer A
CustomerMerger.MergeResult result = CustomerMerger.mergeCustomers(winnerCustomerId, loserCustomerId);

if (result.success) {
    System.debug('Merge successful! Winner: ' + result.winnerId + ', Loser: ' + result.loserId);
} else {
    System.debug('Merge failed: ' + result.errorMessage);
}
```

### Integration with DuplicateApi

The service is automatically called by the DuplicateApi when resolving duplicate matches:

```apex
// POST /duplicates/{id}/resolve with body: {"action": "merge"}
// Internally calls: CustomerMerger.mergeCustomers(match.Customer_A__c, match.Customer_B__c)
```

## Merge Strategies

The service uses different strategies for different field types:

### Name Fields (FirstName\_\_c, LastName\_\_c)

-   **Strategy**: `PREFER_LONGER`
-   **Logic**: Chooses the longer, more complete name
-   **Example**: "Jonathan" wins over "John", "Smith-Johnson" wins over "Smith"

### Contact Fields (Email\_\_c, Phone\_\_c)

-   **Strategy**: `PREFER_WINNER`
-   **Logic**: Always keeps the winner's data as authoritative
-   **Rationale**: Winner is typically the primary/preferred record

### Date Fields (SignupDate\_\_c)

-   **Strategy**: `PREFER_EARLIER`
-   **Logic**: Uses the earlier date to preserve original signup information
-   **Rationale**: Earlier date likely represents the actual first interaction

### Null/Blank Handling

-   If winner has data and loser is blank → use winner's data
-   If winner is blank and loser has data → use loser's data
-   If both are blank → keep as null/blank
-   If both have data → apply field-specific strategy

## Validation Rules

The service performs comprehensive validation before merging:

1. **Null Checks**: Both customer IDs must be provided
2. **Self-Merge Prevention**: Cannot merge a record with itself
3. **Existence Check**: Both customer records must exist in the database
4. **Merge Status Check**: Neither record can already be marked as merged

## Audit Trail

### Merge Tracking

The loser record is updated with merge tracking:

-   `Is_Merged__c` = true
-   `Merged_Into__c` = winner's ID
-   `Merged_On__c` = current timestamp

## Error Handling

### Validation Errors

```apex
CustomerMerger.MergeResult result = CustomerMerger.mergeCustomers(id1, id2);
if (!result.success) {
    // Common validation errors:
    // - "Both winner and loser customer IDs must be provided"
    // - "Cannot merge a customer record with itself"
    // - "One or both customer records not found"
    // - "Customer {id} is already merged into another record"
}
```

### DML Errors

-   Uses database savepoints for transaction safety
-   Rolls back all changes if any DML operation fails
-   Provides detailed error messages for debugging

### Runtime Errors

-   Catches and logs all unexpected exceptions
-   Returns failure result with error details
-   Maintains system stability even with data issues

## Return Values

### MergeResult Class

```apex
public class MergeResult {
	public Boolean success; // Operation success status
	public String errorMessage; // Error details if failed
	public Id winnerId; // ID of the winning customer
	public Id loserId; // ID of the merged customer
	public DateTime mergedOn; // Timestamp of merge operation
}
```

## Performance Considerations

### Governor Limits

-   **SOQL Queries**: 2 queries per merge operation
    -   1 for validation (light query)
    -   1 for data fetch (full fields)
-   **DML Operations**: 2 updates per merge
    -   1 for winner (consolidated data)
    -   1 for loser (merge status)
-   **CPU Time**: Minimal overhead for data consolidation logic

### Bulk Operations

The service is designed for individual merge operations. For bulk merging:

```apex
List<CustomerMerger.MergeResult> results = new List<CustomerMerger.MergeResult>();

for (DuplicatePair pair : duplicatePairs) {
    CustomerMerger.MergeResult result = CustomerMerger.mergeCustomers(
        pair.winnerId,
        pair.loserId
    );
    results.add(result);

    if (!result.success) {
        System.debug('Failed to merge: ' + result.errorMessage);
    }
}
```

## Integration Points

### With DuplicateApi

-   Called automatically during `POST /duplicates/{id}/resolve` with action "merge"
-   Provides detailed success/failure feedback to API responses
-   Handles all customer data consolidation logic

### With BatchDuplicateScan

-   Creates `Duplicate_Match__c` records that can be resolved via this service
-   No direct integration - works through DuplicateApi workflow

### Future Integrations

The service is designed to handle related record updates:

```apex
// Placeholder for future related object support
private static void updateRelatedRecords(Id oldCustomerId, Id newCustomerId) {
    // Future: Update Orders__c.Customer__c references
    // Future: Update Support_Cases__c.Customer__c references
    // Future: Update Customer_Preferences__c.Customer__c references
}
```

## Testing

### Test Class Coverage

`CustomerMergerTest` provides comprehensive test coverage:

-   ✅ Successful merge scenarios
-   ✅ Data consolidation logic
-   ✅ Validation error cases
-   ✅ Edge cases (identical data, partial data)
-   ✅ Error handling and rollback

### Manual Testing

```apex
// Create test customers
Customer__c winner = new Customer__c(
    FirstName__c = 'John',
    LastName__c = 'Smith',
    Email__c = 'john@test.com'
);

Customer__c loser = new Customer__c(
    FirstName__c = 'J',
    LastName__c = 'Smith-Johnson',
    Email__c = 'j.smith@test.com'
);

insert new List<Customer__c>{ winner, loser };

// Test merge
CustomerMerger.MergeResult result = CustomerMerger.mergeCustomers(winner.Id, loser.Id);

// Verify results
System.debug('Success: ' + result.success);
System.debug('Winner ID: ' + result.winnerId);
System.debug('Loser ID: ' + result.loserId);

// Check consolidated data
Customer__c merged = [SELECT FirstName__c, LastName__c, Email__c FROM Customer__c WHERE Id = :winner.Id];
System.debug('Merged name: ' + merged.FirstName__c + ' ' + merged.LastName__c);
System.debug('Merged email: ' + merged.Email__c);

// Verify loser status
Customer__c mergedLoser = [SELECT Is_Merged__c, Merged_Into__c FROM Customer__c WHERE Id = :loser.Id];
System.debug('Loser merged: ' + mergedLoser.Is_Merged__c);
System.debug('Merged into: ' + mergedLoser.Merged_Into__c);
```

## Monitoring and Debugging

### Debug Logs

The service provides detailed logging:

```
CustomerMerger: Successfully merged customer a03xx0000001ABC into a03xx0000001DEF
CustomerMerger: Related record updates not yet implemented
```

### Error Logging

```
CustomerMerger DML Error: REQUIRED_FIELD_MISSING: Required fields are missing
CustomerMerger Exception: System.NullPointerException: Attempt to de-reference a null object
Stack trace: Class.CustomerMerger.mergeCustomers: line 45, column 1
```

### Best Practices

-   **Monitor Batch Jobs**: Check for merge failures in scheduled operations
-   **Review Error Logs**: Investigate validation failures for data quality issues
-   **Track Merge History**: Monitor merge patterns for process improvement
-   **Performance Testing**: Monitor governor limit usage in bulk scenarios

## Future Enhancements

-   **Configurable Merge Rules**: Allow admin configuration of merge strategies
-   **Related Record Handling**: Automatic update of related objects
-   **Undo Functionality**: Ability to reverse merge operations
-   **Advanced Conflict Resolution**: UI for manual conflict resolution
-   **Machine Learning Integration**: AI-powered merge recommendations

## Dependencies

### Required Objects

-   `Customer__c` with fields:
    -   `FirstName__c`, `LastName__c`, `Email__c`, `Phone__c`
    -   `SignupDate__c`, `Is_Merged__c`, `Merged_Into__c`, `Merged_On__c`

### Required Permissions

-   Read/Write access to `Customer__c` object
-   Execute permission on `CustomerMerger` class (via permission set)

### Related Components

-   [`DuplicateApi`](../../resources/README.md) - REST API that calls this service
-   [`BatchDuplicateScan`](../batchable-dup-scan/README.md) - Creates duplicate matches
-   [`Duplicate_Management_Access`](../../../permissionsets/README.md) - Required permissions
