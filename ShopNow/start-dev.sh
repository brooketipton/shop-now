#!/bin/bash

# ShopNow Development Startup Script
# This script starts both the Express server and React app concurrently

echo "🚀 Starting ShopNow Development Environment..."
echo "================================================"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Node.js is installed
if ! command_exists node; then
    echo -e "${RED}❌ Node.js is not installed. Please install Node.js first.${NC}"
    exit 1
fi

# Check if npm is installed
if ! command_exists npm; then
    echo -e "${RED}❌ npm is not installed. Please install npm first.${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Node.js version: $(node --version)${NC}"
echo -e "${BLUE}📋 npm version: $(npm --version)${NC}"
echo ""

# Function to install dependencies if node_modules doesn't exist
install_deps_if_needed() {
    local dir=$1
    local name=$2
    
    if [ ! -d "$dir/node_modules" ]; then
        echo -e "${YELLOW}📦 Installing $name dependencies...${NC}"
        cd "$dir"
        npm install
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Failed to install $name dependencies${NC}"
            exit 1
        fi
        cd - > /dev/null
        echo -e "${GREEN}✅ $name dependencies installed${NC}"
    else
        echo -e "${GREEN}✅ $name dependencies already installed${NC}"
    fi
}

# Install dependencies if needed
install_deps_if_needed "server" "Server"
install_deps_if_needed "app" "React App"

echo ""
echo -e "${YELLOW}🔧 Starting services...${NC}"

# Function to cleanup background processes on script exit
cleanup() {
    echo ""
    echo -e "${YELLOW}🛑 Shutting down services...${NC}"
    if [ ! -z "$SERVER_PID" ]; then
        kill $SERVER_PID 2>/dev/null
        echo -e "${GREEN}✅ Server stopped${NC}"
    fi
    if [ ! -z "$APP_PID" ]; then
        kill $APP_PID 2>/dev/null
        echo -e "${GREEN}✅ React app stopped${NC}"
    fi
    exit 0
}

# Set up trap to cleanup on script exit
trap cleanup SIGINT SIGTERM EXIT

# Start the Express server in the background
echo -e "${BLUE}🖥️  Starting Express server...${NC}"
cd server
npm start > ../server.log 2>&1 &
SERVER_PID=$!
cd ..

# Wait a moment for server to start
sleep 2

# Check if server started successfully
if ! kill -0 $SERVER_PID 2>/dev/null; then
    echo -e "${RED}❌ Failed to start Express server. Check server.log for details.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Express server started (PID: $SERVER_PID)${NC}"

# Start the React app in the background
echo -e "${BLUE}⚛️  Starting React app...${NC}"
cd app
npm run dev > ../app.log 2>&1 &
APP_PID=$!
cd ..

# Wait a moment for app to start
sleep 3

# Check if React app started successfully
if ! kill -0 $APP_PID 2>/dev/null; then
    echo -e "${RED}❌ Failed to start React app. Check app.log for details.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ React app started (PID: $APP_PID)${NC}"
echo ""
echo -e "${GREEN}🎉 Development environment is ready!${NC}"
echo "================================================"
echo -e "${BLUE}📱 React App:${NC}     http://localhost:5173"
echo -e "${BLUE}🖥️  Express Server:${NC} http://localhost:3001"
echo ""
echo -e "${YELLOW}📝 Logs:${NC}"
echo "   Server logs: tail -f server.log"
echo "   App logs:    tail -f app.log"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}"

# Keep script running and show live logs
echo ""
echo -e "${BLUE}📊 Live logs (press Ctrl+C to stop):${NC}"
echo "================================================"

# Show combined logs from both services
tail -f server.log app.log 2>/dev/null &
TAIL_PID=$!

# Wait for user to press Ctrl+C
wait $TAIL_PID 2>/dev/null
