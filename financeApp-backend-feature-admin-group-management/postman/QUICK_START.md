# Postman Collection - Quick Start Guide

Get started testing the Finance Backend API in 5 minutes!

## Step 1: Import Collection (30 seconds)

1. Open Postman
2. Click **Import** button (top left)
3. Drag and drop `Finance-API.postman_collection.json`
4. Click **Import**

✅ You should see "Finance Backend API" collection in your sidebar

## Step 2: Start Laravel Server (1 minute)

```bash
# Navigate to project directory
cd finance_backend

# Start development server
php artisan serve
```

✅ Server should be running at `http://localhost:8000`

## Step 3: Register a User (30 seconds)

1. Expand **Finance Backend API** collection
2. Open **Authentication** folder
3. Click **Register** request
4. Click **Send** button

✅ You should get a 201 response with a token
✅ Token is automatically saved for future requests

## Step 4: Create Your First Expense (30 seconds)

1. Open **Expenses** folder
2. Click **Create Expense** request
3. Click **Send** button

✅ You should get a 201 response with expense data
✅ Expense ID is automatically saved

## Step 5: View Your Expenses (30 seconds)

1. Click **List Expenses** request
2. Click **Send** button

✅ You should see your created expense in the list

## 🎉 You're Ready!

You can now test all 50+ endpoints in the collection.

## Common Test Scenarios

### Test Complete Expense Flow

```
1. Authentication → Register (or Login)
2. Expenses → Create Expense
3. File Operations → Upload Invoice to Expense
4. Expenses → Get Expense (see invoice attached)
5. Expenses → Update Expense
6. Expenses → Delete Expense
```

### Test Admin Features

```
1. Login with admin credentials:
   - Email: admin@example.com
   - Password: password

2. Admin - Dashboard → Get Stats
3. Admin - Dashboard → Get User Activity
4. Admin - Fund Box → Get Fund Box
5. Admin - Audit Logs → List Audit Logs
```

### Test Data Sync

```
1. Data Sync → Batch Sync (create multiple records)
2. Data Sync → Get Changes (retrieve updates)
```

## Need Help?

- 📖 Full documentation: [README.md](./README.md)
- 🔗 API Reference: [API_ENDPOINTS_REFERENCE.md](../API_ENDPOINTS_REFERENCE.md)
- 🐛 Issues? Check [Troubleshooting section](./README.md#-troubleshooting)

## Pro Tips

💡 **Auto-save IDs**: Register and Create requests automatically save IDs for you

💡 **Query params**: Enable disabled query parameters to filter results

💡 **Environments**: Create separate environments for dev/staging/prod

💡 **Test scripts**: Check the Tests tab to see auto-save scripts

---

Happy Testing! 🚀
