@echo off
setlocal EnableDelayedExpansion

REM ShopNow Development Startup Script for Windows
REM This script starts both the Express server and React app concurrently

echo 🚀 Starting ShopNow Development Environment...
echo ================================================

REM Check if Node.js is installed
node --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Node.js is not installed. Please install Node.js first.
    pause
    exit /b 1
)

REM Check if npm is installed
npm --version >nul 2>&1
if errorlevel 1 (
    echo ❌ npm is not installed. Please install npm first.
    pause
    exit /b 1
)

echo 📋 Node.js version:
node --version
echo 📋 npm version:
npm --version
echo.

REM Function to install dependencies if node_modules doesn't exist
if not exist "server\node_modules" (
    echo 📦 Installing Server dependencies...
    cd server
    call npm install
    if errorlevel 1 (
        echo ❌ Failed to install Server dependencies
        pause
        exit /b 1
    )
    cd ..
    echo ✅ Server dependencies installed
) else (
    echo ✅ Server dependencies already installed
)

if not exist "app\node_modules" (
    echo 📦 Installing React App dependencies...
    cd app
    call npm install
    if errorlevel 1 (
        echo ❌ Failed to install React App dependencies
        pause
        exit /b 1
    )
    cd ..
    echo ✅ React App dependencies installed
) else (
    echo ✅ React App dependencies already installed
)

echo.
echo 🔧 Starting services...

REM Start the Express server
echo 🖥️  Starting Express server...
cd server
start "Express Server" cmd /k "npm start"
cd ..

REM Wait a moment for server to start
timeout /t 3 /nobreak >nul

echo ✅ Express server started

REM Start the React app
echo ⚛️  Starting React app...
cd app
start "React App" cmd /k "npm run dev"
cd ..

REM Wait a moment for app to start
timeout /t 3 /nobreak >nul

echo ✅ React app started
echo.
echo 🎉 Development environment is ready!
echo ================================================
echo 📱 React App:     http://localhost:5173
echo 🖥️  Express Server: http://localhost:3001
echo.
echo 📝 Both services are running in separate command windows.
echo    Close those windows to stop the services.
echo.
echo Press any key to exit this script (services will continue running)...
pause >nul
