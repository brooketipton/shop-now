// Test 1: Create Test Data
System.debug('=== Creating Test Data ===');

List<Customer__c> customers = new List<Customer__c>{
    new Customer__c(FirstName__c='John', LastName__c='Smith', Email__c='john@test.com', Phone__c='555-0123'),
    new Customer__c(FirstName__c='J', LastName__c='Smith', Email__c='j@test.com', Phone__c='555-0123'),
    new Customer__c(FirstName__c='Jane', LastName__c='Doe', Email__c='jane@test.com', Phone__c='555-0456'),
    new Customer__c(FirstName__c='Jane', LastName__c='Doe', Email__c='jane@test.com', Phone__c='555-0789')
};
insert customers;

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

System.debug('Created customers: ' + customers);
System.debug('Created matches: ' + matches);
System.debug('=== Test data ready ===');
