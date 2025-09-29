# Duplicate Customer Management API

This REST API provides endpoints for managing duplicate customer records in the ShopNow Salesforce application. The API allows you to retrieve pending duplicate matches and resolve them by either merging customers or marking matches as ignored.

## Base URL

```
https://[your-salesforce-instance].salesforce.com/services/apexrest/duplicates
```

## Authentication

All API calls require Salesforce authentication using one of the following methods:

-   **Session ID**: Include `Authorization: Bearer [session_id]` header
-   **OAuth 2.0**: Use OAuth flow to obtain access token
-   **Connected App**: Use JWT bearer token flow

## Endpoints

### 1. Get Pending Duplicate Matches

Retrieves a list of pending duplicate customer matches that require review.

**Endpoint:** `GET /services/apexrest/duplicates/pending`

#### Query Parameters

| Parameter  | Type    | Default | Max | Description                            |
| ---------- | ------- | ------- | --- | -------------------------------------- |
| `limit`    | Integer | 200     | 500 | Maximum number of records to return    |
| `minScore` | Integer | 0       | -   | Minimum match score to include (0-100) |

#### Response Format

```json
{
	"success": true,
	"count": 25,
	"matches": [
		{
			"id": "a05XX0000004CCCYAY",
			"score": 95.5,
			"customerA": {
				"id": "a04XX0000008ABCYAY",
				"name": "John Smith",
				"email": "john.smith@email.com",
				"phone": "+1-555-0123"
			},
			"customerB": {
				"id": "a04XX0000008DEFYAY",
				"name": "J. Smith",
				"email": "j.smith@email.com",
				"phone": "+1-555-0123"
			}
		}
	]
}
```

#### Example Requests

**Basic request:**

```bash
curl -X GET \
  "https://yourinstance.salesforce.com/services/apexrest/duplicates/pending" \
  -H "Authorization: Bearer YOUR_SESSION_ID" \
  -H "Content-Type: application/json"
```

**With query parameters:**

```bash
curl -X GET \
  "https://yourinstance.salesforce.com/services/apexrest/duplicates/pending?limit=50&minScore=80" \
  -H "Authorization: Bearer YOUR_SESSION_ID" \
  -H "Content-Type: application/json"
```

**JavaScript example:**

```javascript
const response = await fetch("/services/apexrest/duplicates/pending?limit=100&minScore=70", {
	method: "GET",
	headers: {
		Authorization: "Bearer " + sessionId,
		"Content-Type": "application/json"
	}
});

const data = await response.json();
if (data.success) {
	console.log(`Found ${data.count} pending duplicates`);
	data.matches.forEach((match) => {
		console.log(
			`Match ${match.id}: ${match.customerA.name} vs ${match.customerB.name} (${match.score}% similarity)`
		);
	});
}
```

### 2. Resolve Duplicate Match

Resolves a pending duplicate match by either merging the customers or marking the match as ignored.

**Endpoint:** `POST /services/apexrest/duplicates/{matchId}/resolve`

#### Path Parameters

| Parameter | Type   | Description                                                             |
| --------- | ------ | ----------------------------------------------------------------------- |
| `matchId` | String | The 15 or 18 character Salesforce ID of the Duplicate_Match\_\_c record |

#### Request Body

```json
{
  "action": "merge" | "ignore"
}
```

#### Response Format

**Successful merge:**

```json
{
	"result": "ok",
	"message": "Customers successfully merged",
	"winnerId": "a04XX0000008ABCYAY",
	"loserId": "a04XX0000008DEFYAY"
}
```

**Successful ignore:**

```json
{
	"result": "ok",
	"message": "Match successfully ignored"
}
```

**Error response:**

```json
{
	"result": "error",
	"message": "Match is not in pending status. Current status: Merged"
}
```

#### Example Requests

**Merge customers:**

```bash
curl -X POST \
  "https://yourinstance.salesforce.com/services/apexrest/duplicates/a05XX0000004CCCYAY/resolve" \
  -H "Authorization: Bearer YOUR_SESSION_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "merge"
  }'
```

**Ignore match:**

```bash
curl -X POST \
  "https://yourinstance.salesforce.com/services/apexrest/duplicates/a05XX0000004CCCYAY/resolve" \
  -H "Authorization: Bearer YOUR_SESSION_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "ignore"
  }'
```

**JavaScript example:**

```javascript
async function resolveMatch(matchId, action) {
	const response = await fetch(`/services/apexrest/duplicates/${matchId}/resolve`, {
		method: "POST",
		headers: {
			Authorization: "Bearer " + sessionId,
			"Content-Type": "application/json"
		},
		body: JSON.stringify({ action: action })
	});

	const result = await response.json();

	if (result.result === "ok") {
		if (action === "merge") {
			console.log(`Customers merged successfully. Winner: ${result.winnerId}, Loser: ${result.loserId}`);
		} else {
			console.log("Match marked as ignored");
		}
	} else {
		console.error("Error:", result.message);
	}

	return result;
}

// Usage examples
await resolveMatch("a05XX0000004CCCYAY", "merge");
await resolveMatch("a05XX0000004DDDYAY", "ignore");
```

## Merge Logic

When resolving a duplicate match with the "merge" action, the system uses the following rules to determine which customer becomes the "winner":

### Winner Selection Rules (in order of precedence):

1. **Data Completeness**: Customer with more filled fields wins
    - Fields considered: FirstName**c, LastName**c, Email**c, Phone**c
2. **Signup Date**: If completeness is tied, more recent signup date wins
3. **ID Comparison**: Final tie-breaker uses Salesforce ID comparison for consistency

### Merge Process:

1. **Field Merging**: Non-null fields from the loser are copied to winner where winner fields are null
2. **Loser Update**: Loser record is marked as merged (`Is_Merged__c = true`)
3. **Audit Trail**: Merge timestamp and winner reference are recorded on loser
4. **Match Status**: Duplicate match status is updated to "Merged"

## Response Codes

| Code | Description                                                   |
| ---- | ------------------------------------------------------------- |
| 200  | Success                                                       |
| 400  | Bad Request (invalid parameters or request body)              |
| 404  | Duplicate match not found                                     |
| 409  | Conflict (match already resolved or customers already merged) |
| 500  | Internal Server Error                                         |

## Error Handling

### Common Error Scenarios:

**Invalid match ID:**

```json
{
	"result": "error",
	"message": "Missing or invalid match ID in URL path"
}
```

**Match already resolved:**

```json
{
	"result": "error",
	"message": "Match is not in pending status. Current status: Merged"
}
```

**Customers already merged:**

```json
{
	"result": "error",
	"message": "One or both customers are already merged"
}
```

**Invalid action:**

```json
{
	"result": "error",
	"message": "Invalid action. Must be \"merge\" or \"ignore\""
}
```

## Best Practices

### 1. Pagination

For large datasets, use the `limit` parameter to control response size:

```javascript
// Process duplicates in batches
let processedCount = 0;
const batchSize = 50;

do {
	const response = await fetch(`/services/apexrest/duplicates/pending?limit=${batchSize}&minScore=70`);
	const data = await response.json();

	// Process batch
	for (const match of data.matches) {
		await processMatch(match);
	}

	processedCount += data.count;
} while (data.count === batchSize);
```

### 2. Error Handling

Always check response status and handle errors appropriately:

```javascript
async function safeResolveMatch(matchId, action) {
	try {
		const response = await fetch(`/services/apexrest/duplicates/${matchId}/resolve`, {
			method: "POST",
			headers: {
				Authorization: "Bearer " + sessionId,
				"Content-Type": "application/json"
			},
			body: JSON.stringify({ action: action })
		});

		if (!response.ok) {
			throw new Error(`HTTP ${response.status}: ${response.statusText}`);
		}

		const result = await response.json();

		if (result.result !== "ok") {
			throw new Error(result.message);
		}

		return result;
	} catch (error) {
		console.error("Failed to resolve match:", error.message);
		throw error;
	}
}
```

### 3. Filtering by Score

Use `minScore` to focus on high-confidence matches:

-   **90-100**: Very high confidence, likely safe to auto-merge
-   **70-89**: High confidence, good candidates for review
-   **50-69**: Medium confidence, requires careful review
-   **0-49**: Low confidence, may be false positives

### 4. Bulk Processing

For processing multiple matches, consider implementing retry logic:

```javascript
async function bulkResolveMatches(decisions) {
	const results = [];

	for (const decision of decisions) {
		let attempt = 0;
		const maxAttempts = 3;

		while (attempt < maxAttempts) {
			try {
				const result = await resolveMatch(decision.matchId, decision.action);
				results.push({ ...decision, result });
				break;
			} catch (error) {
				attempt++;
				if (attempt === maxAttempts) {
					results.push({ ...decision, error: error.message });
				} else {
					await new Promise((resolve) => setTimeout(resolve, 1000 * attempt)); // Exponential backoff
				}
			}
		}
	}

	return results;
}
```

## Integration Examples

### Lightning Web Component Integration

```javascript
// duplicateManager.js
import { LightningElement, track } from "lwc";

export default class DuplicateManager extends LightningElement {
	@track duplicates = [];
	@track loading = false;

	async connectedCallback() {
		await this.loadDuplicates();
	}

	async loadDuplicates() {
		this.loading = true;
		try {
			const response = await fetch("/services/apexrest/duplicates/pending?limit=20&minScore=70");
			const data = await response.json();

			if (data.success) {
				this.duplicates = data.matches;
			}
		} catch (error) {
			console.error("Error loading duplicates:", error);
		} finally {
			this.loading = false;
		}
	}

	async handleResolve(event) {
		const { matchId, action } = event.detail;

		try {
			const response = await fetch(`/services/apexrest/duplicates/${matchId}/resolve`, {
				method: "POST",
				headers: { "Content-Type": "application/json" },
				body: JSON.stringify({ action })
			});

			const result = await response.json();

			if (result.result === "ok") {
				// Remove resolved match from list
				this.duplicates = this.duplicates.filter((dup) => dup.id !== matchId);
				this.showSuccess(`Match ${action}d successfully`);
			} else {
				this.showError(result.message);
			}
		} catch (error) {
			this.showError("Failed to resolve match");
		}
	}
}
```

### Apex Integration

```apex
// Example: Batch processing duplicates
public class DuplicateProcessor {
	public static void processHighConfidenceMatches() {
		// Get high-confidence matches
		Http http = new Http();
		HttpRequest request = new HttpRequest();
		request.setEndpoint('/services/apexrest/duplicates/pending?minScore=95&limit=100');
		request.setMethod('GET');
		request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());

		HttpResponse response = http.send(request);

		if (response.getStatusCode() == 200) {
			Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
			List<Object> matches = (List<Object>) result.get('matches');

			// Auto-merge very high confidence matches
			for (Object matchObj : matches) {
				Map<String, Object> match = (Map<String, Object>) matchObj;
				String matchId = (String) match.get('id');
				Double score = (Double) match.get('score');

				if (score >= 98.0) {
					mergeMatch(matchId);
				}
			}
		}
	}

	private static void mergeMatch(String matchId) {
		Http http = new Http();
		HttpRequest request = new HttpRequest();
		request.setEndpoint('/services/apexrest/duplicates/' + matchId + '/resolve');
		request.setMethod('POST');
		request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
		request.setHeader('Content-Type', 'application/json');
		request.setBody('{"action": "merge"}');

		HttpResponse response = http.send(request);

		System.debug('Merge result for ' + matchId + ': ' + response.getBody());
	}
}
```

## Related Objects

### Duplicate_Match\_\_c Fields

| Field            | Type     | Description                              |
| ---------------- | -------- | ---------------------------------------- |
| Customer_A\_\_c  | Lookup   | Reference to first customer              |
| Customer_B\_\_c  | Lookup   | Reference to second customer             |
| Match_Score\_\_c | Number   | Similarity score (0-100)                 |
| Status\_\_c      | Picklist | "Pending Review", "Merged", or "Ignored" |
| Pair_Key\_\_c    | Text     | Unique key for customer pair             |

### Customer\_\_c Fields

| Field            | Type     | Description                          |
| ---------------- | -------- | ------------------------------------ |
| FirstName\_\_c   | Text     | Customer first name                  |
| LastName\_\_c    | Text     | Customer last name                   |
| Email\_\_c       | Email    | Customer email address               |
| Phone\_\_c       | Phone    | Customer phone number                |
| SignupDate\_\_c  | Date     | Customer signup date                 |
| Is_Merged\_\_c   | Checkbox | Whether customer has been merged     |
| Merged_Into\_\_c | Lookup   | Reference to winning customer record |
| Merged_On\_\_c   | DateTime | When the merge occurred              |

For more information about the duplicate detection process, see the BatchDuplicateScan and DedupeService classes.
