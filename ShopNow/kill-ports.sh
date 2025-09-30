#!/bin/bash

# Kill processes using common development ports
# This script helps clean up stuck processes

# Check for force flag
FORCE=false
if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
    FORCE=true
fi

echo "🔍 Checking for processes using development ports..."

# Common ports used by the app
PORTS=(3001 5173 3000 8080)

for PORT in "${PORTS[@]}"; do
    echo ""
    echo "Checking port $PORT..."
    
    # Find processes using the port
    PIDS=$(lsof -ti :$PORT 2>/dev/null)
    
    if [ -z "$PIDS" ]; then
        echo "✅ Port $PORT is free"
    else
        echo "⚠️  Port $PORT is in use by process(es): $PIDS"
        
        # Show what's using the port
        echo "Process details:"
        lsof -i :$PORT
        
        # Ask user if they want to kill the process
        if [ "$FORCE" = true ]; then
            echo "🔥 Force killing processes on port $PORT..."
            REPLY="y"
        else
            read -p "Kill process(es) using port $PORT? (y/N): " -n 1 -r
            echo
        fi
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for PID in $PIDS; do
                echo "Killing process $PID..."
                kill $PID 2>/dev/null
                
                # Wait a moment and check if it's really dead
                sleep 1
                if kill -0 $PID 2>/dev/null; then
                    echo "Process $PID didn't die gracefully, force killing..."
                    kill -9 $PID 2>/dev/null
                fi
            done
            
            # Verify the port is now free
            sleep 1
            NEW_PIDS=$(lsof -ti :$PORT 2>/dev/null)
            if [ -z "$NEW_PIDS" ]; then
                echo "✅ Port $PORT is now free"
            else
                echo "❌ Port $PORT is still in use"
            fi
        else
            echo "Skipping port $PORT"
        fi
    fi
done

echo ""
echo "🎉 Port cleanup complete!"
echo ""
echo "You can now run:"
echo "  npm run dev        # Start both services"
echo "  npm run start:server  # Start server only"
echo "  npm start          # Start React app only"
