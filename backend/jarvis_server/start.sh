#!/bin/bash
# Quick start script for J.A.R.V.I.S Server (Linux/macOS)

echo "========================================"
echo "J.A.R.V.I.S Server Quick Start"
echo "========================================"
echo ""

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
    echo ""
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate
echo ""

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "WARNING: .env file not found!"
    echo "Please copy .env.example to .env and add your OpenAI API key"
    echo ""
    exit 1
fi

# Start server
echo "Starting J.A.R.V.I.S Server..."
echo "Server will be available at http://localhost:8000"
echo "API docs at http://localhost:8000/docs"
echo ""
python main.py
