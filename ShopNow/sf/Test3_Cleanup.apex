// Test 3: Cleanup Test Data
System.debug('=== Cleaning up test data ===');

try {
    List<Duplicate_Match__c> matchesToDelete = [
        SELECT Id FROM Duplicate_Match__c 
        WHERE Customer_A__r.Email__c LIKE '%@test.com' 
        OR Customer_B__r.Email__c LIKE '%@test.com'
    ];
    delete matchesToDelete;
    System.debug('Deleted ' + matchesToDelete.size() + ' matches');
    
    List<Customer__c> customersToDelete = [
        SELECT Id FROM Customer__c 
        WHERE Email__c LIKE '%@test.com'
    ];
    delete customersToDelete;
    System.debug('Deleted ' + customersToDelete.size() + ' customers');
    
} catch (Exception e) {
    System.debug('Cleanup error: ' + e.getMessage());
}

System.debug('=== Cleanup completed ===');
