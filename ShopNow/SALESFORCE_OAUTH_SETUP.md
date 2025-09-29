## Step 1: Create a Connected App in Salesforce

1. **Go to Setup** → App Manager → New Connected App

2. **Basic Information:**

   - Connected App Name: `Duplicate Management App`
   - API Name: `Duplicate_Management_App`
   - Contact Email: Your email

3. **API (Enable OAuth Settings):**

   - ✅ Enable OAuth Settings
   - **Callback URL**: `http://localhost:5173` (for development)
   - **Selected OAuth Scopes:**
     - Access and manage your data (api)
     - Perform requests on your behalf at any time (refresh_token, offline_access)

4. **Click Save** and wait 2-10 minutes for the app to be created

5. **Get Your Credentials:**
   - Go back to the Connected App
   - Copy the **Consumer Key** (this is your Client ID)

## Step 2: Configure Your React App

Update your `.env` file:

```env
# Salesforce OAuth Configuration
VITE_SALESFORCE_CLIENT_ID=your_consumer_key_here
VITE_SALESFORCE_INSTANCE_URL=https://your-org.salesforce.com
VITE_SALESFORCE_REDIRECT_URI=http://localhost:5173

# API Base (will be dynamically set after OAuth)
VITE_API_BASE=https://your-org.salesforce.com/services/apexrest/duplicates
```

## Step 3: Set Up Permission Set

Assign the **Duplicate Management Access** permission set to users who need access:

1. Setup → Users → Permission Sets
2. Find "Duplicate Management Access"
3. Click "Manage Assignments"
4. Add your users

## Step 4: Configure CORS (if needed)

If you get CORS errors:

1. Setup → Remote Site Settings → New Remote Site
2. **Remote Site Name**: `React_App_Dev`
3. **Remote Site URL**: `http://localhost:5173`
4. ✅ Active

## Step 5: Production Setup

For production deployment:

1. **Update Connected App:**

   - Add your production domain to Callback URLs
   - Example: `https://your-app.vercel.app`

2. **Update .env for production:**

   ```env
   VITE_SALESFORCE_REDIRECT_URI=https://your-app.vercel.app
   ```

3. **Add Remote Site for production domain**

## How OAuth Flow Works

1. **User clicks "Login with Salesforce"**
2. **App redirects to Salesforce OAuth URL**
3. **User logs into Salesforce**
4. **Salesforce redirects back with access token**
5. **App stores token and makes API calls**

## Security Benefits

✅ **No hardcoded credentials**
✅ **Tokens expire automatically**  
✅ **User-based permissions**
✅ **Audit trail in Salesforce**
✅ **Revokable access**

## Alternative: Named Credentials (For Salesforce → External APIs)

If you want to call external APIs FROM Salesforce Apex:

### Setup Named Credential:

1. Setup → Named Credentials → New Legacy
2. **Label**: `External_API_Service`
3. **URL**: `https://api.external-service.com`
4. **Identity Type**: Named Principal
5. **Authentication Protocol**: OAuth 2.0
6. Configure OAuth settings

### Use in Apex:

```apex
@RestResource(urlMapping='/external-data/*')
global class ExternalDataApi {

    @HttpGet
    global static String getExternalData() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:External_API_Service/data');
        req.setMethod('GET');

        Http http = new Http();
        HttpResponse res = http.send(req);

        return res.getBody();
    }
}
```

## Troubleshooting

**"Invalid Client ID"**: Double-check the Consumer Key in your .env file

**"Redirect URI Mismatch"**: Ensure the callback URL in the Connected App matches your app's URL

**"Access Denied"**: User needs the Duplicate Management Access permission set

**CORS Errors**: Add your app's domain to Remote Site Settings

**API Errors**: Check that the user has the ApiEnabled permission (included in the permission set)

## Testing the Setup

1. Start your React app: `npm run dev`
2. Click "Login with Salesforce"
3. Authenticate with your Salesforce credentials
4. You should see "✓ Authenticated with Salesforce"
5. The duplicate table should load automatically

This setup provides secure, user-based authentication without exposing session IDs or other credentials.
