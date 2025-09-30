/**
 * Utility class for calculating Jaro-Winkler string similarity
 *
 * The Jaro-Winkler algorithm measures similarity between two strings,
 * returning a value between 0 (no similarity) and 1 (identical strings).
 * It gives higher scores to strings that:
 * 1. Have more matching characters
 * 2. Have fewer transpositions (reordered/mistyped characters)
 * 3. Share a common prefix (up to 4 characters)
 */
public class SimilarityScorer {
	private static final Decimal WINKLER_PREFIX_SCALE = 0.1;
	private static final Integer MAX_PREFIX_LENGTH = 4;

	/**
	 * Calculates the Jaro-Winkler similarity between two strings.
	 *
	 * @param firstString The first string to compare
	 * @param secondString The second string to compare
	 * @return Decimal value between 0 and 1 representing similarity
	 */
	public static Decimal calculateSimilarity(String firstString, String secondString) {
		String normalizedFirst = StringUtil.normalizeName(firstString);
		String normalizedSecond = StringUtil.normalizeName(secondString);

		if (normalizedFirst == normalizedSecond) {
			return 1.0;
		}

		if (String.isBlank(normalizedFirst) || String.isBlank(normalizedSecond)) {
			return 0.0;
		}

		Decimal jaroSimilarity = calculateJaroSimilarity(normalizedFirst, normalizedSecond);

		if (jaroSimilarity == 0) {
			return 0.0;
		}

		Integer commonPrefixLength = getCommonPrefixLength(normalizedFirst, normalizedSecond);
		Decimal winklerBonus = WINKLER_PREFIX_SCALE * commonPrefixLength * (1 - jaroSimilarity);

		return jaroSimilarity + winklerBonus;
	}

	private static Decimal calculateJaroSimilarity(String firstString, String secondString) {
		Integer firstLength = firstString.length();
		Integer secondLength = secondString.length();

		Integer maxMatchDistance = Math.max(firstLength, secondLength) / 2 - 1;
		if (maxMatchDistance < 0) {
			maxMatchDistance = 0;
		}

		MatchingResult matchingResult = findMatchingCharacters(firstString, secondString, maxMatchDistance);

		if (matchingResult.matchCount == 0) {
			return 0.0;
		}

		// Count transpositions (matching characters in wrong order)
		Integer transpositionCount = countTranspositions(
			matchingResult.firstMatches,
			matchingResult.secondMatches,
			firstString,
			secondString
		);

		// Calculate Jaro similarity using the standard formula
		Decimal matchRatio1 = (Decimal) matchingResult.matchCount / firstLength;
		Decimal matchRatio2 = (Decimal) matchingResult.matchCount / secondLength;
		Decimal transpositionRatio =
			((Decimal) matchingResult.matchCount - transpositionCount / 2.0) / matchingResult.matchCount;

		return (matchRatio1 + matchRatio2 + transpositionRatio) / 3.0;
	}

	private static MatchingResult findMatchingCharacters(String firstString, String secondString, Integer maxDistance) {
		// Store the positions of matching characters in the first string
		Set<Integer> firstMatches = new Set<Integer>();
		// Store the positions of matching characters in the second string
		Set<Integer> secondMatches = new Set<Integer>();
		Integer matchCount = 0;

		// For each character in the first string
		for (Integer i = 0; i < firstString.length(); i++) {
			String currentChar = firstString.substring(i, i + 1);

			// Define search window in second string
			Integer searchStart = Math.max(0, i - maxDistance);
			Integer searchEnd = Math.min(i + maxDistance + 1, secondString.length());

			// Look for matching characters within the search window
			for (Integer j = searchStart; j < searchEnd; j++) {
				if (secondMatches.contains(j)) {
					continue;
				}

				String targetChar = secondString.substring(j, j + 1);
				if (currentChar == targetChar) {
					firstMatches.add(i);
					secondMatches.add(j);
					matchCount++;
					break;
				}
			}
		}

		return new MatchingResult(firstMatches, secondMatches, matchCount);
	}

	private static Integer countTranspositions(
		Set<Integer> firstMatches,
		Set<Integer> secondMatches,
		String firstString,
		String secondString
	) {
		Integer transpositions = 0;
		Integer secondIndex = 0;

		// Go through matched positions in first string
		for (Integer firstIndex = 0; firstIndex < firstString.length(); firstIndex++) {
			if (!firstMatches.contains(firstIndex)) {
				continue;
			}

			// Find corresponding matched position in second string
			while (!secondMatches.contains(secondIndex)) {
				secondIndex++;
			}

			// Compare characters at matched positions
			String firstChar = firstString.substring(firstIndex, firstIndex + 1);
			String secondChar = secondString.substring(secondIndex, secondIndex + 1);

			if (firstChar != secondChar) {
				transpositions++;
			}

			secondIndex++;
		}

		return transpositions;
	}

	private static Integer getCommonPrefixLength(String firstString, String secondString) {
		Integer prefixLength = 0;
		Integer maxPrefixLength = Math.min(MAX_PREFIX_LENGTH, Math.min(firstString.length(), secondString.length()));

		for (Integer i = 0; i < maxPrefixLength; i++) {
			String firstChar = firstString.substring(i, i + 1);
			String secondChar = secondString.substring(i, i + 1);

			if (firstChar == secondChar) {
				prefixLength++;
			} else {
				break;
			}
		}

		return prefixLength;
	}

	private class MatchingResult {
		public Set<Integer> firstMatches;
		public Set<Integer> secondMatches;
		public Integer matchCount;

		public MatchingResult(Set<Integer> firstMatches, Set<Integer> secondMatches, Integer matchCount) {
			this.firstMatches = firstMatches;
			this.secondMatches = secondMatches;
			this.matchCount = matchCount;
		}
	}
}
