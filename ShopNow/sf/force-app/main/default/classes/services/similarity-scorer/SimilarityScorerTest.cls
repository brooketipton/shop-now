@IsTest
public class SimilarityScorerTest {
	@IsTest
	static void testCalculateSimilarity_IdenticalStrings() {
		Test.startTest();

		Decimal result1 = SimilarityScorer.calculateSimilarity('John', 'John');
		Decimal result2 = SimilarityScorer.calculateSimilarity('SMITH', 'SMITH');
		Decimal result3 = SimilarityScorer.calculateSimilarity('test@email.com', 'test@email.com');

		Test.stopTest();

		System.assertEquals(1.0, result1, 'Identical strings should return similarity of 1.0');
		System.assertEquals(1.0, result2, 'Identical uppercase strings should return similarity of 1.0');
		System.assertEquals(1.0, result3, 'Identical email strings should return similarity of 1.0');
	}

	@IsTest
	static void testCalculateSimilarity_CaseInsensitive() {
		Test.startTest();

		Decimal result1 = SimilarityScorer.calculateSimilarity('John', 'JOHN');
		Decimal result2 = SimilarityScorer.calculateSimilarity('smith', 'Smith');
		Decimal result3 = SimilarityScorer.calculateSimilarity('McDonald', 'mcdonald');

		Test.stopTest();

		System.assertEquals(1.0, result1, 'Case differences should be normalized - identical after normalization');
		System.assertEquals(1.0, result2, 'Mixed case should be normalized - identical after normalization');
		System.assertEquals(1.0, result3, 'Different case should be normalized - identical after normalization');
	}

	@IsTest
	static void testCalculateSimilarity_NullAndEmpty() {
		Test.startTest();

		Decimal result1 = SimilarityScorer.calculateSimilarity(null, 'John');
		Decimal result2 = SimilarityScorer.calculateSimilarity('John', null);
		Decimal result3 = SimilarityScorer.calculateSimilarity(null, null);
		Decimal result4 = SimilarityScorer.calculateSimilarity('', 'John');
		Decimal result5 = SimilarityScorer.calculateSimilarity('John', '');
		Decimal result6 = SimilarityScorer.calculateSimilarity('', '');
		Decimal result7 = SimilarityScorer.calculateSimilarity('   ', 'John');

		Test.stopTest();

		System.assertEquals(0.0, result1, 'Null first string should return 0.0');
		System.assertEquals(0.0, result2, 'Null second string should return 0.0');
		System.assertEquals(1.0, result3, 'Both null should return 1.0 (identical)');
		System.assertEquals(0.0, result4, 'Empty first string should return 0.0');
		System.assertEquals(0.0, result5, 'Empty second string should return 0.0');
		System.assertEquals(1.0, result6, 'Both empty should return 1.0 (identical)');
		System.assertEquals(0.0, result7, 'Whitespace-only string should return 0.0 after normalization');
	}

	@IsTest
	static void testCalculateSimilarity_CompletelyDifferent() {
		Test.startTest();

		Decimal result1 = SimilarityScorer.calculateSimilarity('John', 'Xyz');
		Decimal result2 = SimilarityScorer.calculateSimilarity('Smith', 'Brown');
		Decimal result3 = SimilarityScorer.calculateSimilarity('ABC', '123');

		Test.stopTest();

		System.assertEquals(0.0, result1, 'Completely different strings should return 0.0');
		System.assertEquals(0.0, result2, 'Different surnames should return 0.0');
		System.assertEquals(0.0, result3, 'Letters vs numbers should return 0.0');
	}

	@IsTest
	static void testCalculateSimilarity_HighSimilarity() {
		Test.startTest();

		Decimal result1 = SimilarityScorer.calculateSimilarity('John', 'Jon');
		Decimal result2 = SimilarityScorer.calculateSimilarity('Smith', 'Smyth');
		Decimal result3 = SimilarityScorer.calculateSimilarity('Michael', 'Micheal');

		Test.stopTest();

		System.assert(result1 > 0.7, 'John vs Jon should have high similarity (>0.7), got: ' + result1);
		System.assert(result2 > 0.7, 'Smith vs Smyth should have high similarity (>0.7), got: ' + result2);
		System.assert(result3 > 0.8, 'Michael vs Micheal should have very high similarity (>0.8), got: ' + result3);
	}

	@IsTest
	static void testCalculateSimilarity_MediumSimilarity() {
		Test.startTest();

		Decimal result1 = SimilarityScorer.calculateSimilarity('John', 'Jane');
		Decimal result2 = SimilarityScorer.calculateSimilarity('Williams', 'Wilson');
		Decimal result3 = SimilarityScorer.calculateSimilarity('Robert', 'Roger');

		Test.stopTest();

		System.assert(
			result1 > 0.3 && result1 < 0.9,
			'John vs Jane should have medium similarity (0.3-0.9), got: ' + result1
		);
		System.assert(
			result2 > 0.3 && result2 < 0.9,
			'Williams vs Wilson should have medium similarity (0.3-0.9), got: ' + result2
		);
		System.assert(
			result3 > 0.3 && result3 < 0.9,
			'Robert vs Roger should have medium to high similarity (0.3-0.9), got: ' + result3
		);
	}

	@IsTest
	static void testCalculateSimilarity_CommonPrefix() {
		Test.startTest();

		Decimal result1 = SimilarityScorer.calculateSimilarity('Johnson', 'Jones');
		Decimal result2 = SimilarityScorer.calculateSimilarity('McDonald', 'McBride');
		Decimal result3 = SimilarityScorer.calculateSimilarity('Christopher', 'Christine');

		Test.stopTest();

		System.assert(result1 > 0.4, 'Johnson vs Jones should benefit from common prefix, got: ' + result1);
		System.assert(result2 > 0.4, 'McDonald vs McBride should benefit from common prefix, got: ' + result2);
		System.assert(
			result3 > 0.6,
			'Christopher vs Christine should benefit from long common prefix, got: ' + result3
		);
	}

	@IsTest
	static void testCalculateSimilarity_SingleCharacter() {
		Test.startTest();

		Decimal result1 = SimilarityScorer.calculateSimilarity('A', 'A');
		Decimal result2 = SimilarityScorer.calculateSimilarity('A', 'B');
		Decimal result3 = SimilarityScorer.calculateSimilarity('X', 'Y');

		Test.stopTest();

		System.assertEquals(1.0, result1, 'Identical single characters should return 1.0');
		System.assertEquals(0.0, result2, 'Different single characters should return 0.0');
		System.assertEquals(0.0, result3, 'Different single characters should return 0.0');
	}

	@IsTest
	static void testCalculateSimilarity_DifferentLengths() {
		Test.startTest();

		Decimal result1 = SimilarityScorer.calculateSimilarity('Jo', 'Johnson');
		Decimal result2 = SimilarityScorer.calculateSimilarity('Christopher', 'Chris');
		Decimal result3 = SimilarityScorer.calculateSimilarity('A', 'Alexander');

		Test.stopTest();

		System.assert(result1 > 0.5, 'Jo vs Johnson should have decent similarity due to prefix, got: ' + result1);
		System.assert(result2 > 0.6, 'Christopher vs Chris should have good similarity due to prefix, got: ' + result2);
		System.assert(
			result3 > 0.0 && result3 < 0.8,
			'A vs Alexander should have some similarity due to shared A, got: ' + result3
		);
	}

	@IsTest
	static void testCalculateSimilarity_SpecialCharacters() {
		Test.startTest();

		Decimal result1 = SimilarityScorer.calculateSimilarity('O\'Connor', 'OConnor');
		Decimal result2 = SimilarityScorer.calculateSimilarity('Smith-Jones', 'SmithJones');
		Decimal result3 = SimilarityScorer.calculateSimilarity('John123', 'John124');

		Test.stopTest();

		System.assert(result1 >= 0.0 && result1 <= 1.0, 'Result should be valid decimal between 0-1, got: ' + result1);
		System.assert(result2 >= 0.0 && result2 <= 1.0, 'Result should be valid decimal between 0-1, got: ' + result2);
		System.assert(result3 >= 0.0 && result3 <= 1.0, 'Result should be valid decimal between 0-1, got: ' + result3);
	}

	@IsTest
	static void testCalculateSimilarity_Transpositions() {
		Test.startTest();

		Decimal result1 = SimilarityScorer.calculateSimilarity('Martha', 'Marhta');
		Decimal result2 = SimilarityScorer.calculateSimilarity('Dixon', 'Dioxn');
		Decimal result3 = SimilarityScorer.calculateSimilarity('Crate', 'Trace');

		Test.stopTest();

		System.assert(
			result1 > 0.8,
			'Martha vs Marhta should have very high similarity due to simple transposition, got: ' + result1
		);
		System.assert(
			result2 > 0.7,
			'Dixon vs Dioxn should have high similarity due to transposition, got: ' + result2
		);
		System.assert(result3 > 0.5, 'Crate vs Trace should have decent similarity, got: ' + result3);
	}

	@IsTest
	static void testCalculateSimilarity_RealisticNames() {
		Test.startTest();

		Decimal result1 = SimilarityScorer.calculateSimilarity('William', 'Bill');
		Decimal result2 = SimilarityScorer.calculateSimilarity('Elizabeth', 'Beth');
		Decimal result3 = SimilarityScorer.calculateSimilarity('Catherine', 'Katherine');
		Decimal result4 = SimilarityScorer.calculateSimilarity('Jeffrey', 'Geoffrey');

		Test.stopTest();

		System.assert(
			result1 >= 0.0 && result1 <= 1.0,
			'William vs Bill should return valid similarity, got: ' + result1
		);
		System.assert(
			result2 >= 0.0 && result2 <= 1.0,
			'Elizabeth vs Beth should return valid similarity, got: ' + result2
		);
		System.assert(result3 > 0.5, 'Catherine vs Katherine should have decent similarity, got: ' + result3);
		System.assert(result4 > 0.4, 'Jeffrey vs Geoffrey should have decent similarity, got: ' + result4);
	}

	@IsTest
	static void testCalculateSimilarity_WhitespaceHandling() {
		Test.startTest();

		Decimal result1 = SimilarityScorer.calculateSimilarity('John Smith', 'JohnSmith');
		Decimal result2 = SimilarityScorer.calculateSimilarity('  John  ', 'John');
		Decimal result3 = SimilarityScorer.calculateSimilarity('JOHN SMITH', 'john smith');

		Test.stopTest();

		System.assert(result1 >= 0.0 && result1 <= 1.0, 'Whitespace test should return valid result, got: ' + result1);
		System.assert(result2 >= 0.0 && result2 <= 1.0, 'Trimming test should return valid result, got: ' + result2);
		System.assert(
			result3 >= 0.0 && result3 <= 1.0,
			'Case + whitespace test should return valid result, got: ' + result3
		);
	}
}
