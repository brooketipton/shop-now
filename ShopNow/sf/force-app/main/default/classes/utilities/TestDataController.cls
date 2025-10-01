/**
 * Controller class for generating comprehensive test customer data for duplicate detection testing.
 *
 * This class creates various customer scenarios to thoroughly test BatchDuplicateScan logic:
 * - Exact email duplicates (Score 100): Email matches with case/whitespace variations
 * - Phone + high name similarity (Score 70): ≥90% Jaro-Winkler similarity + same phone
 * - Phone + exact last name (Score 50): Same phone + identical last names
 * - Edge cases: Missing fields, international characters, normalization tests
 * - Negative cases: Scenarios that should NOT match to verify scoring accuracy
 * - Unique customers: Clean records with no duplicates
 */
public with sharing class TestDataController {
	public class TestDataResult {
		@AuraEnabled
		public Boolean success;
		@AuraEnabled
		public String message;
		@AuraEnabled
		public Integer customersCreated;
		@AuraEnabled
		public List<String> errors;

		public TestDataResult() {
			this.success = true;
			this.customersCreated = 0;
			this.errors = new List<String>();
		}
	}

	/**
	 * Generates a set of test customer data for duplicate detection testing
	 * Creates various scenarios including exact duplicates, close duplicates, and
	 * completley unique customers
	 *
	 * @return TestDataResult with operation details
	 */
	@AuraEnabled
	public static TestDataResult generateTestData() {
		TestDataResult result = new TestDataResult();

		try {
			List<Customer__c> testCustomers = new List<Customer__c>();

			testCustomers.addAll(createExactEmailDuplicates());
			testCustomers.addAll(createPhoneNameSimilarDuplicates());
			testCustomers.addAll(createPhoneLastNameDuplicates());
			testCustomers.addAll(createUniqueCustomers());
			testCustomers.addAll(createEdgeCaseCustomers());
			testCustomers.addAll(createNegativeTestCases());

			insert testCustomers;

			result.customersCreated = testCustomers.size();
			result.message = String.format(
				'Successfully created {0} test customers across multiple duplicate scenarios',
				new List<Object>{ result.customersCreated }
			);
		} catch (DmlException e) {
			result.success = false;
			result.message = 'Failed to create test data due to database error';
			result.errors.add('DML Error: ' + e.getMessage());
		} catch (Exception e) {
			result.success = false;
			result.message = 'Unexpected error occurred while creating test data';
			result.errors.add('Error: ' + e.getMessage());
		}

		return result;
	}

	/**
	 * Clears all existing customer and duplicate match data.
	 * Use with caution - this deletes ALL customer data!
	 *
	 * @return TestDataResult with operation details
	 */
	@AuraEnabled
	public static TestDataResult clearAllData() {
		TestDataResult result = new TestDataResult();

		try {
			List<Duplicate_Match__c> allMatches = [SELECT Id FROM Duplicate_Match__c];
			if (!allMatches.isEmpty()) {
				delete allMatches;
			}

			List<Customer__c> allCustomers = [SELECT Id FROM Customer__c];
			if (!allCustomers.isEmpty()) {
				delete allCustomers;
			}

			result.message = String.format(
				'Successfully deleted {0} customers and {1} duplicate matches',
				new List<Object>{ allCustomers.size(), allMatches.size() }
			);
		} catch (DmlException e) {
			result.success = false;
			result.message = 'Failed to clear data due to database error';
			result.errors.add('DML Error: ' + e.getMessage());
		} catch (Exception e) {
			result.success = false;
			result.message = 'Unexpected error occurred while clearing data';
			result.errors.add('Error: ' + e.getMessage());
		}

		return result;
	}

	private static List<Customer__c> createExactEmailDuplicates() {
		return new List<Customer__c>{
			// Score 100: Exact email match with case variations
			new Customer__c(
				FirstName__c = 'John',
				LastName__c = 'Smith',
				Email__c = 'john.smith@example.com',
				Phone__c = '555-123-4567',
				SignupDate__c = Date.today().addDays(-30)
			),
			new Customer__c(
				FirstName__c = 'Johnny',
				LastName__c = 'Smith',
				Email__c = 'JOHN.SMITH@EXAMPLE.COM', // Case variation - should still match
				Phone__c = '5551234567',
				SignupDate__c = Date.today().addDays(-25)
			),
			new Customer__c(
				FirstName__c = 'J.',
				LastName__c = 'Smith Jr.',
				Email__c = '  john.smith@example.com  ', // Whitespace - should still match
				Phone__c = '555-123-4567',
				SignupDate__c = Date.today().addDays(-23)
			),
			// Score 100: Another exact email group
			new Customer__c(
				FirstName__c = 'Sarah',
				LastName__c = 'Johnson',
				Email__c = 'sarah.johnson@test.com',
				Phone__c = '555-987-6543',
				SignupDate__c = Date.today().addDays(-20)
			),
			new Customer__c(
				FirstName__c = 'Sara',
				LastName__c = 'Johnson-Miller',
				Email__c = 'sarah.johnson@test.com',
				Phone__c = '555-987-6543',
				SignupDate__c = Date.today().addDays(-18)
			),
			// Score 100: Corporate email duplicates
			new Customer__c(
				FirstName__c = 'Michael',
				LastName__c = 'Davis',
				Email__c = 'mdavis@company.org',
				Phone__c = '555-111-2222',
				SignupDate__c = Date.today().addDays(-15)
			),
			new Customer__c(
				FirstName__c = 'Mike',
				LastName__c = 'Davis',
				Email__c = 'mdavis@company.org',
				Phone__c = '555-111-2223', // Different phone - should still match on email
				SignupDate__c = Date.today().addDays(-12)
			)
		};
	}

	private static List<Customer__c> createPhoneNameSimilarDuplicates() {
		return new List<Customer__c>{
			// Score 70: High name similarity (≥90%) + same phone
			new Customer__c(
				FirstName__c = 'Michael',
				LastName__c = 'Anderson',
				Email__c = 'mike.anderson@email.com',
				Phone__c = '555-555-1234',
				SignupDate__c = Date.today().addDays(-15)
			),
			new Customer__c(
				FirstName__c = 'Mike', // "Mike Anderson" vs "Michael Anderson" should be >90% similar
				LastName__c = 'Anderson',
				Email__c = 'michael.andersen@email.net',
				Phone__c = '(555) 555-1234', // Same phone, different format
				SignupDate__c = Date.today().addDays(-12)
			),
			// Score 70: Name variations that should score ≥90%
			new Customer__c(
				FirstName__c = 'Elizabeth',
				LastName__c = 'Williams',
				Email__c = 'liz.williams@domain.com',
				Phone__c = '555-777-8888',
				SignupDate__c = Date.today().addDays(-10)
			),
			new Customer__c(
				FirstName__c = 'Liz', // "Liz Williams" vs "Elizabeth Williams" should be >90%
				LastName__c = 'Williams',
				Email__c = 'elizabeth.w@domain.org',
				Phone__c = '555.777.8888', // Same phone, different format
				SignupDate__c = Date.today().addDays(-8)
			),
			// Score 70: Common nickname variations
			new Customer__c(
				FirstName__c = 'Robert',
				LastName__c = 'Johnson',
				Email__c = 'robert.johnson@test.com',
				Phone__c = '555-333-9999',
				SignupDate__c = Date.today().addDays(-7)
			),
			new Customer__c(
				FirstName__c = 'Bob', // "Bob Johnson" vs "Robert Johnson" should be >90%
				LastName__c = 'Johnson',
				Email__c = 'bob.j@test.net',
				Phone__c = '+1-555-333-9999', // Same phone with country code
				SignupDate__c = Date.today().addDays(-5)
			),
			// Score 70: Slight spelling variations that are still highly similar
			new Customer__c(
				FirstName__c = 'Katherine',
				LastName__c = 'Miller',
				Email__c = 'katherine.miller@example.com',
				Phone__c = '555-444-7777',
				SignupDate__c = Date.today().addDays(-4)
			),
			new Customer__c(
				FirstName__c = 'Catherine', // "Catherine Miller" vs "Katherine Miller" should be >90%
				LastName__c = 'Miller',
				Email__c = 'catherine.m@example.org',
				Phone__c = '5554447777', // Same phone, no formatting
				SignupDate__c = Date.today().addDays(-2)
			),
			// Score 70: Testing normalization - special characters removed
			new Customer__c(
				FirstName__c = 'José',
				LastName__c = 'García-Rodriguez',
				Email__c = 'jose.garcia@test.com',
				Phone__c = '555-666-1111',
				SignupDate__c = Date.today().addDays(-3)
			),
			new Customer__c(
				FirstName__c = 'Jose', // After normalization: "jose garcia rodriguez" vs "jose garcia rodriguez"
				LastName__c = 'Garcia Rodriguez',
				Email__c = 'j.garcia@test.net',
				Phone__c = '555-666-1111',
				SignupDate__c = Date.today().addDays(-1)
			)
		};
	}

	private static List<Customer__c> createPhoneLastNameDuplicates() {
		return new List<Customer__c>{
			// Score 50: Same phone + exact last name match (different first names)
			new Customer__c(
				FirstName__c = 'Robert',
				LastName__c = 'Davis',
				Email__c = 'robert.davis@company.com',
				Phone__c = '555-111-2222',
				SignupDate__c = Date.today().addDays(-7)
			),
			new Customer__c(
				FirstName__c = 'Jennifer', // Different first name, same last name + phone
				LastName__c = 'Davis',
				Email__c = 'jen.davis@different.com',
				Phone__c = '555-111-2222',
				SignupDate__c = Date.today().addDays(-5)
			),
			new Customer__c(
				FirstName__c = 'Michael', // Third person with same last name + phone
				LastName__c = 'Davis',
				Email__c = 'mike.davis@another.com',
				Phone__c = '(555) 111-2222', // Same phone, different format
				SignupDate__c = Date.today().addDays(-4)
			),
			// Score 50: Another family group
			new Customer__c(
				FirstName__c = 'David',
				LastName__c = 'Brown',
				Email__c = 'david.brown@myemail.com',
				Phone__c = '555-333-4444',
				SignupDate__c = Date.today().addDays(-6)
			),
			new Customer__c(
				FirstName__c = 'Linda', // Spouse/family member with same last name + phone
				LastName__c = 'Brown',
				Email__c = 'linda.brown@otheremail.com',
				Phone__c = '555-333-4444',
				SignupDate__c = Date.today().addDays(-3)
			),
			// Score 50: Testing case insensitive last name matching
			new Customer__c(
				FirstName__c = 'James',
				LastName__c = 'WILSON',
				Email__c = 'james.wilson@test.com',
				Phone__c = '555-222-3333',
				SignupDate__c = Date.today().addDays(-8)
			),
			new Customer__c(
				FirstName__c = 'Mary',
				LastName__c = 'wilson', // Same last name, different case
				Email__c = 'mary.wilson@test.net',
				Phone__c = '555-222-3333',
				SignupDate__c = Date.today().addDays(-2)
			),
			// Score 50: Hyphenated last names (normalization test)
			new Customer__c(
				FirstName__c = 'Anna',
				LastName__c = 'Smith-Jones',
				Email__c = 'anna.smith@example.com',
				Phone__c = '555-888-9999',
				SignupDate__c = Date.today().addDays(-9)
			),
			new Customer__c(
				FirstName__c = 'Peter',
				LastName__c = 'Smith Jones', // Same normalized last name
				Email__c = 'peter.jones@example.org',
				Phone__c = '555-888-9999',
				SignupDate__c = Date.today().addDays(-1)
			)
		};
	}

	private static List<Customer__c> createUniqueCustomers() {
		return new List<Customer__c>{
			new Customer__c(
				FirstName__c = 'Emma',
				LastName__c = 'Wilson',
				Email__c = 'emma.wilson@unique.com',
				Phone__c = '555-999-0000',
				SignupDate__c = Date.today().addDays(-2)
			),
			new Customer__c(
				FirstName__c = 'James',
				LastName__c = 'Taylor',
				Email__c = 'james.taylor@solo.com',
				Phone__c = '555-888-7777',
				SignupDate__c = Date.today().addDays(-1)
			),
			new Customer__c(
				FirstName__c = 'Maria',
				LastName__c = 'Garcia',
				Email__c = 'maria.garcia@single.com',
				Phone__c = '555-666-5555',
				SignupDate__c = Date.today()
			)
		};
	}

	private static List<Customer__c> createEdgeCaseCustomers() {
		return new List<Customer__c>{
			// Edge case: Only last name + email (no first name for similarity calc)
			new Customer__c(
				LastName__c = 'NoFirstName',
				Email__c = 'nofirst@test.com',
				Phone__c = '555-000-1111',
				SignupDate__c = Date.today().addDays(-40)
			),
			new Customer__c(
				LastName__c = 'NoFirstName', // Same last name + phone, but no first names to compare
				Email__c = 'another.nofirst@test.com',
				Phone__c = '555-000-1111',
				SignupDate__c = Date.today().addDays(-38)
			),
			// Edge case: Only first name + phone (no last name for exact match)
			new Customer__c(
				FirstName__c = 'NoLast',
				Email__c = 'nolast@test.com',
				Phone__c = '555-000-2222',
				SignupDate__c = Date.today().addDays(-35)
			),
			new Customer__c(
				FirstName__c = 'NoLast', // Same first name + phone, but no last names
				Email__c = 'another.nolast@test.com',
				Phone__c = '555-000-2222',
				SignupDate__c = Date.today().addDays(-33)
			),
			// Edge case: Email only (no phone for phone-based matching)
			new Customer__c(Email__c = 'emailonly@test.com', SignupDate__c = Date.today().addDays(-32)),
			new Customer__c(
				Email__c = 'emailonly@test.com', // Should match on email only
				FirstName__c = 'Added Later',
				LastName__c = 'Added Later',
				SignupDate__c = Date.today().addDays(-30)
			),
			// Edge case: Phone only (no email for email matching)
			new Customer__c(Phone__c = '555-000-3333', SignupDate__c = Date.today().addDays(-28)),
			new Customer__c(
				Phone__c = '555-000-3333', // Same phone but no names to compare
				SignupDate__c = Date.today().addDays(-26)
			),
			// Edge case: International characters and formatting
			new Customer__c(
				FirstName__c = 'José María',
				LastName__c = 'García-Rodríguez',
				Email__c = 'jose.garcia@special.com',
				Phone__c = '+1-555-000-4444',
				SignupDate__c = Date.today().addDays(-22)
			),
			new Customer__c(
				FirstName__c = 'Jose Maria', // Should normalize to same as above
				LastName__c = 'Garcia Rodriguez',
				Email__c = 'j.garcia@special.net',
				Phone__c = '555-000-4444', // Same phone, different format
				SignupDate__c = Date.today().addDays(-20)
			),
			// Edge case: Empty/whitespace names
			new Customer__c(
				FirstName__c = '   ', // Whitespace only
				LastName__c = '', // Empty string
				Email__c = 'whitespace@test.com',
				Phone__c = '555-000-5555',
				SignupDate__c = Date.today().addDays(-18)
			),
			new Customer__c(
				FirstName__c = null, // Null values
				LastName__c = null,
				Email__c = 'nullnames@test.com',
				Phone__c = '555-000-6666',
				SignupDate__c = Date.today().addDays(-16)
			)
		};
	}

	private static List<Customer__c> createNegativeTestCases() {
		return new List<Customer__c>{
			// Should NOT match: Same phone but low name similarity (<90%)
			new Customer__c(
				FirstName__c = 'Alexander',
				LastName__c = 'Thompson',
				Email__c = 'alex.thompson@test.com',
				Phone__c = '555-999-0001',
				SignupDate__c = Date.today().addDays(-50)
			),
			new Customer__c(
				FirstName__c = 'Benjamin', // "Benjamin Wilson" vs "Alexander Thompson" should be <90%
				LastName__c = 'Wilson',
				Email__c = 'ben.wilson@test.com',
				Phone__c = '555-999-0001', // Same phone but names too different
				SignupDate__c = Date.today().addDays(-48)
			),
			// Should NOT match: Same phone but different last names (no exact match)
			new Customer__c(
				FirstName__c = 'Christopher',
				LastName__c = 'Martinez',
				Email__c = 'chris.martinez@test.com',
				Phone__c = '555-999-0002',
				SignupDate__c = Date.today().addDays(-46)
			),
			new Customer__c(
				FirstName__c = 'Christopher', // Same first name, same phone, but different last names
				LastName__c = 'Rodriguez',
				Email__c = 'chris.rodriguez@test.com',
				Phone__c = '555-999-0002',
				SignupDate__c = Date.today().addDays(-44)
			),
			// Should NOT match: Different emails and phones
			new Customer__c(
				FirstName__c = 'Daniel',
				LastName__c = 'Anderson',
				Email__c = 'daniel.anderson@unique1.com',
				Phone__c = '555-999-0003',
				SignupDate__c = Date.today().addDays(-42)
			),
			new Customer__c(
				FirstName__c = 'Daniel',
				LastName__c = 'Anderson', // Same name but different contact info
				Email__c = 'daniel.anderson@unique2.com',
				Phone__c = '555-999-0004', // Different phone
				SignupDate__c = Date.today().addDays(-40)
			),
			// Should NOT match: Similar emails but not exact
			new Customer__c(
				FirstName__c = 'Emily',
				LastName__c = 'Johnson',
				Email__c = 'emily.johnson@domain.com',
				Phone__c = '555-999-0005',
				SignupDate__c = Date.today().addDays(-38)
			),
			new Customer__c(
				FirstName__c = 'Emily',
				LastName__c = 'Johnson',
				Email__c = 'emily.johnson@domain.net', // Similar but not exact email
				Phone__c = '555-999-0006', // Different phone
				SignupDate__c = Date.today().addDays(-36)
			),
			// Should NOT match: Phone similarity but below threshold
			new Customer__c(
				FirstName__c = 'Matthew',
				LastName__c = 'Clark',
				Email__c = 'matthew.clark@test.com',
				Phone__c = '555-999-0007',
				SignupDate__c = Date.today().addDays(-34)
			),
			new Customer__c(
				FirstName__c = 'Mark', // "Mark Taylor" vs "Matthew Clark" should be <90%
				LastName__c = 'Taylor',
				Email__c = 'mark.taylor@test.com',
				Phone__c = '555-999-0007', // Same phone but names not similar enough
				SignupDate__c = Date.today().addDays(-32)
			),
			// Should NOT match: Boundary test - just under 90% similarity
			new Customer__c(
				FirstName__c = 'Jonathan',
				LastName__c = 'Williams',
				Email__c = 'jonathan.williams@test.com',
				Phone__c = '555-999-0008',
				SignupDate__c = Date.today().addDays(-30)
			),
			new Customer__c(
				FirstName__c = 'Jennifer', // "Jennifer White" vs "Jonathan Williams" should be <90%
				LastName__c = 'White',
				Email__c = 'jennifer.white@test.com',
				Phone__c = '555-999-0008',
				SignupDate__c = Date.today().addDays(-28)
			),
			// Should NOT match: No contact info overlap
			new Customer__c(
				FirstName__c = 'Ashley',
				LastName__c = 'Brown',
				Email__c = 'ashley.brown@solo1.com',
				Phone__c = '555-999-0009',
				SignupDate__c = Date.today().addDays(-26)
			),
			new Customer__c(
				FirstName__c = 'Ashley',
				LastName__c = 'Brown', // Identical name but no shared contact info
				Email__c = 'ashley.brown@solo2.com',
				Phone__c = '555-999-0010',
				SignupDate__c = Date.today().addDays(-24)
			)
		};
	}

	/**
	 * Runs the batch duplicate scan job on the test data.
	 *
	 * @return TestDataResult with batch job details
	 */
	@AuraEnabled
	public static TestDataResult runDuplicateScan() {
		TestDataResult result = new TestDataResult();

		try {
			Id batchJobId = Database.executeBatch(new BatchDuplicateScan(), 200);

			result.message = 'Duplicate scan batch job started successfully. Job ID: ' + batchJobId;
		} catch (Exception e) {
			result.success = false;
			result.message = 'Failed to start duplicate scan batch job';
			result.errors.add('Error: ' + e.getMessage());
		}

		return result;
	}

	/**
	 * Gets summary statistics of current test data.
	 *
	 * @return Map containing data statistics
	 */
	@AuraEnabled
	public static Map<String, Integer> getDataStatistics() {
		Map<String, Integer> stats = new Map<String, Integer>();

		try {
			stats.put('totalCustomers', [SELECT COUNT() FROM Customer__c]);
			stats.put('pendingMatches', [SELECT COUNT() FROM Duplicate_Match__c WHERE Status__c = 'Pending Review']);
			stats.put('mergedMatches', [SELECT COUNT() FROM Duplicate_Match__c WHERE Status__c = 'Merged']);
			stats.put('ignoredMatches', [SELECT COUNT() FROM Duplicate_Match__c WHERE Status__c = 'Ignored']);
			stats.put('mergedCustomers', [SELECT COUNT() FROM Customer__c WHERE Is_Merged__c = TRUE]);
		} catch (Exception e) {
			System.debug('Error getting statistics: ' + e.getMessage());
		}

		return stats;
	}
}
