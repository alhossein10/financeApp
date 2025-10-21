# Task 4: Database Schema Update for Synchronization Support

## Summary

Successfully updated the database schema to support synchronization features and user roles. This includes adding sync-related columns to the expenses table, a role column to the users table, and creating indexes for efficient sync queries.

## Changes Made

### 1. Database Version Update
- Incremented database version from 5 to 6
- Added migration script for version 6 in `lib/data/db.dart`

### 2. Expenses Table Updates (Sub-task 4.1)

Added the following columns to the `expenses` table:
- `invoice_cloud_file_id TEXT` - Stores PocketBase file record ID
- `sync_status INTEGER NOT NULL DEFAULT 0` - Tracks sync status (0=pending, 1=syncing, 2=synced, 3=failed)
- `synced_at INTEGER` - Timestamp when expense was synced
- `sync_retry_count INTEGER NOT NULL DEFAULT 0` - Number of sync retry attempts
- `sync_error_message TEXT` - Error message if sync fails

### 3. Users Table Updates (Sub-task 4.2)

Added the following column to the `users` table:
- `role INTEGER NOT NULL DEFAULT 0` - User role (0=user, 1=admin)

### 4. Database Indexes (Sub-task 4.3)

Created the following indexes for efficient sync queries:
- `idx_expenses_sync_status` - Index on `expenses(sync_status)`
- `idx_expenses_synced_at` - Index on `expenses(synced_at)`
- `idx_expenses_user_id_sync_status` - Composite index on `expenses(user_id, sync_status)`

### 5. Domain Layer Updates

#### User Entity (`lib/features/auth/domain/entities/user.dart`)
- Added `UserRole` enum with `user` and `admin` values
- Added `role` field to User entity with default value `UserRole.user`
- Added `isAdmin` getter method
- Updated `props` list to include role

#### User Model (`lib/features/auth/data/models/user_model.dart`)
- Added `role` parameter to constructor
- Updated `fromMap` to deserialize role from database
- Updated `toMap` to serialize role to database
- Updated `fromEntity` to include role
- Updated `copyWith` to support role updates

#### Expense Entity (`lib/features/expenses/domain/entities/expense.dart`)
- Added `SyncStatus` enum with values: `pending`, `syncing`, `synced`, `failed`
- Added sync-related fields:
  - `invoiceCloudFileId`
  - `syncStatus` (default: `SyncStatus.pending`)
  - `syncedAt`
  - `syncRetryCount` (default: 0)
  - `syncErrorMessage`
- Updated `props` list to include all new fields

#### Expense Model (`lib/features/expenses/data/models/expense_model.dart`)
- Added sync-related parameters to constructor
- Updated `fromMap` to deserialize sync fields from database
- Updated `toMap` to serialize sync fields to database
- Updated `fromEntity` to include sync fields
- Updated `copyWith` to support sync field updates

#### Expense Record (`lib/models/expense.dart`)
- Added `SyncStatus` enum (for backward compatibility)
- Added sync-related fields matching the Expense entity
- Updated `copyWith`, `toMap`, and `fromMap` methods

## Migration Strategy

The migration is handled automatically when the app starts:
1. Database version check detects upgrade from version 5 to 6
2. Migration script adds new columns to existing tables
3. Default values are applied to existing records:
   - All existing expenses get `sync_status = 0` (pending)
   - All existing users get `role = 0` (user)
4. Indexes are created for performance optimization

## Testing

All files passed diagnostic checks with no errors:
- ✅ `lib/data/db.dart`
- ✅ `lib/features/auth/domain/entities/user.dart`
- ✅ `lib/features/auth/data/models/user_model.dart`
- ✅ `lib/features/expenses/domain/entities/expense.dart`
- ✅ `lib/features/expenses/data/models/expense_model.dart`
- ✅ `lib/models/expense.dart`

## Next Steps

With the database schema updated, the next tasks can proceed:
- Task 5: Implement synchronization service with PocketBase
- Task 6: Update Expense domain layer with sync fields (partially complete)
- Task 7: Integrate sync service into expense creation flow

## Requirements Addressed

- ✅ Requirement 7.1: Hybrid Local-Cloud Data Architecture
- ✅ Requirement 7.2: Sync status tracking
- ✅ Requirement 8.1: User Identity and Attribution (role field)
- ✅ Requirement 9.1: Synchronization Status and Monitoring
- ✅ Requirement 10.1: Security and Access Control (role-based)
- ✅ Requirement 10.2: Admin-level authentication
- ✅ Requirement 12.1: Data Migration
- ✅ Requirement 12.2: Backward Compatibility
