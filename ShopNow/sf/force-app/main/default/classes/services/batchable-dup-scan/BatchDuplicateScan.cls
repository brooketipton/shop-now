/**
 * Batch job for scanning Customer__c records to identify potential duplicates.
 *
 * This batch processes customers in chunks and applies multiple matching rules:
 * 1. Exact email match (score: 100)
 * 2. Same phone + high name similarity (score: 70)
 * 3. Same phone + exact last name match (score: 50)
 */
public with sharing class BatchDuplicateScan implements Database.Batchable<SObject>, Database.Stateful {
	private static final Integer EXACT_EMAIL_SCORE = 100;
	private static final Integer PHONE_NAME_FUZZY_SCORE = 70;
	private static final Integer PHONE_LASTNAME_SCORE = 50;
	private static final Decimal NAME_SIMILARITY_THRESHOLD = 0.90;

	private Integer totalRecordsProcessed = 0;
	private Integer totalMatchesFound = 0;
	private Integer batchesProcessed = 0;
	private List<String> processingErrors = new List<String>();

	/**
	 * Query locator to fetch unmerged customers for duplicate scanning.
	 *
	 * @param ctx Batchable context
	 * @return QueryLocator for Customer__c records
	 */
	public Database.QueryLocator start(Database.BatchableContext ctx) {
		System.debug('BatchDuplicateScan: Starting batch job');

		return Database.getQueryLocator(
			[
				SELECT Id, FirstName__c, LastName__c, Email__c, Phone__c
				FROM Customer__c
				WHERE (Is_Merged__c = FALSE OR Is_Merged__c = NULL) AND (Email__c != NULL OR Phone__c != NULL)
				ORDER BY LastModifiedDate DESC
			]
		);
	}

	/**
	 * Main execution method that processes a batch of customers for duplicates and marks them as pending
	 *
	 * @param ctx Batchable context
	 * @param scope List of Customer__c records to process
	 */
	public void execute(Database.BatchableContext ctx, List<Customer__c> scope) {
		System.debug('BatchDuplicateScan: Processing batch of ' + scope.size() + ' records');

		try {
			totalRecordsProcessed += scope.size();
			batchesProcessed++;

			CustomerBuckets buckets = groupCustomersByMatchingCriteria(scope);
			List<Duplicate_Match__c> potentialMatches = new List<Duplicate_Match__c>();

			applyExactEmailMatchingRule(buckets.emailGroups, potentialMatches);
			applyPhoneBasedMatchingRules(buckets.phoneGroups, potentialMatches);

			if (!potentialMatches.isEmpty()) {
				try {
					Map<String, Duplicate_Match__c> uniqueMatches = new Map<String, Duplicate_Match__c>();
					for (Duplicate_Match__c match : potentialMatches) {
						String pairKey = generatePairKey(match.Customer_A__c, match.Customer_B__c);
						match.Pair_Key__c = pairKey;
						uniqueMatches.put(pairKey, match);
					}

					insert uniqueMatches.values();
					totalMatchesFound += uniqueMatches.size();

					System.debug(
						'BatchDuplicateScan: Created ' + uniqueMatches.size() + ' duplicate match records in this batch'
					);
				} catch (DmlException e) {
					String errorMessage = 'Batch ' + batchesProcessed + ' DML Error: ' + e.getMessage();
					processingErrors.add(errorMessage);
					System.debug(LoggingLevel.ERROR, 'BatchDuplicateScan Error: ' + errorMessage);
				}
			}
		} catch (Exception e) {
			String errorMessage = 'Batch ' + batchesProcessed + ' failed: ' + e.getMessage();
			processingErrors.add(errorMessage);
			System.debug(LoggingLevel.ERROR, 'BatchDuplicateScan Exception: ' + errorMessage);
			System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
		}
	}

	/**
	 * Completion method that logs summary statistics.
	 *
	 * @param ctx Batchable context
	 */
	public void finish(Database.BatchableContext ctx) {
		System.debug('BatchDuplicateScan: Batch job completed');
		System.debug('- Total records processed: ' + totalRecordsProcessed);
		System.debug('- Total batches processed: ' + batchesProcessed);
		System.debug('- Total potential matches found: ' + totalMatchesFound);
		System.debug('- Processing errors: ' + processingErrors.size());

		if (!processingErrors.isEmpty()) {
			System.debug(LoggingLevel.WARN, 'BatchDuplicateScan Errors: ' + processingErrors);
		}
	}

	private CustomerBuckets groupCustomersByMatchingCriteria(List<Customer__c> customers) {
		Map<String, List<Customer__c>> emailGroups = new Map<String, List<Customer__c>>();
		Map<String, List<Customer__c>> phoneGroups = new Map<String, List<Customer__c>>();

		for (Customer__c customer : customers) {
			if (String.isNotBlank(customer.Email__c)) {
				String normalizedEmail = customer.Email__c.toLowerCase().trim();
				if (!emailGroups.containsKey(normalizedEmail)) {
					emailGroups.put(normalizedEmail, new List<Customer__c>());
				}
				emailGroups.get(normalizedEmail).add(customer);
			}

			if (String.isNotBlank(customer.Phone__c)) {
				String normalizedPhone = StringUtil.normalizePhone(customer.Phone__c);
				if (String.isNotBlank(normalizedPhone)) {
					if (!phoneGroups.containsKey(normalizedPhone)) {
						phoneGroups.put(normalizedPhone, new List<Customer__c>());
					}
					phoneGroups.get(normalizedPhone).add(customer);
				}
			}
		}

		return new CustomerBuckets(emailGroups, phoneGroups);
	}

	private void applyExactEmailMatchingRule(
		Map<String, List<Customer__c>> emailGroups,
		List<Duplicate_Match__c> matches
	) {
		for (String email : emailGroups.keySet()) {
			List<Customer__c> customersWithEmail = emailGroups.get(email);

			if (customersWithEmail.size() > 1) {
				addPairwiseMatches(customersWithEmail, EXACT_EMAIL_SCORE, matches);
			}
		}
	}

	private void applyPhoneBasedMatchingRules(
		Map<String, List<Customer__c>> phoneGroups,
		List<Duplicate_Match__c> matches
	) {
		for (String phone : phoneGroups.keySet()) {
			List<Customer__c> customersWithPhone = phoneGroups.get(phone);

			if (customersWithPhone.size() > 1) {
				addPhoneBasedMatches(customersWithPhone, matches);
			}
		}
	}

	private void addPairwiseMatches(List<Customer__c> customers, Integer score, List<Duplicate_Match__c> matches) {
		for (Integer i = 0; i < customers.size(); i++) {
			for (Integer j = i + 1; j < customers.size(); j++) {
				Customer__c customerA = customers[i];
				Customer__c customerB = customers[j];

				Duplicate_Match__c match = new Duplicate_Match__c();
				match.Customer_A__c = customerA.Id;
				match.Customer_B__c = customerB.Id;
				match.Match_Score__c = score;
				match.Status__c = 'Pending Review';

				matches.add(match);
			}
		}
	}

	private void addPhoneBasedMatches(List<Customer__c> customers, List<Duplicate_Match__c> matches) {
		for (Integer i = 0; i < customers.size(); i++) {
			for (Integer j = i + 1; j < customers.size(); j++) {
				Customer__c customerA = customers[i];
				Customer__c customerB = customers[j];

				Integer matchScore = calculatePhoneBasedMatchScore(customerA, customerB);

				if (matchScore > 0) {
					Duplicate_Match__c match = new Duplicate_Match__c();
					match.Customer_A__c = customerA.Id;
					match.Customer_B__c = customerB.Id;
					match.Match_Score__c = matchScore;
					match.Status__c = 'Pending Review';

					matches.add(match);
				}
			}
		}
	}

	private Integer calculatePhoneBasedMatchScore(Customer__c customerA, Customer__c customerB) {
		String fullNameA = buildFullName(customerA.FirstName__c, customerA.LastName__c);
		String fullNameB = buildFullName(customerB.FirstName__c, customerB.LastName__c);

		if (String.isNotBlank(fullNameA) && String.isNotBlank(fullNameB)) {
			Decimal nameSimilarity = SimilarityScorer.calculateSimilarity(fullNameA, fullNameB);

			if (nameSimilarity >= NAME_SIMILARITY_THRESHOLD) {
				return PHONE_NAME_FUZZY_SCORE;
			}
		}

		if (hasMatchingLastNames(customerA.LastName__c, customerB.LastName__c)) {
			return PHONE_LASTNAME_SCORE;
		}

		return 0;
	}

	private String buildFullName(String firstName, String lastName) {
		String fullName = '';

		if (String.isNotBlank(firstName)) {
			fullName += firstName;
		}

		if (String.isNotBlank(lastName)) {
			if (String.isNotBlank(fullName)) {
				fullName += ' ';
			}
			fullName += lastName;
		}

		return String.isNotBlank(fullName) ? StringUtil.normalizeName(fullName) : '';
	}

	private Boolean hasMatchingLastNames(String lastNameA, String lastNameB) {
		if (String.isBlank(lastNameA) || String.isBlank(lastNameB)) {
			return false;
		}

		String normalizedA = StringUtil.normalizeName(lastNameA);
		String normalizedB = StringUtil.normalizeName(lastNameB);

		return normalizedA == normalizedB;
	}

	private String generatePairKey(Id recordAId, Id recordBId) {
		String firstId = String.valueOf(recordAId);
		String secondId = String.valueOf(recordBId);

		return (firstId < secondId) ? firstId + ':' + secondId : secondId + ':' + firstId;
	}

	private class CustomerBuckets {
		public Map<String, List<Customer__c>> emailGroups;
		public Map<String, List<Customer__c>> phoneGroups;

		public CustomerBuckets(Map<String, List<Customer__c>> emailGroups, Map<String, List<Customer__c>> phoneGroups) {
			this.emailGroups = emailGroups;
			this.phoneGroups = phoneGroups;
		}
	}
}
