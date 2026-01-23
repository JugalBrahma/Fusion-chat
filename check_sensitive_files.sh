#!/bin/bash

echo "Checking for potentially sensitive files that should be gitignored..."
echo ""

# Check for Firebase files
echo "🔍 Firebase files:"
find . -name "firebase-*.json" -o -name "google-services.json" -o -name "GoogleService-Info.plist" 2>/dev/null

# Check for API key files
echo ""
echo "🔍 API key files:"
find . -name "*api_key*" -o -name "*secret*" -o -name "*credential*" 2>/dev/null

# Check for env files
echo ""
echo "🔍 Environment files:"
find . -name ".env*" -not -name ".env.example" 2>/dev/null

# Check for key files
echo ""
echo "🔍 Key files:"
find . -name "*.key" -o -name "*.pem" -o -name "*.p12" 2>/dev/null

echo ""
echo "✅ Check complete!"
echo "If any files are listed above, run:"
echo "git rm --cached <filename>"
echo "to remove them from git tracking"
