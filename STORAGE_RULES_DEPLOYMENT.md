# Storage Rules Deployment Guide

## Summary of Changes

The Storage rules have been updated with improved documentation for the `isAdmin()` function. The function correctly checks:
1. User is authenticated
2. User document exists in Firestore
3. `roles` field exists and is a list
4. `'admin'` string is in the roles array

## Deployment Steps

### 1. Deploy Storage Rules

Run the following command to deploy the updated Storage rules:

```bash
firebase deploy --only storage
```

Or deploy both Firestore and Storage rules together:

```bash
firebase deploy --only firestore:rules,storage
```

### 2. Verify User Document Structure

Before testing, ensure your admin user's document in Firestore has the correct structure:

**Path:** `users/{userId}`

**Required fields:**
```json
{
  "roles": ["admin"],  // Must be an array of strings, containing "admin"
  "name": "...",
  "email": "...",
  // ... other fields
}
```

**Important:** The `roles` field must be:
- An array (not a single string)
- Contains the string `"admin"` (lowercase)
- Example: `["admin"]` or `["admin", "student"]`

### 3. Verify Rules Deployment

After deployment, verify in Firebase Console:
1. Go to Firebase Console → Storage → Rules
2. Check that the rules match your local `storage.rules` file
3. Look for any deployment errors

### 4. Test Admin Upload

Test image upload as an admin user:
1. Log in as a user with `roles: ["admin"]` in Firestore
2. Try uploading an image (hadith, news, dua, etc.)
3. Check for any error messages

## Troubleshooting

### Error: "You are not authorized to upload images"

**Possible causes:**
1. **Rules not deployed:** Run `firebase deploy --only storage`
2. **User document missing:** Ensure user document exists at `users/{userId}` in Firestore
3. **Roles field incorrect:** Check that `roles` is an array containing `"admin"` string
4. **User not authenticated:** Ensure user is logged in

### Verify User Document

Check in Firebase Console → Firestore Database:
- Document path: `users/{your-user-id}`
- Field: `roles` should be an array like `["admin"]`

### Check Rule Evaluation

In Firebase Console → Storage → Rules:
- Click "Rules Playground" to test rule evaluation
- Test with your user's UID and verify `isAdmin()` returns true

## Current Configuration

- **Storage Rules File:** `storage.rules`
- **Firebase Project:** `uwais-manage`
- **Storage Bucket:** `uwais-manage.appspot.com`
- **Rules Version:** v2

## Next Steps

After deployment:
1. Test image uploads for all admin features (hadith, news, dua, classes, videos, ads)
2. Verify non-admin users cannot upload (should get proper error)
3. Check Firebase Console logs for any rule evaluation errors

