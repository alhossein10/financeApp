# Firebase Setup Guide

This guide will help you set up Firebase for the Finance App with dual versions (Admin and User).

## Prerequisites

- A Google account
- Flutter development environment set up
- Firebase CLI installed (optional, for deploying security rules)

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: `finance-app` (or your preferred name)
4. Disable Google Analytics (optional)
5. Click **"Create project"**

## Step 2: Enable Firebase Services

### Enable Firebase Authentication

1. In Firebase Console, go to **Authentication**
2. Click **"Get started"**
3. Go to **"Sign-in method"** tab
4. Enable **"Email/Password"** provider
5. Click **"Save"**

### Enable Cloud Firestore

1. In Firebase Console, go to **Firestore Database**
2. Click **"Create database"**
3. Select **"Start in test mode"** (we'll deploy security rules later)
4. Choose a location (select closest to your users)
5. Click **"Enable"**

### ~~Enable Firebase Storage~~ (NOT REQUIRED - Using Firestore Only)

**Note:** This implementation uses **Firestore only** to stay within the free tier. Invoice images are stored as compressed base64 strings in Firestore documents instead of Firebase Storage. This approach:
- ✅ Completely free (within Firestore limits)
- ✅ No additional service setup required
- ✅ Simpler security rules
- ⚠️ Limited to smaller images (~500KB recommended)

If you need to store larger images in the future, you can upgrade to Firebase Storage (requires Blaze plan).

## Step 3: Register Android Apps

You need to register TWO Android apps (Admin and User versions).

### Register Admin Version

1. In Firebase Console, click **"Add app"** → Select **Android**
2. Enter package name: `com.app.finance.admin`
3. Enter app nickname: `Finance Admin`
4. Leave SHA-1 empty for now (add later for production)
5. Click **"Register app"**
6. Download `google-services.json`
7. **Rename it to `google-services-admin.json`**
8. Place it in: `android/app/src/admin/` (create the directory if needed)

### Register User Version

1. Click **"Add app"** → Select **Android** again
2. Enter package name: `com.app.finance.user`
3. Enter app nickname: `Finance User`
4. Leave SHA-1 empty for now
5. Click **"Register app"**
6. Download `google-services.json`
7. **Rename it to `google-services-user.json`**
8. Place it in: `android/app/src/user/` (create the directory if needed)

## Step 4: Register iOS Apps

You need to register TWO iOS apps (Admin and User versions).

### Register Admin Version

1. In Firebase Console, click **"Add app"** → Select **iOS**
2. Enter bundle ID: `com.app.finance.admin`
3. Enter app nickname: `Finance Admin`
4. Leave App Store ID empty
5. Click **"Register app"**
6. Download `GoogleService-Info.plist`
7. **Rename it to `GoogleService-Info-Admin.plist`**
8. Place it in: `ios/Runner/Firebase/Admin/` (create the directory if needed)

### Register User Version

1. Click **"Add app"** → Select **iOS** again
2. Enter bundle ID: `com.app.finance.user`
3. Enter app nickname: `Finance User`
4. Leave App Store ID empty
5. Click **"Register app"**
6. Download `GoogleService-Info.plist`
7. **Rename it to `GoogleService-Info-User.plist`**
8. Place it in: `ios/Runner/Firebase/User/` (create the directory if needed)

## Step 5: Deploy Security Rules

### Option A: Using Firebase Console (Manual)

#### Firestore Rules

1. Go to **Firestore Database** → **Rules** tab
2. Copy the contents of `firebase/firestore.rules`
3. Paste into the rules editor
4. Click **"Publish"**

#### Storage Rules

1. Go to **Storage** → **Rules** tab
2. Copy the contents of `firebase/storage.rules`
3. Paste into the rules editor
4. Click **"Publish"**

### Option B: Using Firebase CLI (Recommended)

1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Initialize Firebase in your project:
   ```bash
   firebase init
   ```
   - Select **Firestore** and **Storage**
   - Use existing project: select your `finance-app` project
   - Use `firebase/firestore.rules` for Firestore rules
   - Use `firebase/storage.rules` for Storage rules

4. Deploy rules:
   ```bash
   firebase deploy --only firestore:rules,storage:rules
   ```

## Step 6: Create Admin User

After setting up authentication, you'll need to manually create an admin user:

1. Go to **Authentication** → **Users** tab
2. Click **"Add user"**
3. Enter email and password for admin
4. Note the **User UID**
5. Go to **Firestore Database**
6. Create a document in the `users` collection:
   - Document ID: `{User UID from step 4}`
   - Fields:
     ```
     id: {User UID}
     username: "admin"
     email: "{admin email}"
     role: 1
     created_at: {current timestamp}
     ```

## Step 7: Update Flutter Dependencies

Run the following command to install Firebase packages:

```bash
flutter pub get
```

## Step 8: Configure Android Build

The Android configuration will be set up in Task 2.3 of the implementation plan.

## Step 9: Configure iOS Build

The iOS configuration will be set up in Task 2.4 of the implementation plan.

## Verification

To verify your Firebase setup:

1. Check that all services are enabled in Firebase Console
2. Verify security rules are deployed
3. Confirm both Android apps are registered
4. Confirm both iOS apps are registered
5. Verify admin user exists in Authentication

## Troubleshooting

### "Default FirebaseApp is not initialized"

- Make sure you've placed the config files in the correct directories
- Ensure `Firebase.initializeApp()` is called in `main.dart`

### "Permission denied" errors

- Check that security rules are deployed correctly
- Verify user authentication is working
- Check that user role is set correctly in Firestore

### Build errors on Android

- Ensure `google-services.json` files are in the correct flavor directories
- Check that package names match exactly

### Build errors on iOS

- Ensure `GoogleService-Info.plist` files are added to Xcode project
- Check that bundle identifiers match exactly
- Verify the files are included in the correct build schemes

## Next Steps

After completing this setup:

1. Proceed to **Task 2: Implement build flavor configuration system**
2. Test Firebase connectivity with a simple read/write operation
3. Verify authentication works for both admin and user versions

## Security Notes

- **Never commit** `google-services.json` or `GoogleService-Info.plist` files to public repositories
- Add these files to `.gitignore`:
  ```
  # Firebase config files
  android/app/google-services.json
  android/app/src/*/google-services*.json
  ios/Runner/GoogleService-Info.plist
  ios/Runner/Firebase/**/*.plist
  ```
- Use environment-specific Firebase projects for development, staging, and production
- Regularly review Firebase security rules
- Monitor Firebase usage and set up billing alerts

## Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
