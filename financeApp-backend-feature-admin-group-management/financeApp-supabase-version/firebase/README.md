# Firebase Security Rules

This directory contains Firebase security rules for the Finance App.

## Files

- **firestore.rules**: Security rules for Cloud Firestore database (includes image storage as base64)
- **storage.rules**: NOT USED - Kept for reference if upgrading to Firebase Storage in future

## Important: Free Tier Implementation

This implementation uses **Firestore only** (no Firebase Storage) to stay within the free tier:
- ✅ Invoice images stored as compressed base64 strings in Firestore documents
- ✅ Completely free within Firestore limits
- ✅ Simpler setup and security rules
- ⚠️ Recommended for images under 500KB (compressed)

## Deploying Rules

### Using Firebase Console (Manual)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. For Firestore rules:
   - Navigate to Firestore Database → Rules
   - Copy contents of `firestore.rules`
   - Paste and publish
4. ~~Storage rules~~ - NOT NEEDED (no Storage used)

### Using Firebase CLI (Recommended)

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize (first time only)
firebase init
# Select: Firestore only (NOT Storage)

# Deploy rules
firebase deploy --only firestore:rules
```

## Security Rules Overview

### Firestore Rules

The Firestore rules implement:

- **User authentication**: All operations require authentication
- **Role-based access**: Admin users (role=1) have elevated permissions
- **Data isolation**: Users can only access their own data
- **Admin oversight**: Admins can read all user-submitted expenses
- **Immutable records**: Expenses cannot be updated or deleted (audit trail)
- **Image size validation**: Base64 images limited to ~1MB (prevents abuse)

### ~~Storage Rules~~ (NOT USED)

Firebase Storage is not used in this implementation. Images are stored as base64 strings in Firestore documents to stay within the free tier.

## Testing Rules

You can test security rules locally using the Firebase Emulator Suite:

```bash
# Install emulators
firebase init emulators

# Start emulators
firebase emulators:start

# Run tests (if you have test files)
firebase emulators:exec "npm test"
```

## Important Notes

- Always test rules in a development environment before deploying to production
- Review rules regularly for security vulnerabilities
- Monitor Firebase Console for unauthorized access attempts
- Keep rules in sync with application logic
- Document any rule changes in version control

## Rule Structure

### Firestore Collections

- `/users/{userId}`: User profile data
- `/expenses/{expenseId}`: Expense records with sync metadata AND base64 images
- `/sync_metadata/{userId}`: Sync status tracking

### ~~Storage Paths~~ (NOT USED)

Firebase Storage is not used. Images are stored within Firestore documents as base64 strings.

## Troubleshooting

### "Permission denied" errors

1. Check that user is authenticated
2. Verify user role is set correctly in Firestore
3. Ensure document IDs match expected format
4. Check that required fields are present in write operations

### Rules not updating

1. Wait a few minutes for rules to propagate
2. Clear browser cache
3. Restart the app
4. Verify rules were deployed successfully

## Resources

- [Firebase Security Rules Documentation](https://firebase.google.com/docs/rules)
- [Firestore Security Rules Guide](https://firebase.google.com/docs/firestore/security/get-started)
- [Storage Security Rules Guide](https://firebase.google.com/docs/storage/security)
