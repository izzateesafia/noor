# Quick Start: Adding Mushafs to Firestore

## Step-by-Step Guide

### 1. Get PDF URLs from Firebase Storage

For each PDF you uploaded (`madinah_old.pdf` and `warsh.pdf`):

1. Open **Firebase Console** → **Storage**
2. Navigate to `mushafs/` folder
3. Click on `madinah_old.pdf`
4. Copy the **"Download URL"** (looks like: `https://firebasestorage.googleapis.com/v0/b/...`)
5. Repeat for `warsh.pdf`

### 2. Create Firestore Documents

1. Open **Firebase Console** → **Firestore Database**
2. Click **"Start collection"** (if `mushafs` doesn't exist)
3. Collection ID: `mushafs`
4. Click **"Next"**

#### Document 1: Madinah Old

- **Document ID**: `hafs_medina_old` (or leave empty for auto-generated)
- **Fields**:
  ```
  name: "Mushaf Madinah (Old)"
  nameArabic: "مصحف المدينة القديم"
  description: "Hafs narration - Old version - King Fahd Complex"
  riwayah: "Hafs"
  pdfUrl: [PASTE THE DOWNLOAD URL FROM STEP 1]
  totalPages: 604
  isPremium: false
  ```
- Click **"Save"**

#### Document 2: Warsh

- **Document ID**: `warsh` (or leave empty for auto-generated)
- **Fields**:
  ```
  name: "Mushaf Warsh"
  nameArabic: "مصحف ورش"
  description: "Warsh narration from Nafi - King Fahd Complex"
  riwayah: "Warsh"
  pdfUrl: [PASTE THE DOWNLOAD URL FROM STEP 1]
  totalPages: 576
  isPremium: false
  ```
- Click **"Save"**

### 3. Create Firestore Index (if needed)

If you see an error about missing index:

1. Click the error link in the console
2. Click **"Create Index"**
3. Wait for index to build (usually takes a few minutes)

### 4. Test in App

1. Open the app
2. Navigate to **Menu** → **"Mushaf PDF"**
3. You should see your mushafs listed
4. Tap on one to download and view

## Field Types in Firestore

- `name`: **string**
- `nameArabic`: **string**
- `description`: **string**
- `riwayah`: **string**
- `pdfUrl`: **string**
- `totalPages`: **number**
- `isPremium`: **boolean**
- `thumbnailUrl`: **string** (optional, can be left empty)

## Troubleshooting

**"Missing index" error:**
- Click the error link to create the index automatically
- Or manually create in Firestore → Indexes tab

**PDFs not showing:**
- Check collection name is exactly `mushafs`
- Verify all required fields are present
- Check `pdfUrl` is a valid download URL (starts with `https://firebasestorage.googleapis.com`)

**PDF download fails:**
- Verify Storage rules allow read access (see `storage.rules`)
- Check PDF file exists in Storage at `mushafs/{filename}.pdf`
- Ensure `pdfUrl` includes the full token parameter

