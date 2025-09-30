# DuplicateApi.cls - REST API for Customer Duplicate Management

A Salesforce Apex REST API for managing duplicate customer records. This API provides endpoints to retrieve pending duplicate matches and resolve them through merge or ignore actions.

## Overview

The `DuplicateApi` class provides a RESTful interface for:

-   Retrieving pending duplicate customer matches with similarity scores
-   Resolving duplicates by merging or ignoring them
-   Managing duplicate workflow status

## API Endpoints

### Base URL

```
/services/apexrest/duplicates/
```

## Endpoints

### 1. Get Pending Duplicates

**GET** `/services/apexrest/duplicates/pending`

Retrieves all duplicate matches with status 'Pending Review', ordered by match score (highest first).

#### Response Format

```json
[
	{
		"id": "a003000000AbCdEf",
		"matchScore": 85,
		"status": "Pending Review",
		"customerA": {
			"id": "a013000000XyZwVu",
			"firstName": "John",
			"lastName": "Smith",
			"email": "john.smith@email.com",
			"phone": "+1-555-0123"
		},
		"customerB": {
			"id": "a013000000AbCdEf",
			"firstName": "Jon",
			"lastName": "Smith",
			"email": "j.smith@email.com",
			"phone": "+1-555-0123"
		}
	}
]
```

#### Example Usage

**Using cURL:**

```bash
curl -X GET \
  "https://your-org.salesforce.com/services/apexrest/duplicates/pending" \
  -H "Authorization: Bearer YOUR_SESSION_TOKEN" \
  -H "Content-Type: application/json"
```

**Using JavaScript/Fetch:**

```javascript
const response = await fetch("/services/apexrest/duplicates/pending", {
	method: "GET",
	headers: {
		Authorization: "Bearer " + sessionToken,
		"Content-Type": "application/json"
	}
});
const duplicates = await response.json();
```

**Using Apex:**

```apex
// Call from another Apex class
List<DuplicateApi.DuplicateMatchResponse> pendingDuplicates = DuplicateApi.getPendingDuplicates();
```

### 2. Resolve Duplicate

**POST** `/services/apexrest/duplicates/{duplicateId}/resolve`

Resolves a duplicate match by either merging the customers or marking as ignored.

#### Request Body

```json
{
  "action": "merge" | "ignore"
}
```

#### Response Format

```json
{
	"success": true,
	"message": "Duplicate match resolved successfully with action: merge"
}
```

#### Example Usage

**Merge Customers:**

```bash
curl -X POST \
  "https://your-org.salesforce.com/services/apexrest/duplicates/a003000000AbCdEf/resolve" \
  -H "Authorization: Bearer YOUR_SESSION_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action": "merge"}'
```

**Ignore Duplicate:**

```bash
curl -X POST \
  "https://your-org.salesforce.com/services/apexrest/duplicates/a003000000AbCdEf/resolve" \
  -H "Authorization: Bearer YOUR_SESSION_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action": "ignore"}'
```

**Using JavaScript:**

```javascript
// Merge duplicate
const mergeResponse = await fetch(`/services/apexrest/duplicates/${duplicateId}/resolve`, {
	method: "POST",
	headers: {
		Authorization: "Bearer " + sessionToken,
		"Content-Type": "application/json"
	},
	body: JSON.stringify({ action: "merge" })
});

// Ignore duplicate
const ignoreResponse = await fetch(`/services/apexrest/duplicates/${duplicateId}/resolve`, {
	method: "POST",
	headers: {
		Authorization: "Bearer " + sessionToken,
		"Content-Type": "application/json"
	},
	body: JSON.stringify({ action: "ignore" })
});
```

## Error Handling

The API returns appropriate HTTP status codes and error messages:

-   **400 Bad Request**: Invalid request format or missing parameters
-   **404 Not Found**: Duplicate match ID not found
-   **409 Conflict**: Duplicate already resolved
-   **500 Internal Server Error**: Server-side processing error

### Error Response Format

```json
{
	"success": false,
	"message": "Error description here"
}
```

Or for 500 errors:

```json
{
	"error": "Internal Server Error",
	"message": "Failed to retrieve pending duplicates: [error details]"
}
```

## Common Usage Patterns

### 1. Complete Workflow Example

```javascript
// 1. Get all pending duplicates
const pendingDuplicates = await fetch("/services/apexrest/duplicates/pending").then((response) => response.json());

// 2. Present to user for review
pendingDuplicates.forEach((duplicate) => {
	console.log(`Match Score: ${duplicate.matchScore}%`);
	console.log(`Customer A: ${duplicate.customerA.firstName} ${duplicate.customerA.lastName}`);
	console.log(`Customer B: ${duplicate.customerB.firstName} ${duplicate.customerB.lastName}`);
});

// 3. Resolve based on user decision
const duplicateId = pendingDuplicates[0].id;
const resolution = await fetch(`/services/apexrest/duplicates/${duplicateId}/resolve`, {
	method: "POST",
	headers: { "Content-Type": "application/json" },
	body: JSON.stringify({ action: "merge" })
});
```

### 2. Batch Processing

```apex
// Process multiple duplicates in Apex
List<DuplicateApi.DuplicateMatchResponse> pendingDuplicates = DuplicateApi.getPendingDuplicates();

for (DuplicateApi.DuplicateMatchResponse duplicate : pendingDuplicates) {
    if (duplicate.matchScore >= 90) {
        // Auto-merge high confidence matches
        // Note: You'd need to call the REST endpoint or implement similar logic
    }
}
```

## Dependencies

-   Custom Objects: `Duplicate_Match__c`, `Customer__c`
-   Required Fields: Match_Score**c, Status**c, Customer_A**c, Customer_B**c
-   Customer Fields: FirstName**c, LastName**c, Email**c, Phone**c

## Notes

-   The merge action currently only updates the status to 'Merged' - actual customer record merging logic needs to be implemented
-   Results are ordered by match score (descending) and creation date (newest first)
-   Only duplicates with status 'Pending Review' are returned by the GET endpoint
-   The API uses Salesforce's standard REST authentication mechanisms

## Security

-   Uses `with sharing` keyword to respect Salesforce sharing rules
-   Requires appropriate object and field-level permissions for `Duplicate_Match__c` and `Customer__c` objects
-   REST endpoint access controlled by Salesforce profile/permission set configuration
