#!/bin/bash
cd "$(dirname "$0")"
echo "Checking for Python..."
if ! command -v python3 &> /dev/null; then
    echo ""
    echo "ERROR: Python 3 was not found on this computer."
    echo "Install it from https://python.org and try again."
    read -p "Press Enter to close..."
    exit 1
fi
python3 update_data.py
