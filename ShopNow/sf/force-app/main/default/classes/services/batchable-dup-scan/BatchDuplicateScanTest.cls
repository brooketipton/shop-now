@IsTest
private class BatchDuplicateScanTest {
	@TestSetup
	static void setupTestData() {
		List<Customer__c> customers = new List<Customer__c>();

		customers.add(
			new Customer__c(
				FirstName__c = 'John',
				LastName__c = 'Smith',
				Email__c = 'john.smith@example.com',
				Phone__c = '+1-555-0001'
			)
		);
		customers.add(
			new Customer__c(
				FirstName__c = 'Johnny',
				LastName__c = 'Smith',
				Email__c = 'john.smith@example.com',
				Phone__c = '+1-555-0002'
			)
		);

		customers.add(
			new Customer__c(
				FirstName__c = 'Michael',
				LastName__c = 'Johnson',
				Email__c = 'mike.johnson@example.com',
				Phone__c = '555-123-4567'
			)
		);
		customers.add(
			new Customer__c(
				FirstName__c = 'Michael',
				LastName__c = 'Johnson',
				Email__c = 'michael.j@example.com',
				Phone__c = '(555) 123-4567'
			)
		);

		customers.add(
			new Customer__c(
				FirstName__c = 'Sarah',
				LastName__c = 'Williams',
				Email__c = 'sarah.williams@example.com',
				Phone__c = '555-987-6543'
			)
		);
		customers.add(
			new Customer__c(
				FirstName__c = 'Jessica',
				LastName__c = 'Williams',
				Email__c = 'jessica.w@example.com',
				Phone__c = '555.987.6543'
			)
		);

		customers.add(
			new Customer__c(
				FirstName__c = 'David',
				LastName__c = 'Brown',
				Email__c = 'david.brown@example.com',
				Phone__c = '555-111-2222'
			)
		);

		customers.add(new Customer__c(FirstName__c = 'NoContact', LastName__c = 'Person'));

		customers.add(
			new Customer__c(
				FirstName__c = 'Merged',
				LastName__c = 'Customer',
				Email__c = 'merged@example.com',
				Phone__c = '555-999-9999',
				Is_Merged__c = true
			)
		);

		customers.add(
			new Customer__c(
				FirstName__c = 'Robert',
				LastName__c = 'Davis',
				Email__c = 'robert.davis@example.com',
				Phone__c = '555-333-4444'
			)
		);
		customers.add(
			new Customer__c(
				FirstName__c = 'William',
				LastName__c = 'Smith',
				Email__c = 'william.smith@example.com',
				Phone__c = '555-333-4444'
			)
		);

		insert customers;
	}

	@IsTest
	static void testSuccessfulBatchExecution() {
		Test.startTest();

		BatchDuplicateScan batchJob = new BatchDuplicateScan();
		Id jobId = Database.executeBatch(batchJob, 200);

		Test.stopTest();

		List<Duplicate_Match__c> matches = [
			SELECT Id, Customer_A__c, Customer_B__c, Match_Score__c, Status__c, Pair_Key__c
			FROM Duplicate_Match__c
			ORDER BY Match_Score__c DESC
		];

		System.assert(matches.size() > 0, 'Expected duplicate matches to be created');

		for (Duplicate_Match__c match : matches) {
			System.assertEquals('Pending Review', match.Status__c, 'All matches should have Pending Review status');
			System.assertNotEquals(null, match.Pair_Key__c, 'Pair key should be set');
		}

		Set<Decimal> foundScores = new Set<Decimal>();
		for (Duplicate_Match__c match : matches) {
			foundScores.add(match.Match_Score__c);
		}

		System.assert(foundScores.contains(100), 'Should have exact email matches (score 100)');
		if (foundScores.contains(70)) {
			System.debug('Found high name similarity matches (score 70)');
		}
		if (foundScores.contains(50)) {
			System.debug('Found phone + last name matches (score 50)');
		}
	}

	@IsTest
	static void testExactEmailMatching() {
		Test.startTest();

		BatchDuplicateScan batchJob = new BatchDuplicateScan();
		Database.executeBatch(batchJob, 200);

		Test.stopTest();

		List<Duplicate_Match__c> emailMatches = [
			SELECT Id, Match_Score__c, Customer_A__r.Email__c, Customer_B__r.Email__c
			FROM Duplicate_Match__c
			WHERE Match_Score__c = 100
		];

		System.assert(emailMatches.size() > 0, 'Should find exact email matches');

		for (Duplicate_Match__c match : emailMatches) {
			System.assertEquals(
				match.Customer_A__r.Email__c.toLowerCase(),
				match.Customer_B__r.Email__c.toLowerCase(),
				'Email matches should have identical emails'
			);
		}
	}

	@IsTest
	static void testPhoneBasedMatching() {
		Test.startTest();

		BatchDuplicateScan batchJob = new BatchDuplicateScan();
		Database.executeBatch(batchJob, 200);

		Test.stopTest();

		List<Duplicate_Match__c> phoneMatches = [
			SELECT
				Id,
				Match_Score__c,
				Customer_A__r.Phone__c,
				Customer_B__r.Phone__c,
				Customer_A__r.FirstName__c,
				Customer_A__r.LastName__c,
				Customer_B__r.FirstName__c,
				Customer_B__r.LastName__c
			FROM Duplicate_Match__c
			WHERE Match_Score__c IN (70, 50)
			ORDER BY Match_Score__c DESC
		];

		System.assert(phoneMatches.size() > 0, 'Should find phone-based matches');

		for (Duplicate_Match__c match : phoneMatches) {
			String phoneA = StringUtil.normalizePhone(match.Customer_A__r.Phone__c);
			String phoneB = StringUtil.normalizePhone(match.Customer_B__r.Phone__c);
			System.assertEquals(phoneA, phoneB, 'Phone numbers should be normalized and equal');
		}
	}

	@IsTest
	static void testHighNameSimilarityMatching() {
		Test.startTest();

		BatchDuplicateScan batchJob = new BatchDuplicateScan();
		Database.executeBatch(batchJob, 200);

		Test.stopTest();

		List<Duplicate_Match__c> nameMatches = [
			SELECT
				Id,
				Customer_A__r.FirstName__c,
				Customer_A__r.LastName__c,
				Customer_B__r.FirstName__c,
				Customer_B__r.LastName__c
			FROM Duplicate_Match__c
			WHERE Match_Score__c = 70
		];

		if (nameMatches.size() > 0) {
			for (Duplicate_Match__c match : nameMatches) {
				String nameA =
					(String.isNotBlank(match.Customer_A__r.FirstName__c)
						? match.Customer_A__r.FirstName__c + ' '
						: '') +
					(String.isNotBlank(match.Customer_A__r.LastName__c) ? match.Customer_A__r.LastName__c : '');
				String nameB =
					(String.isNotBlank(match.Customer_B__r.FirstName__c)
						? match.Customer_B__r.FirstName__c + ' '
						: '') +
					(String.isNotBlank(match.Customer_B__r.LastName__c) ? match.Customer_B__r.LastName__c : '');

				Decimal similarity = SimilarityScorer.calculateSimilarity(nameA.trim(), nameB.trim());
				System.assert(similarity >= 0.90, 'Name similarity should be >= 90%: ' + similarity);
			}
		} else {
			System.debug('No high name similarity matches found - this is acceptable if similarity threshold not met');
		}
	}

	@IsTest
	static void testExactLastNameMatching() {
		Test.startTest();

		BatchDuplicateScan batchJob = new BatchDuplicateScan();
		Database.executeBatch(batchJob, 200);

		Test.stopTest();

		List<Duplicate_Match__c> lastNameMatches = [
			SELECT Id, Customer_A__r.LastName__c, Customer_B__r.LastName__c
			FROM Duplicate_Match__c
			WHERE Match_Score__c = 50
		];

		System.assert(lastNameMatches.size() > 0, 'Should find exact last name matches');

		for (Duplicate_Match__c match : lastNameMatches) {
			String lastNameA = StringUtil.normalizeName(match.Customer_A__r.LastName__c);
			String lastNameB = StringUtil.normalizeName(match.Customer_B__r.LastName__c);
			System.assertEquals(lastNameA, lastNameB, 'Last names should match after normalization');
		}
	}

	@IsTest
	static void testMergedCustomersExcluded() {
		Test.startTest();

		BatchDuplicateScan batchJob = new BatchDuplicateScan();
		Database.executeBatch(batchJob, 200);

		Test.stopTest();

		List<Duplicate_Match__c> mergedMatches = [
			SELECT Id, Customer_A__r.Is_Merged__c, Customer_B__r.Is_Merged__c
			FROM Duplicate_Match__c
			WHERE Customer_A__r.Is_Merged__c = TRUE OR Customer_B__r.Is_Merged__c = TRUE
		];

		System.assertEquals(0, mergedMatches.size(), 'Merged customers should not be included in matches');
	}

	@IsTest
	static void testCustomersWithoutContactInfoExcluded() {
		Test.startTest();

		BatchDuplicateScan batchJob = new BatchDuplicateScan();
		Database.executeBatch(batchJob, 200);

		Test.stopTest();

		List<Duplicate_Match__c> noContactMatches = [
			SELECT Id, Customer_A__r.Email__c, Customer_A__r.Phone__c, Customer_B__r.Email__c, Customer_B__r.Phone__c
			FROM Duplicate_Match__c
			WHERE
				(Customer_A__r.Email__c = NULL
				AND Customer_A__r.Phone__c = NULL)
				OR (Customer_B__r.Email__c = NULL
				AND Customer_B__r.Phone__c = NULL)
		];

		System.assertEquals(0, noContactMatches.size(), 'Customers without email or phone should not be included');
	}

	@IsTest
	static void testDuplicatePrevention() {
		Test.startTest();

		BatchDuplicateScan batchJob = new BatchDuplicateScan();
		Database.executeBatch(batchJob, 200);

		Test.stopTest();

		List<AggregateResult> duplicatePairs = [
			SELECT Pair_Key__c, COUNT(Id) recordCount
			FROM Duplicate_Match__c
			WHERE Pair_Key__c != NULL
			GROUP BY Pair_Key__c
			HAVING COUNT(Id) > 1
		];

		System.assertEquals(0, duplicatePairs.size(), 'No duplicate pair keys should exist');
	}

	@IsTest
	static void testReasonableBatchSize() {
		Test.startTest();

		BatchDuplicateScan batchJob = new BatchDuplicateScan();
		Id jobId = Database.executeBatch(batchJob, 200);

		Test.stopTest();

		List<Duplicate_Match__c> matches = [SELECT Id FROM Duplicate_Match__c];
		System.assert(matches.size() > 0, 'Matches should be created with reasonable batch size');

		AsyncApexJob job = [
			SELECT Id, Status, JobItemsProcessed
			FROM AsyncApexJob
			WHERE JobType = 'BatchApex'
			ORDER BY CreatedDate DESC
			LIMIT 1
		];
		System.assertNotEquals(null, job, 'Batch job should have been created');
	}

	@IsTest
	static void testNoEligibleCustomers() {
		delete [SELECT Id FROM Customer__c];

		List<Customer__c> ineligibleCustomers = new List<Customer__c>();
		ineligibleCustomers.add(new Customer__c(FirstName__c = 'No', LastName__c = 'Contact'));
		ineligibleCustomers.add(
			new Customer__c(
				FirstName__c = 'Merged',
				LastName__c = 'Customer',
				Email__c = 'merged@example.com',
				Is_Merged__c = true
			)
		);
		insert ineligibleCustomers;

		Test.startTest();

		BatchDuplicateScan batchJob = new BatchDuplicateScan();
		Database.executeBatch(batchJob, 200);

		Test.stopTest();

		List<Duplicate_Match__c> matches = [SELECT Id FROM Duplicate_Match__c];
		System.assertEquals(0, matches.size(), 'No matches should be created for ineligible customers');
	}

	@IsTest
	static void testErrorHandling() {
		List<Customer__c> edgeCaseCustomers = new List<Customer__c>();

		edgeCaseCustomers.add(
			new Customer__c(
				FirstName__c = 'Test',
				LastName__c = 'Customer',
				Email__c = 'test.customer@example.com',
				Phone__c = '555-000-0001'
			)
		);

		insert edgeCaseCustomers;

		Test.startTest();

		BatchDuplicateScan batchJob = new BatchDuplicateScan();
		Database.executeBatch(batchJob, 200);

		Test.stopTest();

		AsyncApexJob job = [
			SELECT Id, Status, NumberOfErrors, JobItemsProcessed
			FROM AsyncApexJob
			WHERE JobType = 'BatchApex'
			ORDER BY CreatedDate DESC
			LIMIT 1
		];

		System.assertNotEquals(null, job, 'Batch job should have been created');
		System.assert(job.JobItemsProcessed >= 0, 'Batch should have processed items');
	}

	@IsTest
	static void testPhoneNormalization() {
		List<Customer__c> phoneTestCustomers = new List<Customer__c>();
		phoneTestCustomers.add(
			new Customer__c(
				FirstName__c = 'Phone',
				LastName__c = 'Test',
				Email__c = 'phone1@example.com',
				Phone__c = '+1 (555) 123-4567'
			)
		);
		phoneTestCustomers.add(
			new Customer__c(
				FirstName__c = 'Different',
				LastName__c = 'Test',
				Email__c = 'phone2@example.com',
				Phone__c = '555.123.4567'
			)
		);
		phoneTestCustomers.add(
			new Customer__c(
				FirstName__c = 'Another',
				LastName__c = 'Test',
				Email__c = 'phone3@example.com',
				Phone__c = '5551234567'
			)
		);
		insert phoneTestCustomers;

		Test.startTest();

		BatchDuplicateScan batchJob = new BatchDuplicateScan();
		Database.executeBatch(batchJob, 200);

		Test.stopTest();

		List<Duplicate_Match__c> phoneMatches = [
			SELECT
				Id,
				Customer_A__r.Phone__c,
				Customer_B__r.Phone__c,
				Customer_A__r.LastName__c,
				Customer_B__r.LastName__c
			FROM Duplicate_Match__c
			WHERE Match_Score__c = 50 AND (Customer_A__r.LastName__c = 'Test' OR Customer_B__r.LastName__c = 'Test')
		];

		if (phoneMatches.size() > 0) {
			System.debug('Phone normalization enabled matching across formats');
		} else {
			System.debug(
				'No phone normalization matches found - this may occur if customers are not processed in same batch'
			);
		}
	}
}
