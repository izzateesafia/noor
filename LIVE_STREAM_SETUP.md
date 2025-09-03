# Live Stream Setup Guide

## Overview
The "Watch Live" button in the dashboard shows live streams from TikTok. If you're seeing "No live available", it means there are no active live streams configured in the system.

## How to Set Up Live Streams

### For Admins:

1. **Access Admin Panel**
   - Log in as an admin user
   - Tap the "Admin" button in the top-right corner of the dashboard

2. **Manage Live Streams**
   - Tap "Manage Live Streams" in the admin panel
   - Tap the "+" button to add a new live stream

3. **Create Live Stream**
   - **Title**: Enter a descriptive title (e.g., "Daily Quran Recitation")
   - **Description**: Add details about the live stream
   - **TikTok Live Link**: Paste the TikTok live stream URL
   - **Active Status**: Make sure "Active Live Stream" is toggled ON
   - Tap "Save Live Stream"

### Getting TikTok Live Link:

1. Start your TikTok live stream
2. Tap the "Share" button during the live stream
3. Select "Copy Link"
4. Paste the copied link in the form

### Testing the Setup:

1. **For Admins**: Use the orange "Test" button in the dashboard to create a sample live stream
2. **For All Users**: Pull down to refresh the dashboard, then tap "Watch Live"
3. The button should show "LIVE" indicator when an active stream is available

## Troubleshooting

### "No live available" Message:

**Possible Causes:**
1. No live streams exist in the database
2. No live streams have `isActive: true`
3. Firestore connection issues
4. Network connectivity problems

**Solutions:**
1. Check if live streams exist in the admin panel
2. Ensure at least one live stream is marked as active
3. Verify internet connection
4. Try refreshing the dashboard (pull down)

### Debug Information:

The app logs debug information to help troubleshoot:
- Check console logs for "LiveStreamState" and "CurrentLiveStream" messages
- Look for "Fetching current live stream from Firestore..." messages
- Verify "Query result: X documents found" shows the expected count

## Database Structure

Live streams are stored in Firestore with the following structure:
```json
{
  "title": "Live Stream Title",
  "description": "Live stream description",
  "tiktokLiveLink": "https://www.tiktok.com/@username/live/...",
  "isActive": true,
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

## Important Notes

- Only one live stream can be active at a time
- When a new live stream is created, all others are automatically deactivated
- Live streams are ordered by creation date (newest first)
- The system automatically fetches the most recent active live stream 