# Firebase Setup Checklist

Use this checklist to track your Firebase setup progress.

## ☐ Step 1: Create Firebase Project

- [ ] Go to Firebase Console (https://console.firebase.google.com/)
- [ ] Create new project named "finance-app"
- [ ] Project created successfully

## ☐ Step 2: Enable Firebase Services

### Authentication
- [ ] Navigate to Authentication section
- [ ] Click "Get started"
- [ ] Enable Email/Password sign-in method
- [ ] Save changes

### Cloud Firestore
- [ ] Navigate to Firestore Database
- [ ] Click "Create database"
- [ ] Start in test mode (will deploy rules later)
- [ ] Select database location
- [ ] Database created successfully

### ~~Firebase Storage~~ (NOT REQUIRED)
- [x] **SKIP THIS** - Using Firestore only (free tier)
- [x] Images stored as base64 in Firestore documents
- [x] No Storage setup needed

## ☐ Step 3: Register Android Apps

### Admin Version
- [ ] Click "Add app" → Android
- [ ] Package name: `com.app.finance.admin`
- [ ] App nickname: "Finance Admin"
- [ ] Download `google-services.json`
- [ ] Rename to `google-services-admin.json`
- [ ] Place in `android/app/src/admin/`
- [ ] Verify file is in correct location

### User Version
- [ ] Click "Add app" → Android
- [ ] Package name: `com.app.finance.user`
- [ ] App nickname: "Finance User"
- [ ] Download `google-services.json`
- [ ] Rename to `google-services-user.json`
- [ ] Place in `android/app/src/user/`
- [ ] Verify file is in correct location

## ☐ Step 4: Register iOS Apps

### Admin Version
- [ ] Click "Add app" → iOS
- [ ] Bundle ID: `com.app.finance.admin`
- [ ] App nickname: "Finance Admin"
- [ ] Download `GoogleService-Info.plist`
- [ ] Rename to `GoogleService-Info-Admin.plist`
- [ ] Place in `ios/Runner/Firebase/Admin/`
- [ ] Verify file is in correct location

### User Version
- [ ] Click "Add app" → iOS
- [ ] Bundle ID: `com.app.finance.user`
- [ ] App nickname: "Finance User"
- [ ] Download `GoogleService-Info.plist`
- [ ] Rename to `GoogleService-Info-User.plist`
- [ ] Place in `ios/Runner/Firebase/User/`
- [ ] Verify file is in correct location

## ☐ Step 5: Deploy Security Rules

### Option A: Firebase Console
- [ ] Navigate to Firestore Database → Rules
- [ ] Copy contents from `firebase/firestore.rules`
- [ ] Paste and publish
- [ ] ~~Storage Rules~~ (NOT NEEDED - no Storage used)

### Option B: Firebase CLI (Recommended)
- [ ] Install Firebase CLI: `npm install -g firebase-tools`
- [ ] Login: `firebase login`
- [ ] Initialize: `firebase init` (select Firestore only)
- [ ] Deploy: `firebase deploy --only firestore:rules`

## ☐ Step 6: Create Admin User

- [ ] Navigate to Authentication → Users
- [ ] Click "Add user"
- [ ] Enter admin email and password
- [ ] Copy the User UID
- [ ] Navigate to Firestore Database
- [ ] Create document in `users` collection
- [ ] Document ID: {User UID}
- [ ] Add fields:
  - [ ] `id`: {User UID}
  - [ ] `username`: "admin"
  - [ ] `email`: {admin email}
  - [ ] `role`: 1
  - [ ] `created_at`: {current timestamp}
- [ ] Save document

## ☐ Step 7: Install Dependencies

- [ ] Run `flutter pub get`
- [ ] Verify all Firebase packages installed
- [ ] No dependency conflicts

## ☐ Step 8: Verify Setup

- [ ] All services enabled in Firebase Console
- [ ] Security rules deployed successfully
- [ ] Both Android apps registered
- [ ] Both iOS apps registered
- [ ] Admin user exists with role=1
- [ ] Configuration files in correct locations

## ☐ Step 9: Test Connection (After Task 2 Complete)

- [ ] Build admin flavor successfully
- [ ] Build user flavor successfully
- [ ] Firebase initializes without errors
- [ ] Can authenticate with admin user
- [ ] Can read/write to Firestore
- [ ] Can upload to Storage

## Notes

Record any issues or important information here:

```
Firebase Project ID: ___________________________

Admin User Email: ___________________________

Admin User UID: ___________________________

Database Location: ___________________________

Storage Bucket: ___________________________

Issues/Notes:
_____________________________________________
_____________________________________________
_____________________________________________
```

## Next Steps

After completing this checklist:

1. ✅ Mark Task 1 as complete
2. ➡️ Proceed to Task 2: Implement build flavor configuration system
3. 🧪 Test Firebase connectivity after Task 2 is complete

## Troubleshooting

If you encounter issues, refer to:
- `FIREBASE_SETUP_GUIDE.md` for detailed instructions
- `firebase/README.md` for security rules information
- Firebase Console error logs
- Flutter console output
