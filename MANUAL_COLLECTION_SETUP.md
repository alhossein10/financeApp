# Manual PocketBase Collection Setup

Since the JSON import is failing, let's create the collections manually. This is actually simpler and more reliable!

## Step 1: Create Expenses Collection

1. In PocketBase Admin UI, click **"New collection"**
2. Fill in the details:
   - **Name**: `expenses`
   - **Type**: Base collection
3. Click **"Create"**

### Add Fields to Expenses Collection

Click on the `expenses` collection, then go to the **"Fields"** tab. Add these fields one by one:

#### Field 1: user_id
- **Type**: Number
- **Name**: `user_id`
- **Required**: ✅ Yes
- **Min**: 1
- Click **"Save"**

#### Field 2: username
- **Type**: Plain text
- **Name**: `username`
- **Required**: ✅ Yes
- **Min length**: 1
- **Max length**: 255
- Click **"Save"**

#### Field 3: user_email
- **Type**: Email
- **Name**: `user_email`
- **Required**: ✅ Yes
- Click **"Save"**

#### Field 4: local_expense_id
- **Type**: Number
- **Name**: `local_expense_id`
- **Required**: ✅ Yes
- **Min**: 1
- Click **"Save"**

#### Field 5: description
- **Type**: Plain text
- **Name**: `description`
- **Required**: ✅ Yes
- **Min length**: 1
- **Max length**: 1000
- Click **"Save"**

#### Field 6: price_usd
- **Type**: Number
- **Name**: `price_usd`
- **Required**: ❌ No
- **Min**: 0
- Click **"Save"**

#### Field 7: price_syp
- **Type**: Number
- **Name**: `price_syp`
- **Required**: ❌ No
- **Min**: 0
- Click **"Save"**

#### Field 8: price_try
- **Type**: Number
- **Name**: `price_try`
- **Required**: ❌ No
- **Min**: 0
- Click **"Save"**

#### Field 9: invoice_status
- **Type**: Number
- **Name**: `invoice_status`
- **Required**: ✅ Yes
- **Min**: 0
- **Max**: 10
- Click **"Save"**

#### Field 10: invoice_file_id
- **Type**: Plain text
- **Name**: `invoice_file_id`
- **Required**: ❌ No
- **Max length**: 255
- Click **"Save"**

#### Field 11: expense_date
- **Type**: Date
- **Name**: `expense_date`
- **Required**: ✅ Yes
- Click **"Save"**

#### Field 12: synced_at
- **Type**: Date
- **Name**: `synced_at`
- **Required**: ✅ Yes
- Click **"Save"**

### Set API Rules for Expenses (DO THIS AFTER ALL FIELDS ARE CREATED!)

⚠️ **IMPORTANT**: Only set these rules AFTER you've created all 12 fields above!

Go to the **"API Rules"** tab and set these rules:

**List/Search Rule**:
```javascript
@request.auth.id != "" && (@request.auth.role = "admin" || user_id = @request.auth.id)
```

**View Rule**:
```javascript
@request.auth.id != "" && (@request.auth.role = "admin" || user_id = @request.auth.id)
```

**Create Rule**:
```javascript
@request.auth.id != "" && @request.data.user_id = @request.auth.id
```

**Update Rule**: Leave empty (no updates allowed)

**Delete Rule**: Leave empty (no deletes allowed)

Click **"Save changes"**

---

## Step 2: Create Invoice Files Collection

1. Click **"New collection"** again
2. Fill in the details:
   - **Name**: `invoice_files`
   - **Type**: Base collection
3. Click **"Create"**

### Add Fields to Invoice Files Collection

#### Field 1: user_id
- **Type**: Number
- **Name**: `user_id`
- **Required**: ✅ Yes
- **Min**: 1
- Click **"Save"**

#### Field 2: expense_id
- **Type**: Number
- **Name**: `expense_id`
- **Required**: ✅ Yes
- **Min**: 1
- Click **"Save"**

#### Field 3: file
- **Type**: File
- **Name**: `file`
- **Required**: ✅ Yes
- **Max Select**: 1
- **Max Size**: 10485760 (10MB)
- **Mime Types**: 
  - `image/jpeg`
  - `image/png`
  - `image/jpg`
  - `image/heic`
  - `image/webp`
- Click **"Save"**

### Set API Rules for Invoice Files

Go to the **"API Rules"** tab:

**List/Search Rule**:
```javascript
@request.auth.id != "" && (@request.auth.role = "admin" || user_id = @request.auth.id)
```

**View Rule**:
```javascript
@request.auth.id != "" && (@request.auth.role = "admin" || user_id = @request.auth.id)
```

**Create Rule**:
```javascript
@request.auth.id != "" && @request.data.user_id = @request.auth.id
```

**Update Rule**: Leave empty

**Delete Rule**:
```javascript
@request.auth.id != "" && @request.auth.role = "admin"
```

Click **"Save changes"**

---

## Step 3: Verify Collections

You should now see in the Collections list:
- ✅ `expenses` (12 fields)
- ✅ `invoice_files` (3 fields)
- ✅ `users` (auto-created by PocketBase)

---

## Step 4: Test API

Open Command Prompt and test:

```cmd
curl http://localhost:8090/api/health
```

Should return: `{"code":200,"message":"API is healthy"}`

---

## Step 5: Update App Configuration

Edit `lib/core/config/pocketbase_config.dart`:

```dart
class PocketBaseConfig {
  // Replace with your computer's IP address
  static const String baseUrl = 'http://192.168.1.100:8090'; // YOUR IP HERE
  
  static const String apiUrl = '$baseUrl/api';
  
  // Collection names
  static const String usersCollection = 'users';
  static const String expensesCollection = 'expenses';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
```

Find your IP with: `ipconfig` (look for IPv4 Address)

---

## Step 6: Rebuild and Test App

```bash
flutter clean
flutter pub get
flutter run --flavor admin -t lib/main_admin.dart
```

### Test in App:
1. Register a new user
2. Create an expense with invoice image
3. Check PocketBase Admin UI → Collections → expenses
4. Should see the expense record
5. Check invoice_files collection for the image

---

## Troubleshooting

### Can't create collection?
- Make sure you're logged in as PocketBase admin
- Refresh the browser page

### Field won't save?
- Check all required settings are filled
- Make sure field name has no spaces
- Use lowercase and underscores only

### API Rules won't save?
- Check syntax carefully (copy-paste from above)
- Make sure there are no extra spaces
- Click "Save changes" button

### App can't connect?
- Verify PocketBase is running
- Check IP address in config matches your computer's IP
- Make sure firewall allows port 8090
- Test from phone browser: `http://YOUR_IP:8090/api/health`

---

## Quick Reference

**Collection Names**:
- `expenses` - Stores expense records
- `invoice_files` - Stores invoice images

**Field Types**:
- Number - For IDs and prices
- Plain text - For names and descriptions
- Email - For email addresses
- Date - For dates and timestamps
- File - For images

**API Rules**:
- Users can only see their own data
- Admins can see all data
- No updates or deletes allowed (immutable records)

---

## You're Done!

Once both collections are created with all fields and rules:
- ✅ PocketBase is ready
- ✅ App can sync data
- ✅ Images can be uploaded
- ✅ Ready for testing

Continue with app configuration and testing!
