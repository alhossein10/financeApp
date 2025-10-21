# PocketBase Migration Summary

## Overview

The dual-version-admin-sync spec has been updated to use **PocketBase** instead of Firebase. This change provides a completely free, self-hosted backend solution that can be developed locally and deployed to Render when ready.

## Key Changes

### 1. Backend Infrastructure
- **Before**: Firebase (Storage + Firestore + Auth)
- **After**: PocketBase (Files + Collections + Built-in Auth)

### 2. Storage Service
- **Before**: `FirebaseStorageService` using Firebase Storage
- **After**: `PocketBaseStorageService` using PocketBase file attachments
- Files are uploaded to `invoice_files` collection with file attachments
- File URLs are generated using `pb.getFileUrl(record, fileName)`

### 3. Sync Service
- **Before**: `CloudSyncService` with Firestore
- **After**: `CloudSyncService` with PocketBase collections
- Expenses synced to `expenses` collection
- Uses PocketBase REST API for CRUD operations

### 4. Data Model Changes
- **Before**: `invoiceCloudPath` (Firebase Storage path)
- **After**: `invoiceCloudFileId` (PocketBase file record ID)

### 5. Security Rules
- **Before**: Firebase Security Rules (JavaScript)
- **After**: PocketBase Collection Rules (filter expressions)
- Rules configured in PocketBase Admin UI
- Support for role-based access (admin vs user)

### 6. Dependencies
**Removed**:
- firebase_core
- firebase_storage
- firebase_auth
- cloud_firestore

**Added**:
- pocketbase: ^0.18.0
- http: ^1.1.0
- path_provider: ^2.1.1

**Kept**:
- connectivity_plus (for offline detection)
- image (for compression)
- encrypt (optional, for local encryption)

## PocketBase Collections

### 1. expenses
Fields:
- user_id (number)
- username (text)
- user_email (email)
- local_expense_id (number)
- description (text)
- price_usd (number)
- price_syp (number)
- price_try (number)
- invoice_status (number)
- invoice_file_id (relation to invoice_files)
- expense_date (date)
- created_at (date)
- synced_at (date)

Rules:
- Create: Users can create their own expenses
- Read: Users see only their expenses, admins see all
- Update/Delete: Disabled (immutable records)

### 2. invoice_files
Fields:
- user_id (number)
- expense_id (number)
- file (file attachment)

Rules:
- Create: Users can upload their own files
- Read: Users see only their files, admins see all
- Update/Delete: Disabled

### 3. users (built-in)
Additional field:
- role (select: "user" or "admin")

## Development Workflow

### Phase 1: Local Development
1. Run PocketBase locally: `./pocketbase serve`
2. Access admin UI: `http://127.0.0.1:8090/_/`
3. Configure collections and rules
4. Develop and test with local PocketBase

### Phase 2: Production Deployment (Later)
1. Deploy PocketBase to Render
2. Update Flutter app config with production URL
3. Test sync with production backend
4. Deploy admin and user apps

## Benefits of PocketBase

1. **Completely Free**: No credit card required, no usage limits
2. **Self-Hosted**: Full control over data and infrastructure
3. **Simple Setup**: Single binary, no complex configuration
4. **Built-in Features**: Auth, file storage, real-time subscriptions
5. **Local Development**: Easy to develop and test offline
6. **Easy Deployment**: Deploy to Render with simple Dockerfile

## Migration Path

Since Task 1 already set up PocketBase services, the implementation can proceed directly with:
- Task 2: Build flavor configuration (no backend needed)
- Task 3: Storage service implementation
- Task 4: Database schema updates
- Task 5: Sync service implementation
- And so on...

## Testing Strategy

1. **Local Testing**: Use local PocketBase instance
2. **Mock Testing**: Mock PocketBase client for unit tests
3. **Integration Testing**: Test with real local PocketBase
4. **Production Testing**: Deploy to Render when ready

## Next Steps

1. Review the updated design document
2. Review the updated tasks list
3. Start with Task 2 (Build Flavor Configuration)
4. Continue with remaining tasks sequentially
5. Deploy to Render when app is complete

---

**Note**: The deployment to Render can be done later when you have a credit card. For now, all development and testing can be done locally with PocketBase running on your machine.
