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

# Check for Android Google Services
if [ -f "android/app/google-services.json" ]; then
    echo "✓ android/app/google-services.json exists"
else
    echo "✗ android/app/google-services.json NOT FOUND"
    echo "  → Download from Firebase Console (optional)"
fi

# Check for iOS Google Services
if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo "✓ ios/Runner/GoogleService-Info.plist exists"
else
    echo "✗ ios/Runner/GoogleService-Info.plist NOT FOUND"
    echo "  → Download from Firebase Console (optional)"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Next Steps"
echo "════════════════════════════════════════════════════════"
echo ""
echo "1. Create .env file: cp .env.example .env"
echo "2. Get Google OAuth credentials:"
echo "   → Visit: https://console.cloud.google.com/"
echo "3. Set up remote agent server and get API credentials"
echo "4. Fill in all values in .env file"
echo "5. Review CONFIGURATION.md for detailed instructions"
echo ""
echo "Run this script again to verify your configuration!"
echo ""
