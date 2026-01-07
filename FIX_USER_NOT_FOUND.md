# Fix: "User Not Found" Error When Adding Friends

## Problem
When trying to add a friend using their 5-digit User ID, you get a "User not found" error even though the user exists.

## Root Causes
1. **Missing PublicId Mapping**: The `publicIds` node in Firebase might not have the mapping from publicId to userId
2. **Whitespace in Input**: Users might accidentally add spaces before/after the ID
3. **Database Inconsistency**: Old users might not have their publicId properly indexed

## Fixes Applied

### 1. Input Trimming (add_friend_popup.dart)
- Added `.trim()` to remove any leading/trailing whitespace from the entered ID
- Added validation message if ID is not exactly 5 digits

### 2. Enhanced Logging (chat_service.dart)
- Added detailed debug logs to track the lookup process:
  - 🔍 Shows the ID being looked up
  - 📊 Shows if the mapping exists and what value it contains
  - ✅ Shows the found user ID
  - ❌ Shows clear error messages

### 3. Improved Debug Tools (debug_screen.dart)
- Added a text field to check ANY user ID
- Can now search for specific IDs to verify they exist in the database
- Shows detailed information about the user and their mapping

## How to Fix the Issue

### Step 1: Run the Debug Tool
1. Open the app
2. Go to **Settings** tab
3. Tap on **Debug Tools**
4. Tap **"Fix All PublicId Mappings"** button
5. Wait for the process to complete
6. Check the output to see how many mappings were fixed

### Step 2: Verify Specific IDs
1. In the Debug Tools screen
2. Enter the 5-digit ID you're trying to add
3. Tap **"Check"** button
4. The tool will:
   - Check if the mapping exists
   - If not, search for the user in the database
   - Automatically create the mapping if the user is found

### Step 3: Test Adding Friend
1. Go back to the Friends tab
2. Tap the **+** button
3. Enter the 5-digit ID (make sure no spaces!)
4. Tap **Add**

## Monitoring
Check the console logs when adding a friend. You should see:
```
🔍 Looking up publicId: "12345"
📊 Snapshot exists: true, value: abc123xyz, type: String
✅ Found targetUid: abc123xyz
```

If you see:
```
❌ User not found in publicIds for: 12345
```

Then the mapping doesn't exist and needs to be created using the Debug Tools.

## Prevention
The app now automatically ensures publicId mappings exist when users:
- Sign up
- Sign in with email
- Sign in with Google

This should prevent the issue from happening for new users.

## Technical Details

### Database Structure
```
Firebase Realtime Database
├── users/
│   └── {userId}/
│       ├── publicId: "12345"
│       ├── name: "User Name"
│       └── email: "user@example.com"
└── publicIds/
    └── "12345": "{userId}"
```

The `publicIds` node is an index that maps the 5-digit public ID to the internal Firebase user ID. This allows quick lookups when adding friends.

### Why This Happens
- Old users might have been created before the publicId indexing was implemented
- Database operations might have failed partially (user created but mapping not created)
- Manual database edits might have removed mappings

### The Fix
The `_ensurePublicIdMapping()` method in `auth_service.dart` now:
1. Checks if the user profile exists
2. Checks if they have a publicId
3. Checks if the mapping exists in the `publicIds` node
4. Creates the mapping if it's missing
5. Creates a new publicId if the user doesn't have one

This runs automatically on every login, ensuring consistency.
