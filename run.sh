#!/bin/bash
# ====================================================================
# EduTrack DBMS - One-Click Launcher Script
# ====================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

echo "=========================================================="
echo "🎓 Starting EduTrack DBMS University Management System..."
echo "=========================================================="

# Check if venv exists, create if not
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
    echo "⬇️ Installing dependencies..."
    ./venv/bin/pip install -r requirements.txt
fi

# Run the Flask Application
echo "🚀 Launching Web Server on http://127.0.0.1:5050"
./venv/bin/python app.py
