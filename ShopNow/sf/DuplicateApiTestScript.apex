/**
 * Test script for Duplicate API endpoints
 * 
 * Instructions:
 * 1. Open Salesforce Developer Console
 * 2. Go to Debug > Open Execute Anonymous Window
 * 3. Copy and paste this entire script
 * 4. Check "Open Log" checkbox
 * 5. Click Execute
 * 
 * This script will:
 * - Create test customer records
 * - Create duplicate match records
 * - Test both API endpoints
 * - Clean up test data
 */

// Test configuration
Boolean CLEANUP_TEST_DATA = true; // Set to false if you want to keep test data
Boolean RUN_BATCH_SCAN = false;   // Set to true to test batch duplicate detection

System.debug('=== Starting Duplicate API Test Script ===');

try {
    // Step 1: Create test customers
    System.debug('\n--- Step 1: Creating Test Customers ---');
    
    List<Customer__c> testCustomers = new List<Customer__c>{
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
        ),
        new Customer__c(
            FirstName__c = 'Jane',
            LastName__c = 'Doe',
            Email__c = 'jane.doe@test.com',
            Phone__c = '+1-555-0456',
            SignupDate__c = Date.today().addDays(-15),
            Is_Merged__c = false
        ),
        new Customer__c(
            FirstName__c = 'Jane',
            LastName__c = 'Doe',
            Email__c = 'jane.doe@test.com', // Exact email match
            Phone__c = '+1-555-0789',
            SignupDate__c = Date.today().addDays(-10),
            Is_Merged__c = false
        )
    };
    
    insert testCustomers;
    System.debug('Created ' + testCustomers.size() + ' test customers');
    for (Customer__c customer : testCustomers) {
        System.debug('  - ' + customer.FirstName__c + ' ' + customer.LastName__c + ' (' + customer.Id + ')');
    }
    
    // Step 2: Create test duplicate matches
    System.debug('\n--- Step 2: Creating Test Duplicate Matches ---');
    
    List<Duplicate_Match__c> testMatches = new List<Duplicate_Match__c>{
        new Duplicate_Match__c(
            Customer_A__c = testCustomers[0].Id,
            Customer_B__c = testCustomers[1].Id,
            Match_Score__c = 75.5,
            Status__c = 'Pending Review',
            Pair_Key__c = generatePairKey(testCustomers[0].Id, testCustomers[1].Id)
        ),
        new Duplicate_Match__c(
            Customer_A__c = testCustomers[2].Id,
            Customer_B__c = testCustomers[3].Id,
            Match_Score__c = 100.0,
            Status__c = 'Pending Review',
            Pair_Key__c = generatePairKey(testCustomers[2].Id, testCustomers[3].Id)
        )
    };
    
    insert testMatches;
    System.debug('Created ' + testMatches.size() + ' test duplicate matches');
    for (Duplicate_Match__c match : testMatches) {
        System.debug('  - Match ' + match.Id + ': Score ' + match.Match_Score__c);
    }
    
    // Step 3: Test GET pending duplicates endpoint
    System.debug('\n--- Step 3: Testing GET /pending Endpoint ---');
    
    // Simulate RestContext for testing
    RestRequest mockRequest = new RestRequest();
    mockRequest.requestURI = '/services/apexrest/duplicates/pending';
    mockRequest.params = new Map<String, String>{
        'limit' => '10',
        'minScore' => '50'
    };
    RestContext.request = mockRequest;
    RestContext.response = new RestResponse();
    
    DuplicateApi.PendingDuplicatesResponse getResponse = DuplicateApi.getPendingDuplicates();
    
    System.debug('GET Response Success: ' + getResponse.success);
    System.debug('GET Response Count: ' + getResponse.count);
    System.debug('GET Response Error: ' + getResponse.error);
    
    if (getResponse.success && getResponse.matches.size() > 0) {
        System.debug('Found ' + getResponse.matches.size() + ' pending matches:');
        for (DuplicateApi.DuplicateMatchDto match : getResponse.matches) {
            System.debug('  - Match ' + match.id + ' (Score: ' + match.score + ')');
            System.debug('    Customer A: ' + match.customerA.name + ' (' + match.customerA.email + ')');
            System.debug('    Customer B: ' + match.customerB.name + ' (' + match.customerB.email + ')');
        }
    } else {
        System.debug('No matches found or error occurred');
    }
    
    // Step 4: Test POST resolve endpoint - Ignore action
    System.debug('\n--- Step 4: Testing POST /resolve Endpoint (Ignore) ---');
    
    if (testMatches.size() > 0) {
        String firstMatchId = testMatches[0].Id;
        
        RestRequest resolveRequest = new RestRequest();
        resolveRequest.requestURI = '/services/apexrest/duplicates/' + firstMatchId + '/resolve';
        resolveRequest.requestBody = Blob.valueOf('{"action": "ignore"}');
        RestContext.request = resolveRequest;
        RestContext.response = new RestResponse();
        
        DuplicateApi.ResolveResponse ignoreResponse = DuplicateApi.resolveDuplicate();
        
        System.debug('Ignore Response Result: ' + ignoreResponse.result);
        System.debug('Ignore Response Message: ' + ignoreResponse.message);
        
        // Verify the match was updated
        Duplicate_Match__c updatedMatch = [SELECT Status__c FROM Duplicate_Match__c WHERE Id = :firstMatchId];
        System.debug('Match status after ignore: ' + updatedMatch.Status__c);
    }
    
    // Step 5: Test POST resolve endpoint - Merge action
    System.debug('\n--- Step 5: Testing POST /resolve Endpoint (Merge) ---');
    
    if (testMatches.size() > 1) {
        String secondMatchId = testMatches[1].Id;
        
        RestRequest mergeRequest = new RestRequest();
        mergeRequest.requestURI = '/services/apexrest/duplicates/' + secondMatchId + '/resolve';
        mergeRequest.requestBody = Blob.valueOf('{"action": "merge"}');
        RestContext.request = mergeRequest;
        RestContext.response = new RestResponse();
        
        DuplicateApi.ResolveResponse mergeResponse = DuplicateApi.resolveDuplicate();
        
        System.debug('Merge Response Result: ' + mergeResponse.result);
        System.debug('Merge Response Message: ' + mergeResponse.message);
        System.debug('Winner ID: ' + mergeResponse.winnerId);
        System.debug('Loser ID: ' + mergeResponse.loserId);
        
        if (mergeResponse.result == 'ok') {
            // Verify the merge results
            List<Customer__c> mergedCustomers = [
                SELECT Id, FirstName__c, LastName__c, Email__c, Phone__c, Is_Merged__c, Merged_Into__c, Merged_On__c
                FROM Customer__c 
                WHERE Id IN (:mergeResponse.winnerId, :mergeResponse.loserId)
            ];
            
            System.debug('Merge verification:');
            for (Customer__c customer : mergedCustomers) {
                System.debug('  - Customer ' + customer.Id + ' (' + customer.FirstName__c + ' ' + customer.LastName__c + ')');
                System.debug('    Is_Merged__c: ' + customer.Is_Merged__c);
                if (customer.Is_Merged__c) {
                    System.debug('    Merged_Into__c: ' + customer.Merged_Into__c);
                    System.debug('    Merged_On__c: ' + customer.Merged_On__c);
                }
            }
            
            // Verify match status
            Duplicate_Match__c mergedMatch = [SELECT Status__c FROM Duplicate_Match__c WHERE Id = :secondMatchId];
            System.debug('Match status after merge: ' + mergedMatch.Status__c);
        }
    }
    
    // Step 6: Test error scenarios
    System.debug('\n--- Step 6: Testing Error Scenarios ---');
    
    // Test with invalid match ID
    RestRequest errorRequest = new RestRequest();
    errorRequest.requestURI = '/services/apexrest/duplicates/invalid_id/resolve';
    errorRequest.requestBody = Blob.valueOf('{"action": "merge"}');
    RestContext.request = errorRequest;
    RestContext.response = new RestResponse();
    
    DuplicateApi.ResolveResponse errorResponse = DuplicateApi.resolveDuplicate();
    System.debug('Error test - Invalid ID:');
    System.debug('  Result: ' + errorResponse.result);
    System.debug('  Message: ' + errorResponse.message);
    
    // Test with invalid action
    if (testMatches.size() > 0) {
        RestRequest invalidActionRequest = new RestRequest();
        invalidActionRequest.requestURI = '/services/apexrest/duplicates/' + testMatches[0].Id + '/resolve';
        invalidActionRequest.requestBody = Blob.valueOf('{"action": "invalid"}');
        RestContext.request = invalidActionRequest;
        RestContext.response = new RestResponse();
        
        DuplicateApi.ResolveResponse invalidActionResponse = DuplicateApi.resolveDuplicate();
        System.debug('Error test - Invalid Action:');
        System.debug('  Result: ' + invalidActionResponse.result);
        System.debug('  Message: ' + invalidActionResponse.message);
    }
    
    // Step 7: Test batch duplicate scanning (optional)
    if (RUN_BATCH_SCAN) {
        System.debug('\n--- Step 7: Testing Batch Duplicate Scan ---');
        
        // Create additional customers for batch testing
        List<Customer__c> batchTestCustomers = new List<Customer__c>{
            new Customer__c(
                FirstName__c = 'Michael',
                LastName__c = 'Johnson',
                Email__c = 'mike.johnson@test.com',
                Phone__c = '+1-555-1111'
            ),
            new Customer__c(
                FirstName__c = 'Mike',
                LastName__c = 'Johnson', 
                Email__c = 'michael.johnson@test.com',
                Phone__c = '+1-555-1111'
            )
        };
        insert batchTestCustomers;
        
        // Run batch duplicate scan
        BatchDuplicateScan batchJob = new BatchDuplicateScan();
        Id batchId = Database.executeBatch(batchJob, 200);
        System.debug('Started batch duplicate scan with ID: ' + batchId);
        System.debug('Check Setup > Apex Jobs to monitor batch progress');
    }
    
    // Step 8: Performance test
    System.debug('\n--- Step 8: Performance Test ---');
    
    Long startTime = System.currentTimeMillis();
    
    RestRequest perfRequest = new RestRequest();
    perfRequest.requestURI = '/services/apexrest/duplicates/pending';
    perfRequest.params = new Map<String, String>{'limit' => '100'};
    RestContext.request = perfRequest;
    RestContext.response = new RestResponse();
    
    DuplicateApi.PendingDuplicatesResponse perfResponse = DuplicateApi.getPendingDuplicates();
    
    Long endTime = System.currentTimeMillis();
    System.debug('Performance test completed in ' + (endTime - startTime) + ' ms');
    System.debug('Retrieved ' + perfResponse.count + ' records');
    
} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
} finally {
    // Step 9: Cleanup test data
    if (CLEANUP_TEST_DATA) {
        System.debug('\n--- Step 9: Cleaning Up Test Data ---');
        
        try {
            // Delete test matches
            List<Duplicate_Match__c> matchesToDelete = [
                SELECT Id FROM Duplicate_Match__c 
                WHERE Pair_Key__c LIKE '%test%' OR 
                      Customer_A__r.Email__c LIKE '%@test.com' OR 
                      Customer_B__r.Email__c LIKE '%@test.com'
            ];
            if (!matchesToDelete.isEmpty()) {
                delete matchesToDelete;
                System.debug('Deleted ' + matchesToDelete.size() + ' test matches');
            }
            
            // Delete test customers
            List<Customer__c> customersToDelete = [
                SELECT Id FROM Customer__c 
                WHERE Email__c LIKE '%@test.com'
            ];
            if (!customersToDelete.isEmpty()) {
                delete customersToDelete;
                System.debug('Deleted ' + customersToDelete.size() + ' test customers');
            }
            
        } catch (Exception cleanupError) {
            System.debug('Cleanup error: ' + cleanupError.getMessage());
        }
    } else {
        System.debug('\n--- Test Data Preserved ---');
        System.debug('Test customers and matches have been left in the system for manual inspection');
    }
}

System.debug('\n=== Duplicate API Test Script Completed ===');

// Helper method to generate pair key
private static String generatePairKey(Id id1, Id id2) {
    List<String> ids = new List<String>{String.valueOf(id1), String.valueOf(id2)};
    ids.sort();
    return ids[0] + '|' + ids[1];
}
