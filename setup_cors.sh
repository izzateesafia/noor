#!/bin/bash

# Firebase Storage CORS Setup Script
# This script configures CORS for Firebase Storage to enable image loading on Flutter Web

set -e

echo "🔧 Firebase Storage CORS Setup"
echo "================================"
echo ""

# Check if gsutil is available
if ! command -v gsutil &> /dev/null; then
    echo "❌ gsutil not found. Adding Google Cloud SDK to PATH..."
    export PATH="/opt/homebrew/share/google-cloud-sdk/bin:$PATH"
    
    if ! command -v gsutil &> /dev/null; then
        echo "❌ Error: gsutil is still not available."
        echo "Please install Google Cloud SDK first:"
        echo "  brew install --cask google-cloud-sdk"
        exit 1
    fi
fi

echo "✅ gsutil found"
echo ""

# Set project
PROJECT_ID="uwais-manage"
# Try to detect the correct bucket name
BUCKET_NAME="${PROJECT_ID}.firebasestorage.app"
# Fallback to old naming convention if needed
if ! gsutil ls gs://${BUCKET_NAME} &>/dev/null; then
    BUCKET_NAME="${PROJECT_ID}.appspot.com"
fi

echo "📋 Project: $PROJECT_ID"
echo "📦 Bucket: $BUCKET_NAME"
echo ""

# Check if authenticated
echo "🔐 Checking authentication..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "⚠️  Not authenticated. Please authenticate:"
    echo "   gcloud auth login"
    echo ""
    echo "Or if you prefer Firebase CLI:"
    echo "   firebase login"
    exit 1
fi

echo "✅ Authenticated"
echo ""

# Set project
echo "⚙️  Setting project..."
gcloud config set project $PROJECT_ID
echo "✅ Project set to $PROJECT_ID"
echo ""

# Check if cors.json exists
if [ ! -f "cors.json" ]; then
    echo "❌ Error: cors.json not found in current directory"
    exit 1
fi

echo "📄 CORS configuration file found: cors.json"
echo ""

# Apply CORS
echo "🚀 Applying CORS configuration..."
if gsutil cors set cors.json gs://$BUCKET_NAME; then
    echo ""
    echo "✅ CORS configuration applied successfully!"
    echo ""
    
    # Verify
    echo "🔍 Verifying CORS configuration..."
    echo ""
    gsutil cors get gs://$BUCKET_NAME
    echo ""
    echo "✅ CORS setup complete!"
    echo ""
    echo "📝 Next steps:"
    echo "   1. Test your Flutter web app"
    echo "   2. Check browser console for CORS errors (should be none)"
    echo "   3. Verify images load correctly"
else
    echo ""
    echo "❌ Failed to apply CORS configuration"
    echo ""
    echo "💡 Troubleshooting:"
    echo "   - Ensure you have Storage Admin permissions"
    echo "   - Check that the bucket name is correct: $BUCKET_NAME"
    echo "   - Try: gsutil ls to list available buckets"
    exit 1
fi

