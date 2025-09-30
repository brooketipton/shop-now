@IsTest
public class CustomerMergerTest {
	@IsTest
	static void testSuccessfulMergeWithCompleteData() {
		List<Customer__c> testCustomers = createTestCustomers();
		Customer__c winner = testCustomers[0];
		Customer__c loser = testCustomers[1];

		Test.startTest();

		CustomerMerger.MergeResult result = CustomerMerger.mergeCustomers(winner.Id, loser.Id);

		Test.stopTest();

		System.assert(result.success, 'Merge should be successful');
		System.assertEquals(winner.Id, result.winnerId, 'Winner ID should match');
		System.assertEquals(loser.Id, result.loserId, 'Loser ID should match');
		System.assertNotEquals(null, result.mergedOn, 'Merge timestamp should be set');

		Customer__c updatedWinner = [
			SELECT Id, FirstName__c, LastName__c, Email__c, Phone__c, SignupDate__c, Is_Merged__c
			FROM Customer__c
			WHERE Id = :winner.Id
		];

		System.assertEquals('John', updatedWinner.FirstName__c, 'Winner should keep longer first name');
		System.assertEquals('Smith', updatedWinner.LastName__c, 'Winner should keep last name');
		System.assertEquals('john.smith@test.com', updatedWinner.Email__c, 'Winner should keep email');
		System.assertEquals(false, updatedWinner.Is_Merged__c, 'Winner should not be marked as merged');

		Customer__c updatedLoser = [
			SELECT Id, Is_Merged__c, Merged_Into__c, Merged_On__c
			FROM Customer__c
			WHERE Id = :loser.Id
		];

		System.assertEquals(true, updatedLoser.Is_Merged__c, 'Loser should be marked as merged');
		System.assertEquals(winner.Id, updatedLoser.Merged_Into__c, 'Loser should reference winner');
		System.assertNotEquals(null, updatedLoser.Merged_On__c, 'Merge timestamp should be set on loser');
	}

	@IsTest
	static void testMergeWithPartialData() {
		Customer__c winner = new Customer__c(
			FirstName__c = 'John',
			LastName__c = '',
			Email__c = 'john@test.com',
			Phone__c = null,
			SignupDate__c = Date.today().addDays(-30),
			Is_Merged__c = false
		);

		Customer__c loser = new Customer__c(
			FirstName__c = '',
			LastName__c = 'Smith',
			Email__c = null,
			Phone__c = '+1-555-0123',
			SignupDate__c = Date.today().addDays(-20),
			Is_Merged__c = false
		);

		insert new List<Customer__c>{ winner, loser };

		Test.startTest();

		CustomerMerger.MergeResult result = CustomerMerger.mergeCustomers(winner.Id, loser.Id);

		Test.stopTest();

		System.assert(result.success, 'Merge should be successful with partial data');

		Customer__c merged = [
			SELECT FirstName__c, LastName__c, Email__c, Phone__c
			FROM Customer__c
			WHERE Id = :winner.Id
		];

		System.assertEquals('John', merged.FirstName__c, 'Should use winner\'s first name');
		System.assertEquals('Smith', merged.LastName__c, 'Should use loser\'s last name');
		System.assertEquals('john@test.com', merged.Email__c, 'Should use winner\'s email');
		System.assertEquals('+1-555-0123', merged.Phone__c, 'Should use loser\'s phone');
	}

	@IsTest
	static void testMergeSignupDateLogic() {
		Date earlierDate = Date.today().addDays(-50);
		Date laterDate = Date.today().addDays(-20);

		Customer__c winner = new Customer__c(
			FirstName__c = 'John',
			LastName__c = 'Smith',
			Email__c = 'john@test.com',
			SignupDate__c = laterDate,
			Is_Merged__c = false
		);

		Customer__c loser = new Customer__c(
			FirstName__c = 'J',
			LastName__c = 'Smith',
			Email__c = 'j.smith@test.com',
			SignupDate__c = earlierDate,
			Is_Merged__c = false
		);

		insert new List<Customer__c>{ winner, loser };

		Test.startTest();

		CustomerMerger.MergeResult result = CustomerMerger.mergeCustomers(winner.Id, loser.Id);

		Test.stopTest();

		System.assert(result.success, 'Merge should be successful');

		Customer__c merged = [SELECT SignupDate__c FROM Customer__c WHERE Id = :winner.Id];
		System.assertEquals(earlierDate, merged.SignupDate__c, 'Should use earlier signup date');
	}

	@IsTest
	static void testValidationErrorNullWinner() {
		List<Customer__c> testCustomers = createTestCustomers();

		Test.startTest();

		CustomerMerger.MergeResult result = CustomerMerger.mergeCustomers(null, testCustomers[1].Id);

		Test.stopTest();

		System.assertEquals(false, result.success, 'Merge should fail with null winner');
		System.assert(result.errorMessage.contains('must be provided'), 'Error message should mention required IDs');
	}

	@IsTest
	static void testValidationErrorSameCustomer() {
		List<Customer__c> testCustomers = createTestCustomers();
		Id customerId = testCustomers[0].Id;

		Test.startTest();

		CustomerMerger.MergeResult result = CustomerMerger.mergeCustomers(customerId, customerId);

		Test.stopTest();

		System.assertEquals(false, result.success, 'Merge should fail with same customer');
		System.assert(result.errorMessage.contains('itself'), 'Error message should mention self-merge');
	}

	@IsTest
	static void testValidationErrorAlreadyMerged() {
		List<Customer__c> testCustomers = createTestCustomers();

		testCustomers[1].Is_Merged__c = true;
		testCustomers[1].Merged_Into__c = testCustomers[0].Id;
		update testCustomers[1];

		Test.startTest();

		CustomerMerger.MergeResult result = CustomerMerger.mergeCustomers(testCustomers[0].Id, testCustomers[1].Id);

		Test.stopTest();

		System.assertEquals(false, result.success, 'Merge should fail with already merged customer');
		System.assert(result.errorMessage.contains('already merged'), 'Error message should mention already merged');
	}

	@IsTest
	static void testNameConsolidationLogic() {
		Customer__c winner = new Customer__c(
			FirstName__c = 'J',
			LastName__c = 'Smith-Johnson',
			Email__c = 'john@test.com',
			Is_Merged__c = false
		);

		Customer__c loser = new Customer__c(
			FirstName__c = 'Jonathan',
			LastName__c = 'Smith',
			Email__c = 'jonathan@test.com',
			Is_Merged__c = false
		);

		insert new List<Customer__c>{ winner, loser };

		Test.startTest();

		CustomerMerger.MergeResult result = CustomerMerger.mergeCustomers(winner.Id, loser.Id);

		Test.stopTest();

		System.assert(result.success, 'Merge should be successful');

		Customer__c merged = [
			SELECT FirstName__c, LastName__c
			FROM Customer__c
			WHERE Id = :winner.Id
		];

		System.assertEquals('Jonathan', merged.FirstName__c, 'Should prefer longer first name');
		System.assertEquals('Smith-Johnson', merged.LastName__c, 'Should prefer longer last name');
	}

	@IsTest
	static void testIdenticalCustomerData() {
		Customer__c winner = new Customer__c(
			FirstName__c = 'John',
			LastName__c = 'Smith',
			Email__c = 'john.smith@test.com',
			Phone__c = '+1-555-0123',
			SignupDate__c = Date.today().addDays(-30),
			Is_Merged__c = false
		);

		Customer__c loser = new Customer__c(
			FirstName__c = 'John',
			LastName__c = 'Smith',
			Email__c = 'john.smith@test.com',
			Phone__c = '+1-555-0123',
			SignupDate__c = Date.today().addDays(-30),
			Is_Merged__c = false
		);

		insert new List<Customer__c>{ winner, loser };

		Test.startTest();

		CustomerMerger.MergeResult result = CustomerMerger.mergeCustomers(winner.Id, loser.Id);

		Test.stopTest();

		System.assert(result.success, 'Merge should be successful even with identical data');

		Customer__c mergedLoser = [
			SELECT Is_Merged__c, Merged_Into__c
			FROM Customer__c
			WHERE Id = :loser.Id
		];

		System.assertEquals(true, mergedLoser.Is_Merged__c, 'Loser should be marked as merged');
		System.assertEquals(winner.Id, mergedLoser.Merged_Into__c, 'Loser should reference winner');
	}

	private static List<Customer__c> createTestCustomers() {
		List<Customer__c> customers = new List<Customer__c>{
			new Customer__c(
				FirstName__c = 'John',
				LastName__c = 'Smith',
				Email__c = 'john.smith@test.com',
				Phone__c = '+1-555-0123',
				SignupDate__c = Date.today().addDays(-30),
				Is_Merged__c = false
			),
			new Customer__c(
				FirstName__c = 'J',
				LastName__c = 'Smith',
				Email__c = 'j.smith@test.com',
				Phone__c = '+1-555-0123',
				SignupDate__c = Date.today().addDays(-20),
				Is_Merged__c = false
			)
		};

		insert customers;
		return customers;
	}
}
