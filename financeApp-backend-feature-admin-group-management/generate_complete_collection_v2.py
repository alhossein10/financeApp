#!/usr/bin/env python3
"""
Generate Complete Postman Collection v2 for Finance API
Includes all endpoints with organizational hierarchy support
"""

import json
from datetime import datetime

def create_collection():
    collection = {
        "info": {
            "name": "Finance API - Complete Collection v2",
            "description": "Complete API collection including organizational hierarchy features",
            "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
            "_postman_id": "finance-api-complete-v2",
            "version": "2.0.0"
        },
        "variable": [
            {"key": "base_url", "value": "http://127.0.0.1:8000/api/v1", "type": "string"},
            {"key": "token", "value": "", "type": "string"},
            {"key": "user_id", "value": "", "type": "string"},
            {"key": "expense_id", "value": "", "type": "string"},
            {"key": "transfer_id", "value": "", "type": "string"},
            {"key": "incoming_id", "value": "", "type": "string"},
            {"key": "organization_id", "value": "1", "type": "string"},
            {"key": "department_id", "value": "1", "type": "string"}
        ],
        "item": []
    }

    # 1. Public Endpoints Folder
    public_folder = {
        "name": "1. Public Endpoints",
        "item": [
            # Get Organizations
            {
                "name": "Get All Organizations",
                "request": {
                    "method": "GET",
                    "header": [],
                    "url": {
                        "raw": "{{base_url}}/organizations",
                        "host": ["{{base_url}}"],
                        "path": ["organizations"]
                    },
                    "description": "Get list of all organizations (public endpoint)"
                },
                "response": []
            },
            # Get Departments
            {
                "name": "Get Departments for Organization",
                "request": {
                    "method": "GET",
                    "header": [],
                    "url": {
                        "raw": "{{base_url}}/organizations/{{organization_id}}/departments",
                        "host": ["{{base_url}}"],
                        "path": ["organizations", "{{organization_id}}", "departments"]
                    },
                    "description": "Get departments for a specific organization"
                },
                "response": []
            }
        ]
    }

    # 2. Authentication Folder
    auth_folder = {
        "name": "2. Authentication",
        "item": [
            # Register Regular User
            {
                "name": "Register Regular User",
                "event": [
                    {
                        "listen": "test",
                        "script": {
                            "exec": [
                                "if (pm.response.code === 201) {",
                                "    var jsonData = pm.response.json();",
                                "    pm.collectionVariables.set('token', jsonData.data.token);",
                                "    pm.collectionVariables.set('user_id', jsonData.data.user.id);",
                                "}"
                            ]
                        }
                    }
                ],
                "request": {
                    "method": "POST",
                    "header": [{"key": "Content-Type", "value": "application/json"}],
                    "body": {
                        "mode": "raw",
                        "raw": json.dumps({
                            "name": "Test User",
                            "email": f"user{datetime.now().timestamp()}@example.com",
                            "password": "password123",
                            "password_confirmation": "password123",
                            "organization_id": 1,
                            "department_id": 2,
                            "role": "user"
                        }, indent=2)
                    },
                    "url": {
                        "raw": "{{base_url}}/auth/register",
                        "host": ["{{base_url}}"],
                        "path": ["auth", "register"]
                    }
                },
                "response": []
            },
            # Register Admin User
            {
                "name": "Register Admin User",
                "request": {
                    "method": "POST",
                    "header": [{"key": "Content-Type", "value": "application/json"}],
                    "body": {
                        "mode": "raw",
                        "raw": json.dumps({
                            "name": "Admin User",
                            "email": f"admin{datetime.now().timestamp()}@example.com",
                            "password": "password123",
                            "password_confirmation": "password123",
                            "organization_id": 1,
                            "role": "admin"
                        }, indent=2)
                    },
                    "url": {
                        "raw": "{{base_url}}/auth/register",
                        "host": ["{{base_url}}"],
                        "path": ["auth", "register"]
                    }
                },
                "response": []
            },
            # Login
            {
                "name": "Login",
                "event": [
                    {
                        "listen": "test",
                        "script": {
                            "exec": [
                                "if (pm.response.code === 200) {",
                                "    var jsonData = pm.response.json();",
                                "    pm.collectionVariables.set('token', jsonData.data.token);",
                                "    pm.collectionVariables.set('user_id', jsonData.data.user.id);",
                                "}"
                            ]
                        }
                    }
                ],
                "request": {
                    "method": "POST",
                    "header": [{"key": "Content-Type", "value": "application/json"}],
                    "body": {
                        "mode": "raw",
                        "raw": json.dumps({
                            "email": "user@example.com",
                            "password": "password123"
                        }, indent=2)
                    },
                    "url": {
                        "raw": "{{base_url}}/auth/login",
                        "host": ["{{base_url}}"],
                        "path": ["auth", "login"]
                    }
                },
                "response": []
            },
            # Get Current User
            {
                "name": "Get Current User",
                "request": {
                    "method": "GET",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/auth/me",
                        "host": ["{{base_url}}"],
                        "path": ["auth", "me"]
                    }
                },
                "response": []
            },
            # Refresh Token
            {
                "name": "Refresh Token",
                "event": [
                    {
                        "listen": "test",
                        "script": {
                            "exec": [
                                "if (pm.response.code === 200) {",
                                "    var jsonData = pm.response.json();",
                                "    pm.collectionVariables.set('token', jsonData.data.token);",
                                "}"
                            ]
                        }
                    }
                ],
                "request": {
                    "method": "POST",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/auth/refresh",
                        "host": ["{{base_url}}"],
                        "path": ["auth", "refresh"]
                    }
                },
                "response": []
            },
            # Logout
            {
                "name": "Logout",
                "request": {
                    "method": "POST",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/auth/logout",
                        "host": ["{{base_url}}"],
                        "path": ["auth", "logout"]
                    }
                },
                "response": []
            },
            # Forgot Password
            {
                "name": "Forgot Password",
                "request": {
                    "method": "POST",
                    "header": [{"key": "Content-Type", "value": "application/json"}],
                    "body": {
                        "mode": "raw",
                        "raw": json.dumps({
                            "email": "user@example.com"
                        }, indent=2)
                    },
                    "url": {
                        "raw": "{{base_url}}/auth/forgot-password",
                        "host": ["{{base_url}}"],
                        "path": ["auth", "forgot-password"]
                    }
                },
                "response": []
            }
        ]
    }

    # 3. Expenses Folder
    expenses_folder = {
        "name": "3. Expenses Management",
        "item": [
            # List Expenses
            {
                "name": "List Expenses",
                "request": {
                    "method": "GET",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/expenses?per_page=15",
                        "host": ["{{base_url}}"],
                        "path": ["expenses"],
                        "query": [
                            {"key": "per_page", "value": "15"},
                            {"key": "sync_status", "value": "synced", "disabled": True},
                            {"key": "expense_date_from", "value": "2024-01-01", "disabled": True},
                            {"key": "expense_date_to", "value": "2024-12-31", "disabled": True},
                            {"key": "search", "value": "", "disabled": True}
                        ]
                    }
                },
                "response": []
            },
            # Create Expense
            {
                "name": "Create Expense",
                "event": [
                    {
                        "listen": "test",
                        "script": {
                            "exec": [
                                "if (pm.response.code === 201) {",
                                "    var jsonData = pm.response.json();",
                                "    pm.collectionVariables.set('expense_id', jsonData.data.id);",
                                "}"
                            ]
                        }
                    }
                ],
                "request": {
                    "method": "POST",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Content-Type", "value": "application/json"}
                    ],
                    "body": {
                        "mode": "raw",
                        "raw": json.dumps({
                            "description": "Test expense",
                            "price_usd": 100.50,
                            "price_syp": 500000,
                            "expense_date": "2024-10-29"
                        }, indent=2)
                    },
                    "url": {
                        "raw": "{{base_url}}/expenses",
                        "host": ["{{base_url}}"],
                        "path": ["expenses"]
                    }
                },
                "response": []
            },
            # Get Expense
            {
                "name": "Get Expense",
                "request": {
                    "method": "GET",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/expenses/{{expense_id}}",
                        "host": ["{{base_url}}"],
                        "path": ["expenses", "{{expense_id}}"]
                    }
                },
                "response": []
            },
            # Update Expense
            {
                "name": "Update Expense",
                "request": {
                    "method": "PUT",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Content-Type", "value": "application/json"}
                    ],
                    "body": {
                        "mode": "raw",
                        "raw": json.dumps({
                            "description": "Updated expense",
                            "price_usd": 150.75
                        }, indent=2)
                    },
                    "url": {
                        "raw": "{{base_url}}/expenses/{{expense_id}}",
                        "host": ["{{base_url}}"],
                        "path": ["expenses", "{{expense_id}}"]
                    }
                },
                "response": []
            },
            # Upload Invoice
            {
                "name": "Upload Invoice",
                "request": {
                    "method": "POST",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "body": {
                        "mode": "formdata",
                        "formdata": [
                            {
                                "key": "photo",
                                "type": "file",
                                "src": ""
                            }
                        ]
                    },
                    "url": {
                        "raw": "{{base_url}}/expenses/{{expense_id}}/invoice",
                        "host": ["{{base_url}}"],
                        "path": ["expenses", "{{expense_id}}", "invoice"]
                    }
                },
                "response": []
            },
            # Download Invoice
            {
                "name": "Download Invoice",
                "request": {
                    "method": "GET",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/expenses/{{expense_id}}/invoice",
                        "host": ["{{base_url}}"],
                        "path": ["expenses", "{{expense_id}}", "invoice"]
                    }
                },
                "response": []
            },
            # Delete Invoice
            {
                "name": "Delete Invoice",
                "request": {
                    "method": "DELETE",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/expenses/{{expense_id}}/invoice",
                        "host": ["{{base_url}}"],
                        "path": ["expenses", "{{expense_id}}", "invoice"]
                    }
                },
                "response": []
            },
            # Delete Expense
            {
                "name": "Delete Expense",
                "request": {
                    "method": "DELETE",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/expenses/{{expense_id}}",
                        "host": ["{{base_url}}"],
                        "path": ["expenses", "{{expense_id}}"]
                    }
                },
                "response": []
            }
        ]
    }

    # 4. Transfers Folder
    transfers_folder = {
        "name": "4. Transfers Management",
        "item": [
            # List Transfers
            {
                "name": "List Transfers",
                "request": {
                    "method": "GET",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/transfers?per_page=15",
                        "host": ["{{base_url}}"],
                        "path": ["transfers"],
                        "query": [{"key": "per_page", "value": "15"}]
                    }
                },
                "response": []
            },
            # Create Transfer
            {
                "name": "Create Transfer",
                "event": [
                    {
                        "listen": "test",
                        "script": {
                            "exec": [
                                "if (pm.response.code === 201) {",
                                "    var jsonData = pm.response.json();",
                                "    pm.collectionVariables.set('transfer_id', jsonData.data.id);",
                                "}"
                            ]
                        }
                    }
                ],
                "request": {
                    "method": "POST",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Content-Type", "value": "application/json"}
                    ],
                    "body": {
                        "mode": "raw",
                        "raw": json.dumps({
                            "recipient_name": "John Doe",
                            "amount_usd": 500.00,
                            "transfer_date": "2024-10-29",
                            "notes": "Test transfer"
                        }, indent=2)
                    },
                    "url": {
                        "raw": "{{base_url}}/transfers",
                        "host": ["{{base_url}}"],
                        "path": ["transfers"]
                    }
                },
                "response": []
            },
            # Get Transfer
            {
                "name": "Get Transfer",
                "request": {
                    "method": "GET",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/transfers/{{transfer_id}}",
                        "host": ["{{base_url}}"],
                        "path": ["transfers", "{{transfer_id}}"]
                    }
                },
                "response": []
            },
            # Update Transfer
            {
                "name": "Update Transfer",
                "request": {
                    "method": "PUT",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Content-Type", "value": "application/json"}
                    ],
                    "body": {
                        "mode": "raw",
                        "raw": json.dumps({
                            "recipient_name": "Jane Doe",
                            "amount_usd": 600.00
                        }, indent=2)
                    },
                    "url": {
                        "raw": "{{base_url}}/transfers/{{transfer_id}}",
                        "host": ["{{base_url}}"],
                        "path": ["transfers", "{{transfer_id}}"]
                    }
                },
                "response": []
            },
            # Add Exchange to Transfer
            {
                "name": "Add Exchange to Transfer",
                "request": {
                    "method": "POST",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Content-Type", "value": "application/json"}
                    ],
                    "body": {
                        "mode": "raw",
                        "raw": json.dumps({
                            "exchange_rate": 15000,
                            "amount_syp": 7500000,
                            "exchange_date": "2024-10-29"
                        }, indent=2)
                    },
                    "url": {
                        "raw": "{{base_url}}/transfers/{{transfer_id}}/exchange",
                        "host": ["{{base_url}}"],
                        "path": ["transfers", "{{transfer_id}}", "exchange"]
                    }
                },
                "response": []
            },
            # Delete Transfer
            {
                "name": "Delete Transfer",
                "request": {
                    "method": "DELETE",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/transfers/{{transfer_id}}",
                        "host": ["{{base_url}}"],
                        "path": ["transfers", "{{transfer_id}}"]
                    }
                },
                "response": []
            }
        ]
    }

    # 5. Incoming Folder
    incoming_folder = {
        "name": "5. Incoming Management",
        "item": [
            # List Incoming
            {
                "name": "List Incoming",
                "request": {
                    "method": "GET",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/incoming?per_page=15",
                        "host": ["{{base_url}}"],
                        "path": ["incoming"],
                        "query": [{"key": "per_page", "value": "15"}]
                    }
                },
                "response": []
            },
            # Create Incoming
            {
                "name": "Create Incoming",
                "event": [
                    {
                        "listen": "test",
                        "script": {
                            "exec": [
                                "if (pm.response.code === 201) {",
                                "    var jsonData = pm.response.json();",
                                "    pm.collectionVariables.set('incoming_id', jsonData.data.id);",
                                "}"
                            ]
                        }
                    }
                ],
                "request": {
                    "method": "POST",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Content-Type", "value": "application/json"}
                    ],
                    "body": {
                        "mode": "raw",
                        "raw": json.dumps({
                            "description": "Monthly budget",
                            "amount_usd": 5000.00,
                            "incoming_date": "2024-10-29"
                        }, indent=2)
                    },
                    "url": {
                        "raw": "{{base_url}}/incoming",
                        "host": ["{{base_url}}"],
                        "path": ["incoming"]
                    }
                },
                "response": []
            },
            # Get Incoming
            {
                "name": "Get Incoming",
                "request": {
                    "method": "GET",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/incoming/{{incoming_id}}",
                        "host": ["{{base_url}}"],
                        "path": ["incoming", "{{incoming_id}}"]
                    }
                },
                "response": []
            },
            # Update Incoming
            {
                "name": "Update Incoming",
                "request": {
                    "method": "PUT",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Content-Type", "value": "application/json"}
                    ],
                    "body": {
                        "mode": "raw",
                        "raw": json.dumps({
                            "description": "Updated monthly budget",
                            "amount_usd": 5500.00
                        }, indent=2)
                    },
                    "url": {
                        "raw": "{{base_url}}/incoming/{{incoming_id}}",
                        "host": ["{{base_url}}"],
                        "path": ["incoming", "{{incoming_id}}"]
                    }
                },
                "response": []
            },
            # Delete Incoming
            {
                "name": "Delete Incoming",
                "request": {
                    "method": "DELETE",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/incoming/{{incoming_id}}",
                        "host": ["{{base_url}}"],
                        "path": ["incoming", "{{incoming_id}}"]
                    }
                },
                "response": []
            }
        ]
    }

    # 6. Fund Box Folder (Admin Only)
    fundbox_folder = {
        "name": "6. Fund Box (Admin Only)",
        "item": [
            # Get Fund Box
            {
                "name": "Get Fund Box",
                "request": {
                    "method": "GET",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/fund-box",
                        "host": ["{{base_url}}"],
                        "path": ["fund-box"]
                    }
                },
                "response": []
            },
            # Update Fund Box
            {
                "name": "Update Fund Box",
                "request": {
                    "method": "PUT",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Content-Type", "value": "application/json"}
                    ],
                    "body": {
                        "mode": "raw",
                        "raw": json.dumps({
                            "balance_usd": 10000.00
                        }, indent=2)
                    },
                    "url": {
                        "raw": "{{base_url}}/fund-box",
                        "host": ["{{base_url}}"],
                        "path": ["fund-box"]
                    }
                },
                "response": []
            }
        ]
    }

    # 7. Admin Dashboard Folder
    dashboard_folder = {
        "name": "7. Admin Dashboard (Admin Only)",
        "item": [
            # Get Stats
            {
                "name": "Get Dashboard Stats",
                "request": {
                    "method": "GET",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/admin/dashboard/stats",
                        "host": ["{{base_url}}"],
                        "path": ["admin", "dashboard", "stats"]
                    }
                },
                "response": []
            },
            # Get Users
            {
                "name": "Get Dashboard Users",
                "request": {
                    "method": "GET",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/admin/dashboard/users",
                        "host": ["{{base_url}}"],
                        "path": ["admin", "dashboard", "users"]
                    }
                },
                "response": []
            },
            # Get Expenses Summary
            {
                "name": "Get Dashboard Expenses",
                "request": {
                    "method": "GET",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/admin/dashboard/expenses",
                        "host": ["{{base_url}}"],
                        "path": ["admin", "dashboard", "expenses"]
                    }
                },
                "response": []
            },
            # Get Analytics
            {
                "name": "Get Dashboard Analytics",
                "request": {
                    "method": "GET",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/admin/dashboard/analytics",
                        "host": ["{{base_url}}"],
                        "path": ["admin", "dashboard", "analytics"]
                    }
                },
                "response": []
            }
        ]
    }

    # 8. Audit Logs Folder
    audit_folder = {
        "name": "8. Audit Logs (Admin Only)",
        "item": [
            # List Audit Logs
            {
                "name": "List Audit Logs",
                "request": {
                    "method": "GET",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/audit-logs?per_page=15",
                        "host": ["{{base_url}}"],
                        "path": ["audit-logs"],
                        "query": [{"key": "per_page", "value": "15"}]
                    }
                },
                "response": []
            },
            # Get Audit Log
            {
                "name": "Get Audit Log",
                "request": {
                    "method": "GET",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/audit-logs/1",
                        "host": ["{{base_url}}"],
                        "path": ["audit-logs", "1"]
                    }
                },
                "response": []
            }
        ]
    }

    # 9. Sync Folder
    sync_folder = {
        "name": "9. Data Synchronization",
        "item": [
            # Batch Sync
            {
                "name": "Batch Sync",
                "request": {
                    "method": "POST",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Content-Type", "value": "application/json"}
                    ],
                    "body": {
                        "mode": "raw",
                        "raw": json.dumps({
                            "expenses": [
                                {
                                    "description": "Offline expense",
                                    "price_usd": 50.00,
                                    "expense_date": "2024-10-29"
                                }
                            ]
                        }, indent=2)
                    },
                    "url": {
                        "raw": "{{base_url}}/sync/batch",
                        "host": ["{{base_url}}"],
                        "path": ["sync", "batch"]
                    }
                },
                "response": []
            },
            # Get Changes
            {
                "name": "Get Changes",
                "request": {
                    "method": "GET",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/sync/changes?since=2024-10-01",
                        "host": ["{{base_url}}"],
                        "path": ["sync", "changes"],
                        "query": [{"key": "since", "value": "2024-10-01"}]
                    }
                },
                "response": []
            },
            # Resolve Conflict
            {
                "name": "Resolve Conflict",
                "request": {
                    "method": "POST",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Content-Type", "value": "application/json"}
                    ],
                    "body": {
                        "mode": "raw",
                        "raw": json.dumps({
                            "resource_type": "expense",
                            "resource_id": 1,
                            "resolution": "server"
                        }, indent=2)
                    },
                    "url": {
                        "raw": "{{base_url}}/sync/resolve",
                        "host": ["{{base_url}}"],
                        "path": ["sync", "resolve"]
                    }
                },
                "response": []
            }
        ]
    }

    # 10. User Profile Folder
    profile_folder = {
        "name": "10. User Profile",
        "item": [
            # Get Profile
            {
                "name": "Get Profile",
                "request": {
                    "method": "GET",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/profile",
                        "host": ["{{base_url}}"],
                        "path": ["profile"]
                    }
                },
                "response": []
            },
            # Update Profile
            {
                "name": "Update Profile",
                "request": {
                    "method": "PUT",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Content-Type", "value": "application/json"}
                    ],
                    "body": {
                        "mode": "raw",
                        "raw": json.dumps({
                            "name": "Updated Name",
                            "email": "updated@example.com"
                        }, indent=2)
                    },
                    "url": {
                        "raw": "{{base_url}}/profile",
                        "host": ["{{base_url}}"],
                        "path": ["profile"]
                    }
                },
                "response": []
            },
            # Change Password
            {
                "name": "Change Password",
                "request": {
                    "method": "PUT",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Content-Type", "value": "application/json"}
                    ],
                    "body": {
                        "mode": "raw",
                        "raw": json.dumps({
                            "current_password": "password123",
                            "password": "newpassword123",
                            "password_confirmation": "newpassword123"
                        }, indent=2)
                    },
                    "url": {
                        "raw": "{{base_url}}/profile/password",
                        "host": ["{{base_url}}"],
                        "path": ["profile", "password"]
                    }
                },
                "response": []
            },
            # Delete Account
            {
                "name": "Delete Account",
                "request": {
                    "method": "DELETE",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/profile",
                        "host": ["{{base_url}}"],
                        "path": ["profile"]
                    }
                },
                "response": []
            }
        ]
    }

    # 11. Export Folder
    export_folder = {
        "name": "11. Data Export",
        "item": [
            # List Exports
            {
                "name": "List Exports",
                "request": {
                    "method": "GET",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/export",
                        "host": ["{{base_url}}"],
                        "path": ["export"]
                    }
                },
                "response": []
            },
            # Export Expenses to PDF
            {
                "name": "Export Expenses to PDF",
                "request": {
                    "method": "POST",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Content-Type", "value": "application/json"}
                    ],
                    "body": {
                        "mode": "raw",
                        "raw": json.dumps({
                            "date_from": "2024-01-01",
                            "date_to": "2024-12-31"
                        }, indent=2)
                    },
                    "url": {
                        "raw": "{{base_url}}/export/expenses/pdf",
                        "host": ["{{base_url}}"],
                        "path": ["export", "expenses", "pdf"]
                    }
                },
                "response": []
            },
            # Export Expenses to Excel
            {
                "name": "Export Expenses to Excel",
                "request": {
                    "method": "POST",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Content-Type", "value": "application/json"}
                    ],
                    "body": {
                        "mode": "raw",
                        "raw": json.dumps({
                            "date_from": "2024-01-01",
                            "date_to": "2024-12-31"
                        }, indent=2)
                    },
                    "url": {
                        "raw": "{{base_url}}/export/expenses/excel",
                        "host": ["{{base_url}}"],
                        "path": ["export", "expenses", "excel"]
                    }
                },
                "response": []
            },
            # System-Wide Export (Admin Only)
            {
                "name": "System-Wide Export (Admin)",
                "request": {
                    "method": "POST",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Content-Type", "value": "application/json"}
                    ],
                    "body": {
                        "mode": "raw",
                        "raw": json.dumps({
                            "format": "excel",
                            "include": ["expenses", "transfers", "incoming"]
                        }, indent=2)
                    },
                    "url": {
                        "raw": "{{base_url}}/export/system-wide",
                        "host": ["{{base_url}}"],
                        "path": ["export", "system-wide"]
                    }
                },
                "response": []
            },
            # Get Export Status
            {
                "name": "Get Export Status",
                "request": {
                    "method": "GET",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/export/1/status",
                        "host": ["{{base_url}}"],
                        "path": ["export", "1", "status"]
                    }
                },
                "response": []
            },
            # Download Export
            {
                "name": "Download Export",
                "request": {
                    "method": "GET",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "url": {
                        "raw": "{{base_url}}/export/1/download",
                        "host": ["{{base_url}}"],
                        "path": ["export", "1", "download"]
                    }
                },
                "response": []
            }
        ]
    }

    # 12. File Operations Folder
    files_folder = {
        "name": "12. File Operations",
        "item": [
            # Upload File
            {
                "name": "Upload File",
                "request": {
                    "method": "POST",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Accept", "value": "application/json"}
                    ],
                    "body": {
                        "mode": "formdata",
                        "formdata": [
                            {
                                "key": "file",
                                "type": "file",
                                "src": ""
                            },
                            {
                                "key": "path",
                                "value": "uploads",
                                "type": "text"
                            }
                        ]
                    },
                    "url": {
                        "raw": "{{base_url}}/files/upload",
                        "host": ["{{base_url}}"],
                        "path": ["files", "upload"]
                    }
                },
                "response": []
            },
            # Delete File
            {
                "name": "Delete File",
                "request": {
                    "method": "DELETE",
                    "header": [
                        {"key": "Authorization", "value": "Bearer {{token}}"},
                        {"key": "Content-Type", "value": "application/json"}
                    ],
                    "body": {
                        "mode": "raw",
                        "raw": json.dumps({
                            "path": "uploads/file.pdf"
                        }, indent=2)
                    },
                    "url": {
                        "raw": "{{base_url}}/files",
                        "host": ["{{base_url}}"],
                        "path": ["files"]
                    }
                },
                "response": []
            }
        ]
    }

    # Add all folders to collection
    collection["item"] = [
        public_folder,
        auth_folder,
        expenses_folder,
        transfers_folder,
        incoming_folder,
        fundbox_folder,
        dashboard_folder,
        audit_folder,
        sync_folder,
        profile_folder,
        export_folder,
        files_folder
    ]

    return collection


def main():
    """Generate and save the collection"""
    collection = create_collection()
    
    # Save to file
    output_file = "postman/Finance-API-Complete-v2.postman_collection.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(collection, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Complete Postman collection generated: {output_file}")
    print(f"📊 Total endpoints: {sum(len(folder['item']) for folder in collection['item'])}")
    print("\nCollection includes:")
    for i, folder in enumerate(collection['item'], 1):
        print(f"  {i}. {folder['name']} ({len(folder['item'])} endpoints)")


if __name__ == "__main__":
    main()
