# ShopNow Development Startup Guide

This guide explains how to start both the Express server and React app for development.

## Quick Start

### Option 1: Using npm scripts (Recommended)

```bash
# For Mac/Linux
npm run dev

# For Windows
npm run dev:windows
```

### Option 2: Direct script execution

```bash
# Mac/Linux
./start-dev.sh

# Windows
start-dev.bat
```

### Option 3: Manual startup (individual services)

```bash
# Start server only
npm run start:server

# Start React app only (in another terminal)
npm start
```

## What the scripts do

1. **Dependency Check**: Verifies Node.js and npm are installed
2. **Auto-install**: Installs dependencies if `node_modules` folders are missing
3. **Server Startup**: Starts the Express server on `http://localhost:3001`
4. **React App Startup**: Starts the React development server on `http://localhost:5173`
5. **Log Management**: Creates log files and shows live output
6. **Graceful Shutdown**: Properly stops both services when you press Ctrl+C

## Services

- **Express Server**: `http://localhost:3001`

  - Handles Salesforce API proxy requests
  - Manages OAuth authentication
  - Serves duplicate management APIs

- **React App**: `http://localhost:5173`
  - Main frontend application
  - Duplicate management interface
  - Hot reload enabled for development

## Log Files

When using the shell script, logs are written to:

- `server.log` - Express server logs
- `app.log` - React app logs

You can monitor them separately:

```bash
# Watch server logs
tail -f server.log

# Watch app logs
tail -f app.log
```

## Troubleshooting

### Port conflicts

If ports 3001 or 5173 are in use:

- Server port can be changed in `server/server.js`
- React app port can be changed in `app/vite.config.ts`

### Dependencies issues

```bash
# Clean install all dependencies
rm -rf app/node_modules server/node_modules
npm run setup:dev
```

### Permission issues (Mac/Linux)

```bash
# Make script executable
chmod +x start-dev.sh
```

## Development Workflow

1. Run `npm run dev` to start both services
2. Open `http://localhost:5173` in your browser
3. Make changes to your code (hot reload is enabled)
4. Use the test data generator LWC to create sample data
5. Test duplicate detection and management features
6. Press Ctrl+C to stop all services when done

## First Time Setup

If this is your first time running the project:

```bash
# Install all dependencies and setup OAuth
npm run setup:dev

# Then start development
npm run dev
```
