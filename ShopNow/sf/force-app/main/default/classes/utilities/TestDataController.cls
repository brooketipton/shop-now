/**
 * Controller class for generating test customer data for duplicate detection testing.
 *
 * This class creates various customer scenarios including:
 * - Exact duplicates (same email)
 * - Near duplicates (similar names, same phone)
 * - Clean unique customers
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
				Email__c = 'john.smith@example.com',
				Phone__c = '5551234567',
				SignupDate__c = Date.today().addDays(-25)
			),
			new Customer__c(
				FirstName__c = 'Sarah',
				LastName__c = 'Johnson',
				Email__c = 'sarah.johnson@test.com',
				Phone__c = '555-987-6543',
				SignupDate__c = Date.today().addDays(-20)
			),
			new Customer__c(
				FirstName__c = 'Sara',
				LastName__c = 'Johnson',
				Email__c = 'sarah.johnson@test.com',
				Phone__c = '555-987-6543',
				SignupDate__c = Date.today().addDays(-18)
			)
		};
	}

	private static List<Customer__c> createPhoneNameSimilarDuplicates() {
		return new List<Customer__c>{
			new Customer__c(
				FirstName__c = 'Michael',
				LastName__c = 'Anderson',
				Email__c = 'mike.anderson@email.com',
				Phone__c = '555-555-1234',
				SignupDate__c = Date.today().addDays(-15)
			),
			new Customer__c(
				FirstName__c = 'Mike',
				LastName__c = 'Andersen',
				Email__c = 'michael.andersen@email.net',
				Phone__c = '5555551234',
				SignupDate__c = Date.today().addDays(-12)
			),
			new Customer__c(
				FirstName__c = 'Elizabeth',
				LastName__c = 'Williams',
				Email__c = 'liz.williams@domain.com',
				Phone__c = '555-777-8888',
				SignupDate__c = Date.today().addDays(-10)
			),
			new Customer__c(
				FirstName__c = 'Liz',
				LastName__c = 'Williamson',
				Email__c = 'elizabeth.williamson@domain.org',
				Phone__c = '555-777-8888',
				SignupDate__c = Date.today().addDays(-8)
			)
		};
	}

	private static List<Customer__c> createPhoneLastNameDuplicates() {
		return new List<Customer__c>{
			new Customer__c(
				FirstName__c = 'Robert',
				LastName__c = 'Davis',
				Email__c = 'robert.davis@company.com',
				Phone__c = '555-111-2222',
				SignupDate__c = Date.today().addDays(-7)
			),
			new Customer__c(
				FirstName__c = 'Jennifer',
				LastName__c = 'Davis',
				Email__c = 'jen.davis@different.com',
				Phone__c = '555-111-2222',
				SignupDate__c = Date.today().addDays(-5)
			),
			new Customer__c(
				FirstName__c = 'David',
				LastName__c = 'Brown',
				Email__c = 'david.brown@myemail.com',
				Phone__c = '555-333-4444',
				SignupDate__c = Date.today().addDays(-4)
			),
			new Customer__c(
				FirstName__c = 'Linda',
				LastName__c = 'Brown',
				Email__c = 'linda.brown@otheremail.com',
				Phone__c = '555-333-4444',
				SignupDate__c = Date.today().addDays(-3)
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
			new Customer__c(
				LastName__c = 'NoFirstName',
				Email__c = 'nofirst@test.com',
				Phone__c = '555-000-1111',
				SignupDate__c = Date.today().addDays(-40)
			),
			new Customer__c(
				FirstName__c = 'NoLast',
				Email__c = 'nolast@test.com',
				Phone__c = '555-000-2222',
				SignupDate__c = Date.today().addDays(-35)
			),
			new Customer__c(Email__c = 'emailonly@test.com', SignupDate__c = Date.today().addDays(-32)),
			new Customer__c(Phone__c = '555-000-3333', SignupDate__c = Date.today().addDays(-28)),
			new Customer__c(
				FirstName__c = 'José',
				LastName__c = 'García-Rodriguez',
				Email__c = 'jose.garcia@special.com',
				Phone__c = '+1-555-000-4444',
				SignupDate__c = Date.today().addDays(-22)
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
