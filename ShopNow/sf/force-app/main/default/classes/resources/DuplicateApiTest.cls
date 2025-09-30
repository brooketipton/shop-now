@IsTest
private class DuplicateApiTest {
	@TestSetup
	static void setupTestData() {
		List<Customer__c> testCustomers = new List<Customer__c>();

		Customer__c customerA = new Customer__c(
			FirstName__c = 'John',
			LastName__c = 'Smith',
			Email__c = 'john.smith@test.com',
			Phone__c = '555-1234',
			SignupDate__c = Date.today().addDays(-30)
		);
		testCustomers.add(customerA);

		Customer__c customerB = new Customer__c(
			FirstName__c = 'Jon',
			LastName__c = 'Smith',
			Email__c = 'jon.smith@test.com',
			Phone__c = '555-1234',
			SignupDate__c = Date.today().addDays(-25)
		);
		testCustomers.add(customerB);

		Customer__c customerC = new Customer__c(
			FirstName__c = 'Jane',
			LastName__c = 'Doe',
			Email__c = 'jane.doe@test.com',
			Phone__c = '555-5678',
			SignupDate__c = Date.today().addDays(-20)
		);
		testCustomers.add(customerC);

		insert testCustomers;

		List<Duplicate_Match__c> testMatches = new List<Duplicate_Match__c>();

		Duplicate_Match__c match1 = new Duplicate_Match__c(
			Customer_A__c = testCustomers[0].Id,
			Customer_B__c = testCustomers[1].Id,
			Match_Score__c = 92,
			Status__c = 'Pending Review',
			Pair_Key__c = 'key1'
		);
		testMatches.add(match1);

		Duplicate_Match__c match2 = new Duplicate_Match__c(
			Customer_A__c = testCustomers[0].Id,
			Customer_B__c = testCustomers[2].Id,
			Match_Score__c = 75,
			Status__c = 'Pending Review',
			Pair_Key__c = 'key2'
		);
		testMatches.add(match2);

		Duplicate_Match__c resolvedMatch = new Duplicate_Match__c(
			Customer_A__c = testCustomers[1].Id,
			Customer_B__c = testCustomers[2].Id,
			Match_Score__c = 85,
			Status__c = 'Merged',
			Pair_Key__c = 'key3'
		);
		testMatches.add(resolvedMatch);

		insert testMatches;
	}

	@IsTest
	static void testGetPendingDuplicates_Success() {
		Test.startTest();

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/duplicates/pending';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;

		List<DuplicateApi.DuplicateMatchResponse> result = DuplicateApi.getPendingDuplicates();

		Test.stopTest();

		System.assertNotEquals(null, result, 'Result should not be null');
		System.assertEquals(2, result.size(), 'Should return 2 pending matches');

		DuplicateApi.DuplicateMatchResponse firstMatch = result[0];
		System.assertEquals(92, firstMatch.matchScore, 'First match should have highest score');
		System.assertEquals('Pending Review', firstMatch.status, 'Status should be Pending Review');
		System.assertNotEquals(null, firstMatch.customerA, 'Customer A should not be null');
		System.assertNotEquals(null, firstMatch.customerB, 'Customer B should not be null');
		System.assertEquals('John', firstMatch.customerA.firstName, 'Customer A first name should match');
		System.assertEquals('Jon', firstMatch.customerB.firstName, 'Customer B first name should match');
	}

	@IsTest
	static void testResolveDuplicate_MergeSuccess() {
		Duplicate_Match__c testMatch = [
			SELECT Id, Customer_A__c, Customer_B__c
			FROM Duplicate_Match__c
			WHERE Status__c = 'Pending Review'
			LIMIT 1
		];

		Test.startTest();

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/duplicates/' + testMatch.Id + '/resolve';
		req.httpMethod = 'POST';
		req.requestBody = Blob.valueOf('{"action": "merge"}');
		RestContext.request = req;
		RestContext.response = res;

		DuplicateApi.ApiResponse result = DuplicateApi.resolveDuplicate();

		Test.stopTest();

		System.assertEquals(true, result.success, 'Merge should be successful');
		System.assert(result.message.contains('successfully merged'), 'Message should indicate successful merge');

		// Verify the match status was updated
		Duplicate_Match__c updatedMatch = [SELECT Status__c FROM Duplicate_Match__c WHERE Id = :testMatch.Id];
		System.assertEquals('Merged', updatedMatch.Status__c, 'Match status should be updated to Merged');
	}

	@IsTest
	static void testResolveDuplicate_IgnoreSuccess() {
		Duplicate_Match__c testMatch = [SELECT Id FROM Duplicate_Match__c WHERE Status__c = 'Pending Review' LIMIT 1];

		Test.startTest();

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/duplicates/' + testMatch.Id + '/resolve';
		req.httpMethod = 'POST';
		req.requestBody = Blob.valueOf('{"action": "ignore"}');
		RestContext.request = req;
		RestContext.response = res;

		DuplicateApi.ApiResponse result = DuplicateApi.resolveDuplicate();

		Test.stopTest();

		System.assertEquals(true, result.success, 'Ignore should be successful');
		System.assertEquals(
			'Duplicate match ignored successfully',
			result.message,
			'Message should indicate successful ignore'
		);

		Duplicate_Match__c updatedMatch = [SELECT Status__c FROM Duplicate_Match__c WHERE Id = :testMatch.Id];
		System.assertEquals('Ignored', updatedMatch.Status__c, 'Match status should be updated to Ignored');
	}

	@IsTest
	static void testResolveDuplicate_InvalidAction() {
		Duplicate_Match__c testMatch = [SELECT Id FROM Duplicate_Match__c WHERE Status__c = 'Pending Review' LIMIT 1];

		Test.startTest();

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/duplicates/' + testMatch.Id + '/resolve';
		req.httpMethod = 'POST';
		req.requestBody = Blob.valueOf('{"action": "invalid"}');
		RestContext.request = req;
		RestContext.response = res;

		DuplicateApi.ApiResponse result = DuplicateApi.resolveDuplicate();

		Test.stopTest();

		System.assertEquals(false, result.success, 'Should fail with invalid action');
		System.assertEquals(
			'Invalid action. Must be "merge" or "ignore"',
			result.message,
			'Should return invalid action message'
		);
		System.assertEquals(400, RestContext.response.statusCode, 'Should return 400 status code');
	}
}
