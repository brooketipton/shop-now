# BatchDuplicateScan

A Salesforce batch job that automatically scans Customer\_\_c records to identify potential duplicates using intelligent matching algorithms.

## Overview

The `BatchDuplicateScan` class implements `Database.Batchable<SObject>` and `Database.Stateful` to process customer records in chunks and identify potential duplicates based on email and phone number matching with sophisticated name similarity analysis.

## Features

-   **Automated Duplicate Detection**: Processes all unmerged customers to find potential duplicates
-   **Multiple Matching Rules**: Uses a tiered approach with different confidence scores
-   **Stateful Tracking**: Maintains statistics across batch executions
-   **Error Handling**: Robust error handling with detailed logging
-   **Duplicate Prevention**: Uses pair keys to prevent duplicate match records

## Matching Rules

The batch job applies three distinct matching rules with different confidence scores:

### Rule 1: Exact Email Match

-   **Score**: 100 (highest confidence)
-   **Logic**: Customers with identical email addresses (case-insensitive)
-   **Use Case**: Most reliable indicator of duplicate customers

### Rule 2: Phone + High Name Similarity

-   **Score**: 70 (medium-high confidence)
-   **Logic**: Same phone number + name similarity ≥ 90%
-   **Use Case**: Catches variations in name formatting (e.g., "John" vs "Jonathan")

### Rule 3: Phone + Exact Last Name

-   **Score**: 50 (medium confidence)
-   **Logic**: Same phone number + identical last name
-   **Use Case**: Family members or name variations with same surname

## Usage

### Basic Execution

```apex
// Execute with default batch size (200 records)
Database.executeBatch(new BatchDuplicateScan());
```

### Custom Batch Size

```apex
// Execute with custom batch size for performance tuning
Database.executeBatch(new BatchDuplicateScan(), 100);
```

### Scheduling

```apex
// Schedule to run daily at 2 AM
String cronExpression = '0 0 2 * * ?';
System.schedule('Daily Duplicate Scan', cronExpression, new BatchDuplicateScan());
```

## Dependencies

This class requires the following components:

-   **Custom Objects**:

    -   `Customer__c` - Customer records to scan
    -   `Duplicate_Match__c` - Stores potential duplicate pairs

-   **Utility Classes**:

    -   `StringUtil.normalizePhone()` - Phone number normalization
    -   `StringUtil.normalizeName()` - Name normalization
    -   `SimilarityScorer.calculateSimilarity()` - Name similarity calculation

-   **Required Fields**:

    ```sql
    Customer__c:
      - Id, FirstName__c, LastName__c, Email__c, Phone__c
      - Is_Merged__c (to exclude already merged records)

    Duplicate_Match__c:
      - Customer_A__c, Customer_B__c, Match_Score__c
      - Status__c, Pair_Key__c
    ```

## Processing Logic

### 1. Start Phase

-   Queries all unmerged customers with email or phone
-   Orders by `LastModifiedDate DESC` for recent-first processing
-   Excludes already merged records (`Is_Merged__c = FALSE OR NULL`)

### 2. Execute Phase (per batch)

-   Groups customers by normalized email and phone
-   Applies matching rules to find potential duplicates
-   Creates `Duplicate_Match__c` records with unique pair keys
-   Tracks statistics and handles errors gracefully

### 3. Finish Phase

-   Logs comprehensive execution statistics
-   Reports any processing errors
-   Sends completion notifications (placeholder)

## Configuration

### Tunable Constants

```apex
private static final Integer EXACT_EMAIL_SCORE = 100;
private static final Integer PHONE_NAME_FUZZY_SCORE = 70;
private static final Integer PHONE_LASTNAME_SCORE = 50;
private static final Decimal NAME_SIMILARITY_THRESHOLD = 0.90;
```

## Monitoring

### Debug Logs

The batch job provides detailed logging at each stage:

```
BatchDuplicateScan: Starting batch job
BatchDuplicateScan: Processing batch of 200 records
BatchDuplicateScan: Created 15 duplicate match records in this batch
BatchDuplicateScan: Batch job completed
- Total records processed: 5000
- Total batches processed: 25
- Total potential matches found: 127
- Processing errors: 0
```

### Error Handling

-   **DML Errors**: Logged but don't stop the batch
-   **Processing Errors**: Captured per batch with stack traces
-   **Stateful Tracking**: Maintains error count across all batches

### Monitoring Batch Jobs

1. Go to **Setup** → **Apex Jobs**
2. Find your `BatchDuplicateScan` job
3. Monitor status and view logs

## Performance Considerations

### Query Optimization

-   Uses selective WHERE clause to exclude merged records
-   Orders by `LastModifiedDate DESC` for index efficiency
-   Limits fields to only those needed for matching

### Memory Management

-   Processes records in configurable batch sizes
-   Uses efficient Map-based grouping for O(1) lookups
-   Clears collections after each batch

### Governor Limits

-   **SOQL Queries**: 1 query in start() method
-   **DML Operations**: 1 insert operation per batch
-   **CPU Time**: Optimized for large datasets
-   **Heap Size**: Minimal memory footprint per batch

## Integration

### With DuplicateApi

The batch job creates `Duplicate_Match__c` records that can be:

-   Retrieved via `GET /duplicates/pending` endpoint
-   Resolved via `POST /duplicates/{id}/resolve` endpoint

### With Frontend

The React app displays matches found by this batch job in the `DuplicateTable` component.

## Testing

### Test Class

Use `BatchDuplicateScanTest` for comprehensive testing:

```apex
@IsTest
public class BatchDuplicateScanTest {
	// Tests all matching rules and error scenarios
}
```

### Manual Testing

```apex
// Create test data
List<Customer__c> testCustomers = new List<Customer__c>{
    new Customer__c(FirstName__c='John', LastName__c='Smith', Email__c='john@test.com'),
    new Customer__c(FirstName__c='J', LastName__c='Smith', Email__c='john@test.com')
};
insert testCustomers;

// Run batch
Database.executeBatch(new BatchDuplicateScan(), 10);

// Check results
List<Duplicate_Match__c> matches = [SELECT Id, Match_Score__c FROM Duplicate_Match__c];
System.debug('Found ' + matches.size() + ' potential duplicates');
```

## Troubleshooting

### Common Issues

1. **No matches found**

    - Verify customers have email or phone data
    - Check if records are already marked as merged
    - Review normalization logic in dependencies

2. **Performance issues**

    - Reduce batch size
    - Check for inefficient queries in dependencies
    - Monitor governor limit usage

3. **Duplicate pair keys error**
    - The system prevents duplicate match records
    - This is expected behavior, not an error

### Best Practices

-   **Schedule during off-hours** to minimize impact
-   **Monitor initial runs** before scheduling
-   **Regular cleanup** of resolved matches
-   **Batch size tuning** based on data volume

## Future Enhancements

-   Email notifications for batch completion
-   Platform events for real-time integration
-   Configurable matching rules via Custom Metadata
-   Advanced ML-based similarity scoring

## Related Components

-   [`DedupeService`](../dedupe/README.md) - Duplicate processing service
-   [`SimilarityScorer`](../similarity-scorer/README.md) - Name similarity algorithms
-   [`DuplicateApi`](../../resources/README.md) - REST API for duplicate management
-   [`StringUtil`](../../utilities/README.md) - String normalization utilities
