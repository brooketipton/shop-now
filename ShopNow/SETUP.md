# ShopNow Duplicate Management System - Setup Guide

## What Is This Project?

ShopNow is a comprehensive customer duplicate detection and management system that helps businesses identify and merge duplicate customer records automatically. The system consists of three main components:

- **React Frontend** - User interface for reviewing and resolving duplicate customers
- **Node.js API Server** - Proxy server that handles authentication and API routing
- **Salesforce Backend** - Core business logic for duplicate detection and customer merging

### The Problem It Solves

When customers sign up multiple times with slight variations in their information (like "John Smith" vs "J. Smith" or different email formats), businesses end up with fragmented customer data. This system automatically finds these duplicates and provides tools to merge them intelligently.

## Quick Start

### Prerequisites

Before you begin, ensure you have:

- **Node.js** (v16 or higher)
- **npm**
- **Salesforce Developer Account** (free at [developer.salesforce.com](https://developer.salesforce.com))
- **Salesforce CLI** (install with `npm install -g @salesforce/cli`)

### 1. Clone and Setup

```bash
# Clone the repository
git clone the-repo
cd ShopNow

# Install dependencies for all components
npm run setup

# Start the development environment
npm start
```

### 2. Salesforce Setup

```bash
# Navigate to the Salesforce directory
cd sf

# Authenticate with your Salesforce org
sf org login web

# Deploy the metadata to your org
sf project deploy start

# Assign permissions to your user
sf org assign permset -n "Duplicate_Management_Access"
```

### 3. Generate Test Data (Optional)

To see the system in action:

1. Open your Salesforce org
2. Go to the App Launcher (9 dots icon)
3. Go to the service or home page in your org to see the Test Data Controller LWC
4. Click "Generate Test Data" to create sample customers
5. Click "Run Duplicate Scan" to find duplicates and prep them for the react UI

### 4. Access the Application

Once everything is running:

- **Frontend**: http://localhost:5173
- **API Server**: http://localhost:3001
- **Salesforce Org**: Your Salesforce instance

## Detailed Setup Instructions

### Frontend (React App)

The React application provides the user interface for duplicate management.

```bash
cd app
npm install
npm run dev
```

**Features:**

- Display pending duplicate customer pairs
- Show confidence scores and customer details
- Allow users to merge or ignore duplicates
- Real-time updates after resolution

### Backend Server (Node.js)

The Node.js server acts as a proxy between the React app and Salesforce.

```bash
cd server
npm install
npm start
```

**What it does:**

- Handles CORS for frontend-backend communication
- Proxies requests to Salesforce APIs
- Manages authentication (simplified for demo)
- Provides error handling and logging

### Salesforce Backend

The Salesforce org contains the core business logic and data storage.

#### Key Components:

**📊 Custom Objects:**

- `Customer__c` - Stores customer information
- `Duplicate_Match__c` - Tracks potential duplicate pairs

**🤖 Automated Services:**

- `BatchDuplicateScan` - Finds duplicates using intelligent algorithms
- `CustomerMerger` - Merges duplicate customers with smart data consolidation
- `SimilarityScorer` - Calculates name similarity for fuzzy matching

**🔧 Utilities:**

- `TestDataController` - Generates sample data for testing
- `StringUtil` - Handles name and phone normalization

## Project Structure

```
ShopNow/
├── app/                          # React frontend
│   ├── src/
│   │   ├── components/           # React components
│   │   ├── api.ts               # API client
│   │   └── types.ts             # TypeScript definitions
│   └── package.json
├── server/                       # Node.js API server
│   ├── server.js                # Express server
│   └── package.json
├── sf/                          # Salesforce backend
│   ├── force-app/main/default/
│   │   ├── classes/             # Apex classes
│   │   ├── objects/             # Custom objects
│   │   ├── lwc/                 # Lightning Web Components
│   │   └── permissionsets/      # Security settings
│   └── sfdx-project.json
├── SETUP.md                     # This file
├── README.md                    # Project overview
├── package.json                 # Root package file
└── start-dev.sh                 # Development startup script
```

## How the System Works

### 1. Data Collection

Customer information is stored in Salesforce `Customer__c` objects with fields like:

- First Name, Last Name
- Email, Phone
- Signup Date
- Merge tracking fields

### 2. Duplicate Detection

The `BatchDuplicateScan` service runs periodically and uses three matching rules:

- **Email Match (100% confidence)**: Exact email address match
- **Phone + Name Similarity (70% confidence)**: Same phone + 90%+ name similarity
- **Phone + Last Name (50% confidence)**: Same phone + exact last name match

### 3. Review Process

Potential duplicates are stored in `Duplicate_Match__c` records with:

- References to both customer records
- Confidence score
- Status (Pending Review, Merged, Ignored)

### 4. Resolution

Users can review duplicates in the React app and choose to:

- **Merge**: Combines records using intelligent data consolidation
- **Ignore**: Marks the pair as not duplicates

### 5. Data Consolidation

When merging, the system:

- Keeps longer, more complete names
- Preserves earlier signup dates
- Maintains winner's contact information
- Marks loser record as merged with audit trail

## Development Commands

### Root Level

```bash
npm start          # Start both server and React app
npm run setup      # Install all dependencies
npm run clean      # Clean all node_modules
```

### Frontend (app/)

```bash
npm run dev        # Start development server
npm run build      # Build for production
npm run test       # Run tests
npm run lint       # Lint code
```

### Server (server/)

```bash
npm start          # Start Express server
npm run dev        # Start with nodemon for development
```

### Salesforce (sf/)

```bash
sf project deploy start                    # Deploy metadata
sf org assign permset -n "Duplicate_Management_Access"  # Assign permissions
sf apex run --file scripts/test.apex      # Run Apex tests
```

## Troubleshooting

### Common Issues

**Port conflicts:**

```bash
# Kill processes on default ports
./kill-ports.sh
```

**Dependencies not installing:**

```bash
# Clear caches and reinstall
rm -rf node_modules package-lock.json
npm install
```

**Salesforce authentication:**

```bash
# Re-authenticate with Salesforce
sf org login web
sf org list
```

**React app not starting:**

```bash
# Check if port 5173 is available
lsof -i :5173
# Or use different port
npm run dev -- --port 3000
```

### Logs

Monitor application logs:

```bash
# Server logs
tail -f server.log

# App logs
tail -f app.log

# Combined logs
tail -f server.log app.log
```

## Testing

### Generate Test Data

1. Open Salesforce org
2. Navigate to "Test Data Generator" Lightning component
3. Click "Generate Test Data" (creates ~20 customers with duplicates)
4. Click "Run Duplicate Scan" (finds potential matches)
5. View results in React app

### API Testing

Test the API endpoints directly:

```bash
# Get pending duplicates
curl http://localhost:3001/api/duplicates/pending

# Resolve a duplicate (replace {id} with actual ID)
curl -X POST http://localhost:3001/api/duplicates/{id}/resolve \
  -H "Content-Type: application/json" \
  -d '{"action": "merge"}'
```

## Next Steps

1. **Explore the Frontend**: Open http://localhost:5173 and interact with the duplicate management interface
2. **Generate Test Data**: Use the Salesforce Lightning component to create sample data
3. **Review Code**: Check out the well-documented services in the `sf/force-app/` directory
4. **Customize**: Modify matching rules, scoring algorithms, or UI components as needed
5. **Deploy**: Use the provided scripts to deploy to production environments

## Support

For questions or issues:

1. Check the individual README files in each directory
2. Review the comprehensive documentation in service classes
3. Look at test files for usage examples
4. Check Salesforce debug logs for backend issues
