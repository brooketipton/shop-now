/**
 * Simple Duplicate API Test Script
 * This version tests the API logic without RestContext complications
 */

System.debug('=== Simple Duplicate API Test ===');

try {
    // Create test customers
    List<Customer__c> customers = new List<Customer__c>{
        new Customer__c(FirstName__c='John', LastName__c='Smith', Email__c='john@test.com', Phone__c='555-0123'),
        new Customer__c(FirstName__c='J', LastName__c='Smith', Email__c='j@test.com', Phone__c='555-0123'),
        new Customer__c(FirstName__c='Jane', LastName__c='Doe', Email__c='jane@test.com', Phone__c='555-0456'),
        new Customer__c(FirstName__c='Jane', LastName__c='Doe', Email__c='jane@test.com', Phone__c='555-0789')
    };
    insert customers;
    System.debug('Created ' + customers.size() + ' test customers');
    
    // Create test matches
    List<Duplicate_Match__c> matches = new List<Duplicate_Match__c>{
        new Duplicate_Match__c(
            Customer_A__c=customers[0].Id, Customer_B__c=customers[1].Id, 
            Match_Score__c=75.5, Status__c='Pending Review',
            Pair_Key__c=customers[0].Id + '|' + customers[1].Id
        ),
        new Duplicate_Match__c(
            Customer_A__c=customers[2].Id, Customer_B__c=customers[3].Id,
            Match_Score__c=100.0, Status__c='Pending Review', 
            Pair_Key__c=customers[2].Id + '|' + customers[3].Id
        )
    };
    insert matches;
    System.debug('Created ' + matches.size() + ' test matches');
    
    // Test 1: Query pending duplicates directly (simulating GET endpoint)
    System.debug('\n--- Test 1: Query Pending Duplicates ---');
    List<Duplicate_Match__c> pendingMatches = [
        SELECT
            Id, Match_Score__c, Customer_A__c, Customer_B__c, CreatedDate,
            Customer_A__r.FirstName__c, Customer_A__r.LastName__c, Customer_A__r.Email__c, Customer_A__r.Phone__c,
            Customer_B__r.FirstName__c, Customer_B__r.LastName__c, Customer_B__r.Email__c, Customer_B__r.Phone__c
        FROM Duplicate_Match__c
        WHERE Status__c = 'Pending Review' AND Match_Score__c >= 50
        ORDER BY Match_Score__c DESC, CreatedDate DESC
        LIMIT 10
    ];
    
    System.debug('Found ' + pendingMatches.size() + ' pending matches');
    for (Duplicate_Match__c match : pendingMatches) {
        System.debug('Match ' + match.Id + ': Score ' + match.Match_Score__c);
        System.debug('  A: ' + match.Customer_A__r.FirstName__c + ' ' + match.Customer_A__r.LastName__c);
        System.debug('  B: ' + match.Customer_B__r.FirstName__c + ' ' + match.Customer_B__r.LastName__c);
    }
    
    // Test 2: Test ignore logic (simulating POST ignore)
    System.debug('\n--- Test 2: Ignore Match Logic ---');
    if (matches.size() > 0) {
        Duplicate_Match__c testMatch = matches[0];
        System.debug('Before ignore: Status = ' + testMatch.Status__c);
        
        // Simulate ignore action
        testMatch.Status__c = 'Ignored';
        update testMatch;
        
        // Verify
        Duplicate_Match__c updatedMatch = [SELECT Status__c FROM Duplicate_Match__c WHERE Id = :testMatch.Id];
        System.debug('After ignore: Status = ' + updatedMatch.Status__c);
    }
    
    // Test 3: Test merge logic (simulating POST merge)
    System.debug('\n--- Test 3: Merge Logic ---');
    if (matches.size() > 1) {
        Duplicate_Match__c mergeMatch = matches[1];
        Customer__c customerA = customers[2];
        Customer__c customerB = customers[3];
        
        System.debug('Before merge:');
        System.debug('  Customer A: ' + customerA.FirstName__c + ' ' + customerA.LastName__c + ' (' + customerA.Email__c + ')');
        System.debug('  Customer B: ' + customerB.FirstName__c + ' ' + customerB.LastName__c + ' (' + customerB.Email__c + ')');
        
        // Determine winner (Customer B has same email, so should win based on completeness or date)
        Customer__c winner = customerA;
        Customer__c loser = customerB;
        
        // Merge fields
        if (String.isBlank(winner.FirstName__c) && String.isNotBlank(loser.FirstName__c)) {
            winner.FirstName__c = loser.FirstName__c;
        }
        if (String.isBlank(winner.Phone__c) && String.isNotBlank(loser.Phone__c)) {
            winner.Phone__c = loser.Phone__c;
        }
        
        // Mark loser as merged
        loser.Is_Merged__c = true;
        loser.Merged_Into__c = winner.Id;
        loser.Merged_On__c = Datetime.now();
        
        // Update match status
        mergeMatch.Status__c = 'Merged';
        
        // Perform updates
        update new List<SObject>{ winner, loser, mergeMatch };
        
        System.debug('After merge:');
        System.debug('  Winner: ' + winner.FirstName__c + ' ' + winner.LastName__c + ' (' + winner.Id + ')');
        System.debug('  Loser: Merged into ' + loser.Merged_Into__c + ' on ' + loser.Merged_On__c);
        System.debug('  Match Status: ' + mergeMatch.Status__c);
    }
    
    // Test 4: Test SimilarityScorer
    System.debug('\n--- Test 4: Similarity Scoring ---');
    Decimal similarity1 = SimilarityScorer.calculateSimilarity('John Smith', 'J Smith');
    Decimal similarity2 = SimilarityScorer.calculateSimilarity('Jane Doe', 'Jane Doe');
    Decimal similarity3 = SimilarityScorer.calculateSimilarity('John Smith', 'Bob Johnson');
    
    System.debug('Similarity "John Smith" vs "J Smith": ' + similarity1);
    System.debug('Similarity "Jane Doe" vs "Jane Doe": ' + similarity2);
    System.debug('Similarity "John Smith" vs "Bob Johnson": ' + similarity3);
    
    // Test 5: Test BatchDuplicateScan (optional)
    System.debug('\n--- Test 5: Batch Scan Test (Optional) ---');
    System.debug('To test batch scanning, run: Database.executeBatch(new BatchDuplicateScan(), 200);');
    
} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
} finally {
    // Cleanup
    try {
        delete [SELECT Id FROM Duplicate_Match__c WHERE Customer_A__r.Email__c LIKE '%@test.com'];
        delete [SELECT Id FROM Customer__c WHERE Email__c LIKE '%@test.com'];
        System.debug('\nTest data cleaned up');
    } catch (Exception ex) {
        System.debug('Cleanup error: ' + ex.getMessage());
    }
}

System.debug('=== Test Completed ===');
