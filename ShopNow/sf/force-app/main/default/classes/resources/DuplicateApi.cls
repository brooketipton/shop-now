/**
 * REST API for managing duplicate customer records.
 * 
 * Endpoints:
 * - GET /duplicates/pending → returns list of customer pairs + match score
 * - POST /duplicates/{id}/resolve → body { action: 'merge' | 'ignore' }
 */
@RestResource(urlMapping='/duplicates/*')
global with sharing class DuplicateApi {
    
    /**
     * GET /duplicates/pending
     * Returns all duplicate matches with status 'Pending Review'
     */
    @HttpGet
    global static List<DuplicateMatchResponse> getPendingDuplicates() {
        List<DuplicateMatchResponse> response = new List<DuplicateMatchResponse>();
        
        try {
            List<Duplicate_Match__c> pendingMatches = [
                SELECT Id, Customer_A__c, Customer_B__c, Match_Score__c, Status__c,
                       Customer_A__r.FirstName__c, Customer_A__r.LastName__c, Customer_A__r.Email__c, Customer_A__r.Phone__c,
                       Customer_B__r.FirstName__c, Customer_B__r.LastName__c, Customer_B__r.Email__c, Customer_B__r.Phone__c
                FROM Duplicate_Match__c
                WHERE Status__c = 'Pending Review'
                ORDER BY Match_Score__c DESC, CreatedDate DESC
            ];
            
            for (Duplicate_Match__c match : pendingMatches) {
                DuplicateMatchResponse matchResponse = new DuplicateMatchResponse();
                matchResponse.id = match.Id;
                matchResponse.matchScore = Integer.valueOf(match.Match_Score__c);
                matchResponse.status = match.Status__c;
                
                // Customer A details
                matchResponse.customerA = new CustomerInfo();
                matchResponse.customerA.id = match.Customer_A__c;
                matchResponse.customerA.firstName = match.Customer_A__r.FirstName__c;
                matchResponse.customerA.lastName = match.Customer_A__r.LastName__c;
                matchResponse.customerA.email = match.Customer_A__r.Email__c;
                matchResponse.customerA.phone = match.Customer_A__r.Phone__c;
                
                // Customer B details
                matchResponse.customerB = new CustomerInfo();
                matchResponse.customerB.id = match.Customer_B__c;
                matchResponse.customerB.firstName = match.Customer_B__r.FirstName__c;
                matchResponse.customerB.lastName = match.Customer_B__r.LastName__c;
                matchResponse.customerB.email = match.Customer_B__r.Email__c;
                matchResponse.customerB.phone = match.Customer_B__r.Phone__c;
                
                response.add(matchResponse);
            }
            
        } catch (Exception e) {
            RestContext.response.statusCode = 500;
            ApiErrorResponse error = new ApiErrorResponse();
            error.error = 'Internal Server Error';
            error.message = 'Failed to retrieve pending duplicates: ' + e.getMessage();
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(error));
            return null;
        }
        
        return response;
    }
    
    /**
     * POST /duplicates/{id}/resolve
     * Resolves a duplicate match by merging or ignoring
     */
    @HttpPost
    global static ApiResponse resolveDuplicate() {
        ApiResponse response = new ApiResponse();
        
        try {
            // Extract duplicate match ID from URL
            String requestUri = RestContext.request.requestURI;
            String duplicateId = extractDuplicateId(requestUri);
            
            if (String.isBlank(duplicateId)) {
                RestContext.response.statusCode = 400;
                response.success = false;
                response.message = 'Invalid duplicate match ID in URL';
                return response;
            }
            
            // Parse request body
            String requestBody = RestContext.request.requestBody.toString();
            ResolveRequest resolveRequest = (ResolveRequest) JSON.deserialize(requestBody, ResolveRequest.class);
            
            if (resolveRequest == null || String.isBlank(resolveRequest.action)) {
                RestContext.response.statusCode = 400;
                response.success = false;
                response.message = 'Missing or invalid action in request body. Expected: {"action": "merge" | "ignore"}';
                return response;
            }
            
            // Validate action
            if (resolveRequest.action != 'merge' && resolveRequest.action != 'ignore') {
                RestContext.response.statusCode = 400;
                response.success = false;
                response.message = 'Invalid action. Must be "merge" or "ignore"';
                return response;
            }
            
            // Find and update the duplicate match
            List<Duplicate_Match__c> matches = [
                SELECT Id, Status__c, Customer_A__c, Customer_B__c
                FROM Duplicate_Match__c
                WHERE Id = :duplicateId
                LIMIT 1
            ];
            
            if (matches.isEmpty()) {
                RestContext.response.statusCode = 404;
                response.success = false;
                response.message = 'Duplicate match not found';
                return response;
            }
            
            Duplicate_Match__c match = matches[0];
            
            // Check if already resolved
            if (match.Status__c != 'Pending Review') {
                RestContext.response.statusCode = 409;
                response.success = false;
                response.message = 'Duplicate match already resolved with status: ' + match.Status__c;
                return response;
            }
            
            // Update status based on action
            if (resolveRequest.action == 'merge') {
                match.Status__c = 'Merged';
                // TODO: Implement actual customer merge logic here
                // This would typically merge Customer_B into Customer_A and mark Customer_B as merged
            } else if (resolveRequest.action == 'ignore') {
                match.Status__c = 'Ignored';
            }
            
            update match;
            
            response.success = true;
            response.message = 'Duplicate match resolved successfully with action: ' + resolveRequest.action;
            
        } catch (JSONException e) {
            RestContext.response.statusCode = 400;
            response.success = false;
            response.message = 'Invalid JSON in request body: ' + e.getMessage();
        } catch (Exception e) {
            RestContext.response.statusCode = 500;
            response.success = false;
            response.message = 'Internal server error: ' + e.getMessage();
        }
        
        return response;
    }
    
    /**
     * Extracts duplicate match ID from the request URI
     */
    private static String extractDuplicateId(String requestUri) {
        // Expected format: /services/apexrest/duplicates/{id}/resolve
        if (String.isBlank(requestUri)) {
            return null;
        }
        
        String[] uriParts = requestUri.split('/');
        for (Integer i = 0; i < uriParts.size(); i++) {
            if (uriParts[i] == 'duplicates' && i + 1 < uriParts.size()) {
                return uriParts[i + 1];
            }
        }
        
        return null;
    }
    
    // Response wrapper classes
    global class DuplicateMatchResponse {
        @AuraEnabled global String id;
        @AuraEnabled global CustomerInfo customerA;
        @AuraEnabled global CustomerInfo customerB;
        @AuraEnabled global Integer matchScore;
        @AuraEnabled global String status;
    }
    
    global class CustomerInfo {
        @AuraEnabled global String id;
        @AuraEnabled global String firstName;
        @AuraEnabled global String lastName;
        @AuraEnabled global String email;
        @AuraEnabled global String phone;
    }
    
    global class ApiResponse {
        @AuraEnabled global Boolean success = true;
        @AuraEnabled global String message;
    }
    
    global class ApiErrorResponse {
        @AuraEnabled global String error;
        @AuraEnabled global String message;
    }
    
    // Request wrapper classes
    global class ResolveRequest {
        @AuraEnabled global String action; // 'merge' or 'ignore'
    }
}