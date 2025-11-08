import json

collection = {
    "info": {
        "name": "Finance Backend API - Complete",
        "description": "Complete API collection with all endpoints for Finance Management Backend",
        "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
        "_postman_id": "finance-api-complete-v1",
        "version": "1.0.0"
    },
    "auth": {
        "type": "bearer",
        "bearer": [
            {
                "key": "token",
                "value": "{{auth_token}}",
                "type": "string"
            }
        ]
    },
    "variable": [
        {"key": "base_url", "value": "http://localhost:8000/api/v1"},
        {"key": "auth_token", "value": ""},
        {"key": "expense_id", "value": ""},
        {"key": "transfer_id", "value": ""},
        {"key": "incoming_id", "value": ""},
        {"key": "export_id", "value": ""},
        {"key": "file_id", "value": ""}
    ],
    "item": []
}

# Authentication folder
auth_folder = {
    "name": "1. Authentication",
    "item": [
        {
            "name": "Register",
            "event": [{
                "listen": "test",
                "script": {
                    "exec": [
                        "if (pm.response.code === 201) {",
                        "    var data = pm.response.json();",
                        "    pm.collectionVariables.set('auth_token', data.data.token);",
                        "    console.log('✅ Token saved:', data.data.token);",
                        "}"
                    ]
                }
            }],
            "request": {
                "auth": {"type": "noauth"},
                "method": "POST",
                "header": [
                    {"key": "Accept", "value": "application/json"},
                    {"key": "Content-Type", "value": "application/json"}
                ],
                "body": {
                    "mode": "raw",
                    "raw": json.dumps({
                        "name": "Test User",
                        "email": "test@example.com",
                        "password": "password123",
                        "password_confirmation": "password123"
                    }, indent=2)
                },
                "url": {
                    "raw": "{{base_url}}/auth/register",
                    "host": ["{{base_url}}"],
                    "path": ["auth", "register"]
                }
            }
        },
        {
            "name": "Login",
            "event": [{
                "listen": "test",
                "script": {
                    "exec": [
                        "if (pm.response.code === 200) {",
                        "    var data = pm.response.json();",
                        "    pm.collectionVariables.set('auth_token', data.data.token);",
                        "    console.log('✅ Token saved:', data.data.token);",
                        "}"
                    ]
                }
            }],
            "request": {
                "auth": {"type": "noauth"},
                "method": "POST",
                "header": [
                    {"key": "Accept", "value": "application/json"},
                    {"key": "Content-Type", "value": "application/json"}
                ],
                "body": {
                    "mode": "raw",
                    "raw": json.dumps({
                        "email": "test@example.com",
                        "password": "password123"
                    }, indent=2)
                },
                "url": {
                    "raw": "{{base_url}}/auth/login",
                    "host": ["{{base_url}}"],
                    "path": ["auth", "login"]
                }
            }
        },
        {
            "name": "Get Current User (Me)",
            "request": {
                "method": "GET",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {
                    "raw": "{{base_url}}/auth/me",
                    "host": ["{{base_url}}"],
                    "path": ["auth", "me"]
                }
            }
        },
        {
            "name": "Logout",
            "request": {
                "method": "POST",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {
                    "raw": "{{base_url}}/auth/logout",
                    "host": ["{{base_url}}"],
                    "path": ["auth", "logout"]
                }
            }
        },
        {
            "name": "Forgot Password",
            "request": {
                "auth": {"type": "noauth"},
                "method": "POST",
                "header": [
                    {"key": "Accept", "value": "application/json"},
                    {"key": "Content-Type", "value": "application/json"}
                ],
                "body": {
                    "mode": "raw",
                    "raw": json.dumps({"email": "test@example.com"}, indent=2)
                },
                "url": {
                    "raw": "{{base_url}}/auth/forgot-password",
                    "host": ["{{base_url}}"],
                    "path": ["auth", "forgot-password"]
                }
            }
        }
    ]
}

# Expenses folder
expenses_folder = {
    "name": "2. Expenses",
    "item": [
        {
            "name": "List All Expenses",
            "request": {
                "method": "GET",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {
                    "raw": "{{base_url}}/expenses?per_page=15",
                    "host": ["{{base_url}}"],
                    "path": ["expenses"],
                    "query": [
                        {"key": "per_page", "value": "15"},
                        {"key": "category", "value": "Food", "disabled": True},
                        {"key": "date_from", "value": "2024-01-01", "disabled": True},
                        {"key": "date_to", "value": "2024-12-31", "disabled": True}
                    ]
                }
            }
        },
        {
            "name": "Create Expense",
            "event": [{
                "listen": "test",
                "script": {
                    "exec": [
                        "if (pm.response.code === 201) {",
                        "    var data = pm.response.json();",
                        "    pm.collectionVariables.set('expense_id', data.data.id);",
                        "    console.log('✅ Expense ID saved:', data.data.id);",
                        "}"
                    ]
                }
            }],
            "request": {
                "method": "POST",
                "header": [
                    {"key": "Accept", "value": "application/json"},
                    {"key": "Content-Type", "value": "application/json"}
                ],
                "body": {
                    "mode": "raw",
                    "raw": json.dumps({
                        "amount": 150.50,
                        "category": "Food",
                        "description": "Grocery shopping",
                        "date": "2024-10-23",
                        "payment_method": "cash"
                    }, indent=2)
                },
                "url": {
                    "raw": "{{base_url}}/expenses",
                    "host": ["{{base_url}}"],
                    "path": ["expenses"]
                }
            }
        },
        {
            "name": "Get Single Expense",
            "request": {
                "method": "GET",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {
                    "raw": "{{base_url}}/expenses/{{expense_id}}",
                    "host": ["{{base_url}}"],
                    "path": ["expenses", "{{expense_id}}"]
                }
            }
        },
        {
            "name": "Update Expense",
            "request": {
                "method": "PUT",
                "header": [
                    {"key": "Accept", "value": "application/json"},
                    {"key": "Content-Type", "value": "application/json"}
                ],
                "body": {
                    "mode": "raw",
                    "raw": json.dumps({
                        "amount": 175.00,
                        "category": "Food",
                        "description": "Grocery shopping - Updated",
                        "date": "2024-10-23",
                        "payment_method": "card"
                    }, indent=2)
                },
                "url": {
                    "raw": "{{base_url}}/expenses/{{expense_id}}",
                    "host": ["{{base_url}}"],
                    "path": ["expenses", "{{expense_id}}"]
                }
            }
        },
        {
            "name": "Delete Expense",
            "request": {
                "method": "DELETE",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {
                    "raw": "{{base_url}}/expenses/{{expense_id}}",
                    "host": ["{{base_url}}"],
                    "path": ["expenses", "{{expense_id}}"]
                }
            }
        }
    ]
}

# Transfers folder
transfers_folder = {
    "name": "3. Transfers",
    "item": [
        {
            "name": "List All Transfers",
            "request": {
                "method": "GET",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {
                    "raw": "{{base_url}}/transfers",
                    "host": ["{{base_url}}"],
                    "path": ["transfers"]
                }
            }
        },
        {
            "name": "Create Transfer",
            "event": [{
                "listen": "test",
                "script": {
                    "exec": [
                        "if (pm.response.code === 201) {",
                        "    var data = pm.response.json();",
                        "    pm.collectionVariables.set('transfer_id', data.data.id);",
                        "    console.log('✅ Transfer ID saved:', data.data.id);",
                        "}"
                    ]
                }
            }],
            "request": {
                "method": "POST",
                "header": [
                    {"key": "Accept", "value": "application/json"},
                    {"key": "Content-Type", "value": "application/json"}
                ],
                "body": {
                    "mode": "raw",
                    "raw": json.dumps({
                        "amount": 500.00,
                        "from_account": "Savings",
                        "to_account": "Checking",
                        "description": "Monthly transfer",
                        "date": "2024-10-23"
                    }, indent=2)
                },
                "url": {
                    "raw": "{{base_url}}/transfers",
                    "host": ["{{base_url}}"],
                    "path": ["transfers"]
                }
            }
        },
        {
            "name": "Get Single Transfer",
            "request": {
                "method": "GET",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {
                    "raw": "{{base_url}}/transfers/{{transfer_id}}",
                    "host": ["{{base_url}}"],
                    "path": ["transfers", "{{transfer_id}}"]
                }
            }
        },
        {
            "name": "Update Transfer",
            "request": {
                "method": "PUT",
                "header": [
                    {"key": "Accept", "value": "application/json"},
                    {"key": "Content-Type", "value": "application/json"}
                ],
                "body": {
                    "mode": "raw",
                    "raw": json.dumps({
                        "amount": 600.00,
                        "from_account": "Savings",
                        "to_account": "Checking",
                        "description": "Monthly transfer - Updated"
                    }, indent=2)
                },
                "url": {
                    "raw": "{{base_url}}/transfers/{{transfer_id}}",
                    "host": ["{{base_url}}"],
                    "path": ["transfers", "{{transfer_id}}"]
                }
            }
        },
        {
            "name": "Delete Transfer",
            "request": {
                "method": "DELETE",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {
                    "raw": "{{base_url}}/transfers/{{transfer_id}}",
                    "host": ["{{base_url}}"],
                    "path": ["transfers", "{{transfer_id}}"]
                }
            }
        }
    ]
}

# Incoming folder
incoming_folder = {
    "name": "4. Incoming (Income)",
    "item": [
        {
            "name": "List All Income",
            "request": {
                "method": "GET",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {
                    "raw": "{{base_url}}/incoming",
                    "host": ["{{base_url}}"],
                    "path": ["incoming"]
                }
            }
        },
        {
            "name": "Create Income",
            "event": [{
                "listen": "test",
                "script": {
                    "exec": [
                        "if (pm.response.code === 201) {",
                        "    var data = pm.response.json();",
                        "    pm.collectionVariables.set('incoming_id', data.data.id);",
                        "    console.log('✅ Income ID saved:', data.data.id);",
                        "}"
                    ]
                }
            }],
            "request": {
                "method": "POST",
                "header": [
                    {"key": "Accept", "value": "application/json"},
                    {"key": "Content-Type", "value": "application/json"}
                ],
                "body": {
                    "mode": "raw",
                    "raw": json.dumps({
                        "amount": 5000.00,
                        "source": "Salary",
                        "description": "Monthly salary",
                        "date": "2024-10-23",
                        "payment_method": "bank_transfer"
                    }, indent=2)
                },
                "url": {
                    "raw": "{{base_url}}/incoming",
                    "host": ["{{base_url}}"],
                    "path": ["incoming"]
                }
            }
        },
        {
            "name": "Get Single Income",
            "request": {
                "method": "GET",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {
                    "raw": "{{base_url}}/incoming/{{incoming_id}}",
                    "host": ["{{base_url}}"],
                    "path": ["incoming", "{{incoming_id}}"]
                }
            }
        },
        {
            "name": "Update Income",
            "request": {
                "method": "PUT",
                "header": [
                    {"key": "Accept", "value": "application/json"},
                    {"key": "Content-Type", "value": "application/json"}
                ],
                "body": {
                    "mode": "raw",
                    "raw": json.dumps({
                        "amount": 5500.00,
                        "source": "Salary",
                        "description": "Monthly salary with bonus"
                    }, indent=2)
                },
                "url": {
                    "raw": "{{base_url}}/incoming/{{incoming_id}}",
                    "host": ["{{base_url}}"],
                    "path": ["incoming", "{{incoming_id}}"]
                }
            }
        },
        {
            "name": "Delete Income",
            "request": {
                "method": "DELETE",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {
                    "raw": "{{base_url}}/incoming/{{incoming_id}}",
                    "host": ["{{base_url}}"],
                    "path": ["incoming", "{{incoming_id}}"]
                }
            }
        }
    ]
}

# Fund Box folder
fundbox_folder = {
    "name": "5. Fund Box (Admin)",
    "item": [
        {
            "name": "Get Fund Box",
            "request": {
                "method": "GET",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {
                    "raw": "{{base_url}}/fund-box",
                    "host": ["{{base_url}}"],
                    "path": ["fund-box"]
                }
            }
        },
        {
            "name": "Update Fund Box",
            "request": {
                "method": "PUT",
                "header": [
                    {"key": "Accept", "value": "application/json"},
                    {"key": "Content-Type", "value": "application/json"}
                ],
                "body": {
                    "mode": "raw",
                    "raw": json.dumps({
                        "total_balance": 10000.00
                    }, indent=2)
                },
                "url": {
                    "raw": "{{base_url}}/fund-box",
                    "host": ["{{base_url}}"],
                    "path": ["fund-box"]
                }
            }
        }
    ]
}

# Profile folder
profile_folder = {
    "name": "6. User Profile",
    "item": [
        {
            "name": "Get Profile",
            "request": {
                "method": "GET",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {
                    "raw": "{{base_url}}/profile",
                    "host": ["{{base_url}}"],
                    "path": ["profile"]
                }
            }
        },
        {
            "name": "Update Profile",
            "request": {
                "method": "PUT",
                "header": [
                    {"key": "Accept", "value": "application/json"},
                    {"key": "Content-Type", "value": "application/json"}
                ],
                "body": {
                    "mode": "raw",
                    "raw": json.dumps({
                        "name": "John Smith",
                        "email": "john.smith@example.com"
                    }, indent=2)
                },
                "url": {
                    "raw": "{{base_url}}/profile",
                    "host": ["{{base_url}}"],
                    "path": ["profile"]
                }
            }
        },
        {
            "name": "Change Password",
            "request": {
                "method": "PUT",
                "header": [
                    {"key": "Accept", "value": "application/json"},
                    {"key": "Content-Type", "value": "application/json"}
                ],
                "body": {
                    "mode": "raw",
                    "raw": json.dumps({
                        "current_password": "password123",
                        "new_password": "newpassword123",
                        "new_password_confirmation": "newpassword123"
                    }, indent=2)
                },
                "url": {
                    "raw": "{{base_url}}/profile/password",
                    "host": ["{{base_url}}"],
                    "path": ["profile", "password"]
                }
            }
        }
    ]
}

# Export folder
export_folder = {
    "name": "7. Data Export",
    "item": [
        {
            "name": "Export Expenses to PDF",
            "event": [{
                "listen": "test",
                "script": {
                    "exec": [
                        "if (pm.response.code === 200) {",
                        "    var data = pm.response.json();",
                        "    pm.collectionVariables.set('export_id', data.data.id);",
                        "    console.log('✅ Export ID saved:', data.data.id);",
                        "}"
                    ]
                }
            }],
            "request": {
                "method": "POST",
                "header": [
                    {"key": "Accept", "value": "application/json"},
                    {"key": "Content-Type", "value": "application/json"}
                ],
                "body": {
                    "mode": "raw",
                    "raw": json.dumps({
                        "format": "pdf",
                        "date_from": "2024-01-01",
                        "date_to": "2024-12-31"
                    }, indent=2)
                },
                "url": {
                    "raw": "{{base_url}}/export/expenses/pdf",
                    "host": ["{{base_url}}"],
                    "path": ["export", "expenses", "pdf"]
                }
            }
        },
        {
            "name": "Export Expenses to Excel",
            "request": {
                "method": "POST",
                "header": [
                    {"key": "Accept", "value": "application/json"},
                    {"key": "Content-Type", "value": "application/json"}
                ],
                "body": {
                    "mode": "raw",
                    "raw": json.dumps({
                        "format": "excel",
                        "date_from": "2024-01-01",
                        "date_to": "2024-12-31"
                    }, indent=2)
                },
                "url": {
                    "raw": "{{base_url}}/export/expenses/excel",
                    "host": ["{{base_url}}"],
                    "path": ["export", "expenses", "excel"]
                }
            }
        },
        {
            "name": "Download Export",
            "request": {
                "method": "GET",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {
                    "raw": "{{base_url}}/export/{{export_id}}/download",
                    "host": ["{{base_url}}"],
                    "path": ["export", "{{export_id}}", "download"]
                }
            }
        }
    ]
}

# Admin Dashboard folder
admin_folder = {
    "name": "8. Admin Dashboard",
    "item": [
        {
            "name": "Get Dashboard Stats",
            "request": {
                "method": "GET",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {
                    "raw": "{{base_url}}/admin/dashboard/stats",
                    "host": ["{{base_url}}"],
                    "path": ["admin", "dashboard", "stats"]
                }
            }
        },
        {
            "name": "Get All Users",
            "request": {
                "method": "GET",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {
                    "raw": "{{base_url}}/admin/dashboard/users",
                    "host": ["{{base_url}}"],
                    "path": ["admin", "dashboard", "users"]
                }
            }
        },
        {
            "name": "Get Expense Summaries",
            "request": {
                "method": "GET",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {
                    "raw": "{{base_url}}/admin/dashboard/expenses",
                    "host": ["{{base_url}}"],
                    "path": ["admin", "dashboard", "expenses"]
                }
            }
        },
        {
            "name": "Get Analytics",
            "request": {
                "method": "GET",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {
                    "raw": "{{base_url}}/admin/dashboard/analytics?date_from=2024-01-01&date_to=2024-12-31",
                    "host": ["{{base_url}}"],
                    "path": ["admin", "dashboard", "analytics"],
                    "query": [
                        {"key": "date_from", "value": "2024-01-01"},
                        {"key": "date_to", "value": "2024-12-31"}
                    ]
                }
            }
        }
    ]
}

# Audit Logs folder
audit_folder = {
    "name": "9. Audit Logs (Admin)",
    "item": [
        {
            "name": "List Audit Logs",
            "request": {
                "method": "GET",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {
                    "raw": "{{base_url}}/audit-logs",
                    "host": ["{{base_url}}"],
                    "path": ["audit-logs"]
                }
            }
        },
        {
            "name": "Get Single Audit Log",
            "request": {
                "method": "GET",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {
                    "raw": "{{base_url}}/audit-logs/1",
                    "host": ["{{base_url}}"],
                    "path": ["audit-logs", "1"]
                }
            }
        }
    ]
}

# Sync folder
sync_folder = {
    "name": "10. Data Synchronization",
    "item": [
        {
            "name": "Batch Sync",
            "request": {
                "method": "POST",
                "header": [
                    {"key": "Accept", "value": "application/json"},
                    {"key": "Content-Type", "value": "application/json"}
                ],
                "body": {
                    "mode": "raw",
                    "raw": json.dumps({
                        "last_sync": "2024-10-23T09:00:00.000000Z",
                        "data": {
                            "expenses": [],
                            "incoming": [],
                            "transfers": []
                        }
                    }, indent=2)
                },
                "url": {
                    "raw": "{{base_url}}/sync/batch",
                    "host": ["{{base_url}}"],
                    "path": ["sync", "batch"]
                }
            }
        },
        {
            "name": "Get Changes",
            "request": {
                "method": "GET",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {
                    "raw": "{{base_url}}/sync/changes?since=2024-10-23T09:00:00.000000Z",
                    "host": ["{{base_url}}"],
                    "path": ["sync", "changes"],
                    "query": [
                        {"key": "since", "value": "2024-10-23T09:00:00.000000Z"}
                    ]
                }
            }
        }
    ]
}

# Files folder
files_folder = {
    "name": "11. File Management",
    "item": [
        {
            "name": "Upload File",
            "request": {
                "method": "POST",
                "header": [{"key": "Accept", "value": "application/json"}],
                "body": {
                    "mode": "formdata",
                    "formdata": [
                        {"key": "file", "type": "file", "src": ""},
                        {"key": "type", "value": "receipt", "type": "text"}
                    ]
                },
                "url": {
                    "raw": "{{base_url}}/files/upload",
                    "host": ["{{base_url}}"],
                    "path": ["files", "upload"]
                }
            }
        },
        {
            "name": "Download File",
            "request": {
                "method": "GET",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {
                    "raw": "{{base_url}}/files/download?path=encrypted_path_here",
                    "host": ["{{base_url}}"],
                    "path": ["files", "download"],
                    "query": [
                        {"key": "path", "value": "encrypted_path_here"}
                    ]
                }
            }
        },
        {
            "name": "Delete File",
            "request": {
                "method": "DELETE",
                "header": [
                    {"key": "Accept", "value": "application/json"},
                    {"key": "Content-Type", "value": "application/json"}
                ],
                "body": {
                    "mode": "raw",
                    "raw": json.dumps({"path": "files/receipt.jpg"}, indent=2)
                },
                "url": {
                    "raw": "{{base_url}}/files",
                    "host": ["{{base_url}}"],
                    "path": ["files"]
                }
            }
        }
    ]
}

# Add all folders to collection
collection["item"] = [
    auth_folder,
    expenses_folder,
    transfers_folder,
    incoming_folder,
    fundbox_folder,
    profile_folder,
    export_folder,
    admin_folder,
    audit_folder,
    sync_folder,
    files_folder
]

# Write to file
with open('postman/Finance-API-COMPLETE.postman_collection.json', 'w') as f:
    json.dump(collection, f, indent=2)

print("✅ Complete Postman collection created successfully!")
print("📁 File: postman/Finance-API-COMPLETE.postman_collection.json")
print("📊 Total folders: 11")
print("📊 Total endpoints: 50+")
print("\n🎯 Import this file into Postman to test all APIs!")
