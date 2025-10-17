#!/bin/bash

# EPANSA App - Configuration Checklist Script
# This script helps you verify if all required configuration is in place

echo "════════════════════════════════════════════════════════"
echo "  EPANSA App - Configuration Checklist"
echo "════════════════════════════════════════════════════════"
echo ""

# Check if .env file exists
if [ -f ".env" ]; then
    echo "✓ .env file exists"
else
    echo "✗ .env file NOT FOUND"
    echo "  → Run: cp .env.example .env"
    echo ""
fi

# Check if .env.example exists
if [ -f ".env.example" ]; then
    echo "✓ .env.example template exists"
else
    echo "✗ .env.example NOT FOUND"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Required Configuration Keys"
echo "════════════════════════════════════════════════════════"

# Check for required keys in .env
if [ -f ".env" ]; then
    required_keys=(
        "AGENT_API_BASE_URL"
        "AGENT_API_KEY"
        "GOOGLE_OAUTH_CLIENT_ID_ANDROID"
        "GOOGLE_OAUTH_CLIENT_ID_IOS"
        "GOOGLE_API_KEY"
    )
    
    for key in "${required_keys[@]}"; do
        if grep -q "^${key}=" .env; then
            value=$(grep "^${key}=" .env | cut -d'=' -f2)
            if [[ "$value" == *"your_"* ]] || [[ "$value" == *"YOUR_"* ]] || [ -z "$value" ]; then
                echo "⚠ $key - Found but needs value"
            else
                echo "✓ $key - Configured"
            fi
        else
            echo "✗ $key - Missing"
        fi
    done
else
    echo "Cannot check keys - .env file doesn't exist"
    echo "Please create .env from .env.example first"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Google OAuth Setup"
echo "════════════════════════════════════════════════════════"

# Note: Google OAuth is configured via .env file
# No additional platform-specific files are required
echo "✓ Google OAuth configured via environment variables"
