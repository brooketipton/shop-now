/**
 * Compact Duplicate API Test Script for Developer Console
 *
 * Instructions:
 * 1. Open Salesforce Developer Console
 * 2. Go to Debug > Open Execute Anonymous Window
 * 3. Copy and paste this script
 * 4. Check "Open Log" checkbox
 * 5. Click Execute
 */

System.debug('=== Duplicate API Test Started ===');

try {
	// Create test customers
	List<Customer__c> customers = new List<Customer__c>{
		new Customer__c(
			FirstName__c = 'John',
			LastName__c = 'Smith',
			Email__c = 'john@test.com',
			Phone__c = '555-0123'
		),
		new Customer__c(FirstName__c = 'J', LastName__c = 'Smith', Email__c = 'j@test.com', Phone__c = '555-0123'),
		new Customer__c(FirstName__c = 'Jane', LastName__c = 'Doe', Email__c = 'jane@test.com', Phone__c = '555-0456'),
		new Customer__c(FirstName__c = 'Jane', LastName__c = 'Doe', Email__c = 'jane@test.com', Phone__c = '555-0789')
	};
	insert customers;
	System.debug('Created ' + customers.size() + ' test customers');

	// Create test matches
	List<Duplicate_Match__c> matches = new List<Duplicate_Match__c>{
		new Duplicate_Match__c(
			Customer_A__c = customers[0].Id,
			Customer_B__c = customers[1].Id,
			Match_Score__c = 75.5,
			Status__c = 'Pending Review',
			Pair_Key__c = customers[0].Id + '|' + customers[1].Id
		),
		new Duplicate_Match__c(
			Customer_A__c = customers[2].Id,
			Customer_B__c = customers[3].Id,
			Match_Score__c = 100.0,
			Status__c = 'Pending Review',
			Pair_Key__c = customers[2].Id + '|' + customers[3].Id
		)
	};
	insert matches;
	System.debug('Created ' + matches.size() + ' test matches');

	// Test GET pending duplicates
	RestRequest req = new RestRequest();
	req.requestURI = '/services/apexrest/duplicates/pending?limit=10&minScore=50';
	// Manually set params map since it's not auto-populated in test context
	if (req.params == null) {
		req.params = new Map<String, String>();
	}
	req.params.put('limit', '10');
	req.params.put('minScore', '50');
	RestContext.request = req;
	RestContext.response = new RestResponse();

	DuplicateApi.PendingDuplicatesResponse getResp = DuplicateApi.getPendingDuplicates();
	System.debug('GET Success: ' + getResp.success + ', Count: ' + getResp.count);

	if (getResp.success && getResp.matches.size() > 0) {
		for (DuplicateApi.DuplicateMatchDto match : getResp.matches) {
			System.debug('Match: ' + match.id + ' Score: ' + match.score);
			System.debug('  A: ' + match.customerA.name + ' (' + match.customerA.email + ')');
			System.debug('  B: ' + match.customerB.name + ' (' + match.customerB.email + ')');
		}
	}

	// Test POST resolve - ignore
	if (matches.size() > 0) {
		RestRequest ignoreReq = new RestRequest();
		ignoreReq.requestURI = '/services/apexrest/duplicates/' + matches[0].Id + '/resolve';
		ignoreReq.requestBody = Blob.valueOf('{"action": "ignore"}');
		RestContext.request = ignoreReq;
		RestContext.response = new RestResponse();

		DuplicateApi.ResolveResponse ignoreResp = DuplicateApi.resolveDuplicate();
		System.debug('Ignore Result: ' + ignoreResp.result + ' - ' + ignoreResp.message);
	}

	// Test POST resolve - merge
	if (matches.size() > 1) {
		RestRequest mergeReq = new RestRequest();
		mergeReq.requestURI = '/services/apexrest/duplicates/' + matches[1].Id + '/resolve';
		mergeReq.requestBody = Blob.valueOf('{"action": "merge"}');
		RestContext.request = mergeReq;
		RestContext.response = new RestResponse();

		DuplicateApi.ResolveResponse mergeResp = DuplicateApi.resolveDuplicate();
		System.debug('Merge Result: ' + mergeResp.result + ' - ' + mergeResp.message);
		if (mergeResp.result == 'ok') {
			System.debug('Winner: ' + mergeResp.winnerId + ', Loser: ' + mergeResp.loserId);
		}
	}

	// Test error scenario
	RestRequest errorReq = new RestRequest();
	errorReq.requestURI = '/services/apexrest/duplicates/invalid_id/resolve';
	errorReq.requestBody = Blob.valueOf('{"action": "merge"}');
	RestContext.request = errorReq;
	RestContext.response = new RestResponse();

	DuplicateApi.ResolveResponse errorResp = DuplicateApi.resolveDuplicate();
	System.debug('Error Test: ' + errorResp.result + ' - ' + errorResp.message);
} catch (Exception e) {
	System.debug('ERROR: ' + e.getMessage());
} finally {
	// Cleanup
	try {
		delete [SELECT Id FROM Duplicate_Match__c WHERE Customer_A__r.Email__c LIKE '%@test.com'];
		delete [SELECT Id FROM Customer__c WHERE Email__c LIKE '%@test.com'];
		System.debug('Test data cleaned up');
	} catch (Exception ex) {
		System.debug('Cleanup error: ' + ex.getMessage());
	}
}

System.debug('=== Test Completed ===');
