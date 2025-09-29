/**
 * Service class for managing duplicate record detection and matching.
 *
 * This service handles the creation and management of Duplicate_Match__c records
 * that track potential duplicate customers and their similarity scores.
 */
public with sharing class DedupeService {
	// Constants for match statuses
	private static final String STATUS_PENDING = 'Pending Review';
	private static final String STATUS_MERGED = 'Merged';
	private static final String STATUS_IGNORED = 'Ignored';

	/**
	 * Input wrapper class for match data.
	 * Contains the two record IDs being compared and their similarity score.
	 */
	public class MatchInput {
		@AuraEnabled
		public Id recordAId;
		@AuraEnabled
		public Id recordBId;
		@AuraEnabled
		public Decimal matchScore;

		public MatchInput() {
		}

		public MatchInput(Id recordA, Id recordB, Decimal score) {
			this.recordAId = recordA;
			this.recordBId = recordB;
			this.matchScore = score;
		}
	}

	/**
	 * Result wrapper class for match operations.
	 * Provides feedback on the operation outcome.
	 */
	public class DedupeResult {
		@AuraEnabled
		public Boolean success;
		@AuraEnabled
		public String message;
		@AuraEnabled
		public Integer recordsProcessed;
		@AuraEnabled
		public Integer recordsUpserted;
		@AuraEnabled
		public List<String> errors;

		public DedupeResult() {
			this.success = true;
			this.recordsProcessed = 0;
			this.recordsUpserted = 0;
			this.errors = new List<String>();
		}
	}

	/**
	 * Creates a consistent pair key for two record IDs.
	 * Orders the IDs alphabetically to ensure the same pair always generates the same key.
	 *
	 * @param recordAId First record ID
	 * @param recordBId Second record ID
	 * @return String key in format "smallerId:largerId"
	 */
	public static String generatePairKey(Id recordAId, Id recordBId) {
		if (recordAId == null || recordBId == null) {
			throw new IllegalArgumentException('Both record IDs must be provided');
		}

		if (recordAId == recordBId) {
			throw new IllegalArgumentException('Cannot create pair key for identical records');
		}

		String firstId = String.valueOf(recordAId);
		String secondId = String.valueOf(recordBId);

		// Always put smaller ID first for consistent ordering
		return (firstId < secondId) ? firstId + ':' + secondId : secondId + ':' + firstId;
	}

	/**
	 * Creates or updates Duplicate_Match__c records for potential duplicate pairs.
	 * Respects existing matches that have been manually resolved (Merged/Ignored).
	 *
	 * @param matchInputs List of potential matches to process
	 * @return DedupeResult with operation details
	 */
	public static DedupeResult processMatches(List<MatchInput> matchInputs) {
		DedupeResult result = new DedupeResult();

		if (matchInputs == null || matchInputs.isEmpty()) {
			result.message = 'No match inputs provided';
			return result;
		}

		try {
			// Validate inputs and collect pair keys
			Set<String> pairKeys = validateAndCollectPairKeys(matchInputs, result);
			if (!result.success) {
				return result;
			}

			result.recordsProcessed = matchInputs.size();

			// Fetch existing matches to avoid overriding resolved duplicates
			Map<String, Duplicate_Match__c> existingMatches = getExistingMatches(pairKeys);

			// Prepare records for upsert
			List<Duplicate_Match__c> matchesToUpsert = prepareMatchRecords(matchInputs, existingMatches, result);

			// Perform upsert operation
			if (!matchesToUpsert.isEmpty()) {
				upsert matchesToUpsert Pair_Key__c;
				result.recordsUpserted = matchesToUpsert.size();
				result.message = String.format(
					'Successfully processed {0} matches, upserted {1} records',
					new List<Object>{ result.recordsProcessed, result.recordsUpserted }
				);
			} else {
				result.message = 'No new matches to process - all pairs already resolved or invalid';
			}
		} catch (DmlException e) {
			result.success = false;
			result.message = 'Database error occurred while processing matches';
			result.errors.add('DML Error: ' + e.getMessage());
		} catch (Exception e) {
			result.success = false;
			result.message = 'Unexpected error occurred while processing matches';
			result.errors.add('Error: ' + e.getMessage());
		}

		return result;
	}

	/**
	 * Validates match inputs and collects unique pair keys.
	 *
	 * @param matchInputs List of inputs to validate
	 * @param result Result object to populate with any errors
	 * @return Set of valid pair keys
	 */
	private static Set<String> validateAndCollectPairKeys(List<MatchInput> matchInputs, DedupeResult result) {
		Set<String> pairKeys = new Set<String>();

		for (Integer i = 0; i < matchInputs.size(); i++) {
			MatchInput input = matchInputs[i];

			// Validate required fields
			if (input.recordAId == null || input.recordBId == null) {
				result.success = false;
				result.errors.add(String.format('Match input at index {0} has null record IDs', new List<Object>{ i }));
				continue;
			}

			if (input.recordAId == input.recordBId) {
				result.success = false;
				result.errors.add(
					String.format('Match input at index {0} has identical record IDs', new List<Object>{ i })
				);
				continue;
			}

			if (input.matchScore == null || input.matchScore < 0 || input.matchScore > 100) {
				result.success = false;
				result.errors.add(
					String.format(
						'Match input at index {0} has invalid match score: {1}',
						new List<Object>{ i, input.matchScore }
					)
				);
				continue;
			}

			try {
				String pairKey = generatePairKey(input.recordAId, input.recordBId);
				pairKeys.add(pairKey);
			} catch (IllegalArgumentException e) {
				result.success = false;
				result.errors.add(
					String.format('Match input at index {0}: {1}', new List<Object>{ i, e.getMessage() })
				);
			}
		}

		return pairKeys;
	}

	/**
	 * Retrieves existing Duplicate_Match__c records for the given pair keys.
	 *
	 * @param pairKeys Set of pair keys to query
	 * @return Map of pair key to existing Duplicate_Match__c record
	 */
	private static Map<String, Duplicate_Match__c> getExistingMatches(Set<String> pairKeys) {
		Map<String, Duplicate_Match__c> existingMatches = new Map<String, Duplicate_Match__c>();

		if (pairKeys.isEmpty()) {
			return existingMatches;
		}

		for (Duplicate_Match__c existingMatch : [
			SELECT Id, Customer_A__c, Customer_B__c, Pair_Key__c, Status__c, Match_Score__c
			FROM Duplicate_Match__c
			WHERE Pair_Key__c IN :pairKeys
		]) {
			existingMatches.put(existingMatch.Pair_Key__c, existingMatch);
		}

		return existingMatches;
	}

	/**
	 * Prepares Duplicate_Match__c records for upsert operation.
	 * Skips records that have been manually resolved (Merged/Ignored status).
	 *
	 * @param matchInputs Original match inputs
	 * @param existingMatches Map of existing match records
	 * @param result Result object to track skipped records
	 * @return List of records ready for upsert
	 */
	private static List<Duplicate_Match__c> prepareMatchRecords(
		List<MatchInput> matchInputs,
		Map<String, Duplicate_Match__c> existingMatches,
		DedupeResult result
	) {
		List<Duplicate_Match__c> recordsToUpsert = new List<Duplicate_Match__c>();

		for (MatchInput input : matchInputs) {
			// Skip invalid inputs (already logged in validation)
			if (input.recordAId == null || input.recordBId == null || input.matchScore == null) {
				continue;
			}

			String pairKey = generatePairKey(input.recordAId, input.recordBId);
			Duplicate_Match__c matchRecord;

			// Check if record already exists
			if (existingMatches.containsKey(pairKey)) {
				matchRecord = existingMatches.get(pairKey);

				// Skip if manually resolved - don't resurrect resolved duplicates
				if (isManuallyResolved(matchRecord.Status__c)) {
					continue;
				}
			} else {
				// Create new record
				matchRecord = new Duplicate_Match__c();
				matchRecord.Pair_Key__c = pairKey;
			}

			// Populate/update record fields
			populateMatchRecord(matchRecord, input);
			recordsToUpsert.add(matchRecord);
		}

		return recordsToUpsert;
	}

	/**
	 * Checks if a match has been manually resolved and should not be updated.
	 *
	 * @param status Current status of the match record
	 * @return True if the record has been manually resolved
	 */
	private static Boolean isManuallyResolved(String status) {
		return status == STATUS_MERGED || status == STATUS_IGNORED;
	}

	/**
	 * Populates a Duplicate_Match__c record with data from MatchInput.
	 *
	 * @param matchRecord Record to populate
	 * @param input Input data
	 */
	private static void populateMatchRecord(Duplicate_Match__c matchRecord, MatchInput input) {
		matchRecord.Customer_A__c = input.recordAId;
		matchRecord.Customer_B__c = input.recordBId;
		matchRecord.Match_Score__c = input.matchScore;
		matchRecord.Status__c = STATUS_PENDING;
	}

	/**
	 * Batch processes matches for large datasets.
	 * Useful when processing thousands of potential matches.
	 *
	 * @param matchInputs List of matches to process
	 * @param batchSize Number of records to process per batch
	 * @return Consolidated DedupeResult from all batches
	 */
	public static DedupeResult processBatchMatches(List<MatchInput> matchInputs, Integer batchSize) {
		DedupeResult consolidatedResult = new DedupeResult();

		if (batchSize == null || batchSize <= 0) {
			batchSize = 200; // Default batch size
		}

		List<List<MatchInput>> batches = createBatches(matchInputs, batchSize);

		for (Integer i = 0; i < batches.size(); i++) {
			List<MatchInput> batch = batches[i];
			DedupeResult batchResult = processMatches(batch);

			// Consolidate results
			consolidatedResult.recordsProcessed += batchResult.recordsProcessed;
			consolidatedResult.recordsUpserted += batchResult.recordsUpserted;
			consolidatedResult.errors.addAll(batchResult.errors);

			if (!batchResult.success) {
				consolidatedResult.success = false;
			}
		}

		consolidatedResult.message = String.format(
			'Batch processing completed. Processed {0} matches across {1} batches, upserted {2} records',
			new List<Object>{ consolidatedResult.recordsProcessed, batches.size(), consolidatedResult.recordsUpserted }
		);

		return consolidatedResult;
	}

	/**
	 * Helper method to split a list into batches.
	 *
	 * @param items List to split
	 * @param batchSize Size of each batch
	 * @return List of batched lists
	 */
	private static List<List<MatchInput>> createBatches(List<MatchInput> items, Integer batchSize) {
		List<List<MatchInput>> batches = new List<List<MatchInput>>();

		for (Integer i = 0; i < items.size(); i += batchSize) {
			Integer endIndex = Math.min(i + batchSize, items.size());
			List<MatchInput> batch = new List<MatchInput>();

			for (Integer j = i; j < endIndex; j++) {
				batch.add(items[j]);
			}

			batches.add(batch);
		}

		return batches;
	}
}
