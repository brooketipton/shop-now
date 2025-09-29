# No-Authentication Setup Guide

This approach eliminates the need for user authentication by using a proxy server that handles Salesforce authentication automatically.

## 🚀 How It Works

```
React App → Proxy Server → Salesforce API
(No Auth)   (Handles Auth)   (Authenticated)
```

- **React App**: No authentication code needed
- **Proxy Server**: Handles Salesforce login using stored credentials
- **Automatic**: Users never see login screens

## 📋 Setup Steps

### 1. Update Connected App Settings

In Salesforce Setup → App Manager → Duplicate Management App:

- ✅ Enable **"Username-Password OAuth Flow"**
- ✅ Add your **IP ranges** to **"Permitted Users"** (or select "All users")

### 2. Get Salesforce Credentials

**Consumer Key & Secret:**

1. Setup → App Manager → Duplicate Management App → View
2. Copy **Consumer Key** and **Consumer Secret**

**Security Token:**

1. Setup → My Personal Information → Reset My Security Token
2. Check your email for the security token

### 3. Configure Server Environment

Create `server/.env`:

```env
SF_INSTANCE_URL=https://customer-nosoftware-7615-dev-ed.scratch.my.salesforce.com
SF_CLIENT_ID=your_consumer_key_here
SF_CLIENT_SECRET=your_consumer_secret_here
SF_USERNAME=your_salesforce_username
SF_PASSWORD=your_salesforce_password
SF_SECURITY_TOKEN=your_security_token
```

### 4. Start the Proxy Server

```bash
cd server
npm install
npm run dev
```

### 5. Update React App

Replace your current `src/App.tsx` with:

```bash
mv src/App.tsx src/App-oauth.tsx
mv src/App-no-auth.tsx src/App.tsx
```

Update `src/components/DuplicateTable.tsx` to use the proxy API:

```typescript
import { duplicateApi } from "../api-proxy";
```

### 6. Start React App

```bash
cd app
npm run dev
```

## 🎯 Benefits

✅ **No User Login**: Users never see authentication screens
✅ **Automatic**: Credentials configured once on server
✅ **Secure**: Client secrets stored safely on server
✅ **Simple**: React app has no authentication code
✅ **Production Ready**: Proper separation of concerns

## 🔒 Security Notes

- Server credentials should be stored securely (environment variables)
- Use HTTPS in production
- Consider IP restrictions in Salesforce
- Regular credential rotation recommended

## 🛠 Production Deployment

### Server (Backend):

- Deploy to Heroku, Vercel, AWS, etc.
- Set environment variables in hosting platform
- Enable HTTPS

### React App (Frontend):

- Update `api-proxy.ts` baseURL to your deployed server
- Deploy to Netlify, Vercel, etc.

## 🔄 Alternative: Environment-Based Switching

You can support both modes by checking environment variables:

```typescript
// src/api.ts
const useProxy = import.meta.env.VITE_USE_PROXY === "true";

export const duplicateApi = useProxy
	? require("./api-proxy").duplicateApi
	: require("./api-oauth").duplicateApi;
```

This lets you:

- **Development**: Use proxy (no auth)
- **Production**: Use OAuth (user auth)

## 🤝 Comparison

| Approach  | User Experience | Security | Complexity |
| --------- | --------------- | -------- | ---------- |
| **OAuth** | Login required  | High     | Medium     |
| **Proxy** | No login        | Medium   | Low        |

Choose based on your requirements:

- **Internal tools**: Use proxy (convenience)
- **External users**: Use OAuth (security)
