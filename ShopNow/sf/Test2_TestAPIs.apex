// Test 2: Test API Endpoints
System.debug('=== Testing APIs ===');

// Test GET pending
RestRequest req = new RestRequest();
req.requestURI = '/services/apexrest/duplicates/pending';
req.params = new Map<String, String>{'limit' => '10'};
RestContext.request = req;
RestContext.response = new RestResponse();

DuplicateApi.PendingDuplicatesResponse getResp = DuplicateApi.getPendingDuplicates();
System.debug('GET Success: ' + getResp.success + ', Count: ' + getResp.count);

// Get a match ID for testing
String testMatchId = null;
if (getResp.success && getResp.matches.size() > 0) {
    testMatchId = getResp.matches[0].id;
    System.debug('Using match ID: ' + testMatchId);
}

// Test POST ignore
if (testMatchId != null) {
    RestRequest ignoreReq = new RestRequest();
    ignoreReq.requestURI = '/services/apexrest/duplicates/' + testMatchId + '/resolve';
    ignoreReq.requestBody = Blob.valueOf('{"action": "ignore"}');
    RestContext.request = ignoreReq;
    RestContext.response = new RestResponse();
    
    DuplicateApi.ResolveResponse ignoreResp = DuplicateApi.resolveDuplicate();
    System.debug('Ignore Result: ' + ignoreResp.result + ' - ' + ignoreResp.message);
}

System.debug('=== API tests completed ===');
