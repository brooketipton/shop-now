/**
 * Service class for merging duplicate customer records.
 *
 * This service handles the merging two Customer__c records,
 * including data consolidation and related record updates
 */
public with sharing class CustomerMerger {
	private static final String MERGE_STRATEGY_PREFER_WINNER = 'PREFER_WINNER';
	private static final String MERGE_STRATEGY_PREFER_NEWER = 'PREFER_NEWER';
	private static final String MERGE_STRATEGY_PREFER_LONGER = 'PREFER_LONGER';
	private static final String MERGE_STRATEGY_CONCATENATE = 'CONCATENATE';

	/**
	 * Merges two customer records, consolidating data from loser into winner
	 *
	 * @param winnerId ID of the customer record to keep
	 * @param loserId ID of the customer record to merge and deactivate
	 * @return MergeResult containing success status and details
	 */
	public static MergeResult mergeCustomers(Id winnerId, Id loserId) {
		MergeResult result = new MergeResult();
		result.winnerId = winnerId;
		result.loserId = loserId;
		result.mergedOn = System.now();

		try {
			ValidationResult validation = validateMergeRequest(winnerId, loserId);
			if (!validation.isValid) {
				result.success = false;
				result.errorMessage = validation.errorMessage;
				return result;
			}

			List<Customer__c> customers = fetchCustomersForMerge(winnerId, loserId);
			Customer__c winner = findCustomerById(customers, winnerId);
			Customer__c loser = findCustomerById(customers, loserId);

			Customer__c mergedWinner = consolidateCustomerData(winner, loser);
			Customer__c mergedLoser = markCustomerAsMerged(loser, winnerId);

			// update records with rollback support
			Savepoint sp = Database.setSavepoint();
			try {
				update mergedWinner;
				update mergedLoser;

				result.success = true;

				System.debug('CustomerMerger: Successfully merged customer ' + loserId + ' into ' + winnerId);
			} catch (DmlException e) {
				Database.rollback(sp);
				result.success = false;
				result.errorMessage = 'DML Error during merge: ' + e.getMessage();
				System.debug(LoggingLevel.ERROR, 'CustomerMerger DML Error: ' + e.getMessage());
			}
		} catch (Exception e) {
			result.success = false;
			result.errorMessage = 'Unexpected error during merge: ' + e.getMessage();
			System.debug(LoggingLevel.ERROR, 'CustomerMerger Exception: ' + e.getMessage());
		}

		return result;
	}

	private static ValidationResult validateMergeRequest(Id winnerId, Id loserId) {
		ValidationResult result = new ValidationResult();

		if (winnerId == null || loserId == null) {
			result.isValid = false;
			result.errorMessage = 'Both winner and loser customer IDs must be provided';
			return result;
		}

		if (winnerId == loserId) {
			result.isValid = false;
			result.errorMessage = 'Cannot merge a customer record with itself';
			return result;
		}

		// check if records exist and are not already merged
		List<Customer__c> customers = [
			SELECT Id, Is_Merged__c, Merged_Into__c
			FROM Customer__c
			WHERE Id IN (:winnerId, :loserId)
		];

		if (customers.size() != 2) {
			result.isValid = false;
			result.errorMessage = 'One or both customer records not found';
			return result;
		}

		for (Customer__c customer : customers) {
			if (customer.Is_Merged__c == true) {
				result.isValid = false;
				result.errorMessage = 'Customer ' + customer.Id + ' is already merged into another record';
				return result;
			}
		}

		result.isValid = true;
		return result;
	}

	private static List<Customer__c> fetchCustomersForMerge(Id winnerId, Id loserId) {
		return [
			SELECT
				Id,
				FirstName__c,
				LastName__c,
				Email__c,
				Phone__c,
				SignupDate__c,
				Is_Merged__c,
				Merged_Into__c,
				Merged_On__c,
				CreatedDate,
				LastModifiedDate
			FROM Customer__c
			WHERE Id IN (:winnerId, :loserId)
		];
	}

	private static Customer__c findCustomerById(List<Customer__c> customers, Id customerId) {
		for (Customer__c customer : customers) {
			if (customer.Id == customerId) {
				return customer;
			}
		}
		return null;
	}

	private static Customer__c consolidateCustomerData(Customer__c winner, Customer__c loser) {
		Customer__c consolidated = winner.clone(true, true, true, true);

		consolidated.FirstName__c = selectBestStringValue(
			winner.FirstName__c,
			loser.FirstName__c,
			MERGE_STRATEGY_PREFER_LONGER
		);
		consolidated.LastName__c = selectBestStringValue(
			winner.LastName__c,
			loser.LastName__c,
			MERGE_STRATEGY_PREFER_LONGER
		);

		consolidated.Email__c = selectBestStringValue(winner.Email__c, loser.Email__c, MERGE_STRATEGY_PREFER_WINNER);
		consolidated.Phone__c = selectBestStringValue(winner.Phone__c, loser.Phone__c, MERGE_STRATEGY_PREFER_WINNER);
		consolidated.SignupDate__c = selectEarlierDate(winner.SignupDate__c, loser.SignupDate__c);

		return consolidated;
	}

	private static Customer__c markCustomerAsMerged(Customer__c loser, Id winnerId) {
		Customer__c mergedLoser = loser.clone(true, true, true, true);
		mergedLoser.Is_Merged__c = true;
		mergedLoser.Merged_Into__c = winnerId;
		mergedLoser.Merged_On__c = System.now();
		return mergedLoser;
	}

	private static String selectBestStringValue(String winnerValue, String loserValue, String strategy) {
		if (String.isBlank(winnerValue) && String.isNotBlank(loserValue)) {
			return loserValue.trim();
		}
		if (String.isNotBlank(winnerValue) && String.isBlank(loserValue)) {
			return winnerValue.trim();
		}
		if (String.isBlank(winnerValue) && String.isBlank(loserValue)) {
			return null;
		}

		switch on strategy {
			when 'PREFER_WINNER' {
				return winnerValue.trim();
			}
			when 'PREFER_LONGER' {
				return winnerValue.trim().length() >= loserValue.trim().length()
					? winnerValue.trim()
					: loserValue.trim();
			}
			when 'CONCATENATE' {
				if (winnerValue.trim().equals(loserValue.trim())) {
					return winnerValue.trim();
				}
				return winnerValue.trim() + ' / ' + loserValue.trim();
			}
			when else {
				return winnerValue.trim();
			}
		}
	}

	private static Date selectEarlierDate(Date date1, Date date2) {
		if (date1 == null && date2 != null) {
			return date2;
		}
		if (date1 != null && date2 == null) {
			return date1;
		}
		if (date1 == null && date2 == null) {
			return null;
		}
		return date1 <= date2 ? date1 : date2;
	}

	public class MergeResult {
		public Boolean success { get; set; }
		public String errorMessage { get; set; }
		public Id winnerId { get; set; }
		public Id loserId { get; set; }
		public DateTime mergedOn { get; set; }

		public MergeResult() {
			this.success = false;
		}
	}

	private class ValidationResult {
		public Boolean isValid { get; set; }
		public String errorMessage { get; set; }

		public ValidationResult() {
			this.isValid = false;
		}
	}
}
