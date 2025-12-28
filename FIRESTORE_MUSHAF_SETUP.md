# Firestore Mushaf Setup Guide

## Overview

This guide explains how to store PDF mushaf URLs from Firebase Storage in Firestore, so they can be fetched by the app using the MushafCubit and MushafRepository.

## Firestore Collection Structure

Create a collection named `mushafs` in Firestore with the following document structure:

### Document Structure

Each document in the `mushafs` collection should have these fields:

```json
{
  "name": "Mushaf Madinah (Old)",
  "nameArabic": "مصحف المدينة القديم",
  "description": "Hafs narration - Old version",
  "riwayah": "Hafs",
  "pdfUrl": "https://firebasestorage.googleapis.com/v0/b/YOUR_PROJECT.appspot.com/o/mushafs%2Fmadinah_old.pdf?alt=media&token=YOUR_TOKEN",
  "totalPages": 604,
  "thumbnailUrl": "https://...", // Optional
  "isPremium": false
}
```

### Field Descriptions

- **name** (String, required): English name of the mushaf
- **nameArabic** (String, required): Arabic name of the mushaf
- **description** (String, required): Description of the mushaf
- **riwayah** (String, required): Recitation method (Hafs, Warsh, Qaloon, Douri, Shubah)
- **pdfUrl** (String, required): Full download URL from Firebase Storage
- **totalPages** (Number, required): Total number of pages in the PDF
- **thumbnailUrl** (String, optional): URL to thumbnail image
- **isPremium** (Boolean, optional): Whether this mushaf requires premium access (default: false)

## Getting PDF URLs from Firebase Storage

### Method 1: From Firebase Console

1. Go to Firebase Console → Storage
2. Navigate to your PDF file (e.g., `mushafs/madinah_old.pdf`)
3. Click on the file
4. Copy the "Download URL" - this is your `pdfUrl`

### Method 2: Using Firebase Storage SDK

The URL format is:
```
https://firebasestorage.googleapis.com/v0/b/YOUR_PROJECT_ID.appspot.com/o/mushafs%2FFILENAME.pdf?alt=media&token=TOKEN
```

## Example Firestore Documents

### Document 1: Madinah Old (Hafs)

**Document ID**: `hafs_medina_old` (or auto-generated)

```json
{
  "name": "Mushaf Madinah (Old)",
  "nameArabic": "مصحف المدينة القديم",
  "description": "Hafs narration - Old version - King Fahd Complex",
  "riwayah": "Hafs",
  "pdfUrl": "https://firebasestorage.googleapis.com/v0/b/YOUR_PROJECT.appspot.com/o/mushafs%2Fmadinah_old.pdf?alt=media&token=YOUR_TOKEN",
  "totalPages": 604,
  "isPremium": false
}
```

### Document 2: Warsh

**Document ID**: `warsh` (or auto-generated)

```json
{
  "name": "Mushaf Warsh",
  "nameArabic": "مصحف ورش",
  "description": "Warsh narration from Nafi - King Fahd Complex",
  "riwayah": "Warsh",
  "pdfUrl": "https://firebasestorage.googleapis.com/v0/b/YOUR_PROJECT.appspot.com/o/mushafs%2Fwarsh.pdf?alt=media&token=YOUR_TOKEN",
  "totalPages": 576,
  "isPremium": false
}
```

## Steps to Add Documents in Firestore

1. **Open Firebase Console** → Firestore Database
2. **Create Collection** (if it doesn't exist):
   - Click "Start collection"
   - Collection ID: `mushafs`
   - Click "Next"

3. **Add First Document**:
   - Document ID: `hafs_medina_old` (or leave empty for auto-generated)
   - Add fields as shown in the example above
   - Click "Save"

4. **Add Second Document**:
   - Document ID: `warsh` (or leave empty for auto-generated)
   - Add fields as shown in the example above
   - Click "Save"

5. **Add More Mushafs** (optional):
   - Repeat for other mushafs (Qaloon, Douri, Shubah, etc.)

## Firestore Security Rules

Add these rules to allow read access (and admin write access):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Mushafs collection - readable by all, writable by admins only
    match /mushafs/{mushafId} {
      allow read: if true; // Anyone can read mushafs
      allow write: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.roles != null &&
                     'admin' in get(/databases/$(database)/documents/users/$(request.auth.uid)).data.roles;
    }
  }
}
```

## How It Works in the App

1. **MushafRepository** fetches all documents from `mushafs` collection
2. **MushafCubit** manages the state (loading, loaded, error)
3. **MushafSelectionPage** displays mushafs from Firestore
4. **PDFMushafViewerPage** downloads PDF from the `pdfUrl` field

## Testing

After adding documents to Firestore:

1. Open the app
2. Navigate to Menu → "Mushaf PDF"
3. You should see the mushafs you added
4. Tap on a mushaf to download and view the PDF

## Troubleshooting

**Mushafs not appearing:**
- Check Firestore collection name is exactly `mushafs`
- Verify all required fields are present
- Check Firestore security rules allow read access
- Check app logs for errors

**PDF not downloading:**
- Verify `pdfUrl` is a valid Firebase Storage download URL
- Check Firebase Storage security rules allow read access
- Ensure PDF file exists in Storage at the specified path

**Error loading mushafs:**
- Check internet connection
- Verify Firestore indexes are created (if using orderBy)
- Check app logs for specific error messages

