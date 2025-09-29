# ShopNow Duplicate Management System

A comprehensive solution for managing duplicate customer records in Salesforce with a React-based frontend interface.

## 🚀 Quick Start

### Prerequisites

- Node.js 16+
- Salesforce CLI (`npm install -g @salesforce/cli`)
- Authenticated Salesforce org (`sf org login web`)

### Automated Setup

```bash
# Clone and setup everything automatically
git clone <your-repo>
cd ShopNow

# Run the automated OAuth setup script
npm run setup:oauth

# Start the development server
npm start
```

The setup script will:

- ✅ Create a Connected App in Salesforce
- ✅ Configure OAuth settings
- ✅ Retrieve the Consumer Key
- ✅ Update your .env file
- ✅ Add CORS settings

## 📁 Project Structure

```
ShopNow/
├── force-app/                    # Salesforce metadata
│   ├── main/default/
│   │   ├── classes/              # Apex classes
│   │   │   ├── resources/        # API classes
│   │   │   │   └── DuplicateApi.cls
│   │   │   ├── services/         # Business logic
│   │   │   │   ├── DedupeService.cls
│   │   │   │   ├── SimilarityScorer.cls
│   │   │   │   └── batchable/
│   │   │   │       └── BatchDuplicateScan.cls
│   │   │   └── utilities/
│   │   │       └── StringUtil.cls
│   │   ├── objects/              # Custom objects
│   │   │   ├── Customer__c/
│   │   │   └── Duplicate_Match__c/
│   │   └── permissionsets/       # Security
│   │       └── Duplicate_Management_Access.permissionset-meta.xml
├── app/                          # React frontend
│   ├── src/
│   │   ├── components/           # React components
│   │   ├── auth/                 # OAuth authentication
│   │   ├── api.ts               # Salesforce API client
│   │   └── types.ts             # TypeScript interfaces
│   ├── package.json
│   └── .env                     # Environment config (auto-generated)
├── scripts/
│   └── setup-oauth.js           # Automated setup script
└── docs/                        # Documentation
```

## 🔧 Manual Setup (if automated setup fails)

### 1. Deploy Salesforce Components

```bash
sf project deploy start --source-dir force-app
```

### 2. Create Connected App

1. Setup → App Manager → New Connected App
2. **Name**: Duplicate Management App
3. **Contact Email**: Your email
4. **Enable OAuth Settings**: ✅
5. **Callback URLs**: `http://localhost:5173`
6. **Scopes**:
   - Access and manage your data (api)
   - Perform requests on your behalf at any time (refresh_token)

### 3. Configure React App

Create `app/.env`:

```env
VITE_SALESFORCE_CLIENT_ID=your_consumer_key_here
VITE_SALESFORCE_INSTANCE_URL=https://your-org.salesforce.com
VITE_SALESFORCE_REDIRECT_URI=http://localhost:5173
VITE_API_BASE=https://your-org.salesforce.com/services/apexrest/duplicates
```

### 4. Install and Start

```bash
cd app
npm install
npm run dev
```

## 🔑 Authentication

The system uses OAuth 2.0 for secure authentication:

1. **User clicks "Login with Salesforce"**
2. **Redirects to Salesforce OAuth**
3. **User authenticates**
4. **Returns with access token**
5. **App uses token for API calls**

## 📊 Features

### Salesforce Backend

- **REST API** (`@RestResource` endpoints)
- **Batch Duplicate Detection** (Jaro-Winkler algorithm)
- **Smart Merging Logic** (completeness-based winner selection)
- **Comprehensive Permission Sets**

### React Frontend

- **OAuth Authentication**
- **Headless Table** (TanStack Table)
- **Real-time Updates** (React Query)
- **TypeScript** for type safety

## 🎯 API Endpoints

### GET `/services/apexrest/duplicates/pending`

Retrieve pending duplicate matches

```typescript
// Query parameters
?limit=50&minScore=70

// Response
{
  "success": true,
  "count": 25,
  "matches": [
    {
      "id": "a05...",
      "score": 95.5,
      "customerA": { "id": "a04...", "name": "John Smith", "email": "..." },
      "customerB": { "id": "a04...", "name": "J. Smith", "email": "..." }
    }
  ]
}
```

### POST `/services/apexrest/duplicates/{id}/resolve`

Resolve a duplicate match

```typescript
// Request body
{ "action": "merge" | "ignore" }

// Response
{
  "result": "ok",
  "message": "Customers successfully merged",
  "winnerId": "a04...",
  "loserId": "a04..."
}
```

## 🔒 Security

- **Permission Sets**: Granular field-level security
- **OAuth 2.0**: Industry-standard authentication
- **CORS Configuration**: Secure cross-origin requests
- **Audit Trail**: All actions logged in Salesforce

## 🚀 Production Deployment

### Update Connected App

1. Add production domain to Callback URLs
2. Update Remote Site Settings

### Environment Variables

```env
# Production .env
VITE_SALESFORCE_CLIENT_ID=your_consumer_key
VITE_SALESFORCE_INSTANCE_URL=https://your-production-org.salesforce.com
VITE_SALESFORCE_REDIRECT_URI=https://your-app.vercel.app
```

### Deploy

```bash
# Deploy Salesforce components
npm run deploy:salesforce

# Build and deploy React app
npm run build
# Deploy build/ folder to your hosting platform
```

## 🛠 Development Commands

```bash
# Setup everything
npm run setup:oauth

# Development
npm start                    # Start React dev server
npm run build               # Build React app
npm run deploy:salesforce   # Deploy Apex classes
npm run deploy:full         # Deploy everything

# Salesforce-specific
sf org login web            # Authenticate with Salesforce
sf project deploy start    # Deploy metadata
sf data import tree         # Import test data
```

## 🐛 Troubleshooting

### Common Issues

**"Invalid Client ID"**

- Check Consumer Key in .env file
- Ensure Connected App is deployed

**"Redirect URI Mismatch"**

- Verify callback URLs in Connected App
- Check VITE_SALESFORCE_REDIRECT_URI

**CORS Errors**

- Add domain to Remote Site Settings
- Check Setup → Remote Site Settings

**"Access Denied"**

- Assign Duplicate Management Access permission set
- Check user has ApiEnabled permission

### Debug Commands

```bash
# Check Salesforce CLI
sf --version

# Check org connection
sf org display

# View deployment status
sf project deploy report

# Test API endpoints
sf apex run --file scripts/test-api.apex
```

## 📚 Documentation

- [Salesforce OAuth Setup](./SALESFORCE_OAUTH_SETUP.md) - Detailed OAuth configuration
- [API Documentation](./DUPLICATE_API_README.md) - Complete API reference
- [Architecture Overview](./docs/ARCHITECTURE.md) - System design details

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

MIT License - see [LICENSE](./LICENSE) for details.
