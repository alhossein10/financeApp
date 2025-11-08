import json

collection = {
    "info": {
        "name": "Finance Backend API",
        "description": "Complete API collection for Finance Management Backend",
        "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
    },
    "auth": {
        "type": "bearer",
        "bearer": [{"key": "token", "value": "{{auth_token}}", "type": "string"}]
    },
    "variable": [
        {"key": "base_url", "value": "http://localhost:8000/api/v1"},
        {"key": "auth_token", "value": ""},
        {"key": "expense_id", "value": ""},
        {"key": "transfer_id", "value": ""},
        {"key": "incoming_id", "value": ""},
        {"key": "export_id", "value": ""}
    ],
    "item": []
}

# Save to file
with open('postman/Finance-API.postman_collection.json', 'w', encoding='utf-8') as f:
    json.dump(collection, f, indent=2)

print("✓ Postman collection created successfully!")
print("  File: postman/Finance-API.postman_collection.json")
print("  Import this file into Postman to get started")


# Authentication folder
auth_folder = {
    "name": "Authentication",
    "item": [
        {
            "name": "Register",
            "event": [{
                "listen": "test",
                "script": {
                    "exec": [
                        "if (pm.response.code === 201) {",
                        "  var data = pm.response.json();",
                        "  pm.collectionVariables.set('auth_token', data.data.token);",
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
                "url": {"raw": "{{base_url}}/register", "host": ["{{base_url}}"], "path": ["register"]}
            }
        },
        {
            "name": "Login",
            "event": [{
                "listen": "test",
                "script": {
                    "exec": [
                        "if (pm.response.code === 200) {",
                        "  var data = pm.response.json();",
                        "  pm.collectionVariables.set('auth_token', data.data.token);",
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
                "url": {"raw": "{{base_url}}/login", "host": ["{{base_url}}"], "path": ["login"]}
            }
        },
        {
            "name": "Get Current User",
            "request": {
                "method": "GET",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {"raw": "{{base_url}}/me", "host": ["{{base_url}}"], "path": ["me"]}
            }
        },
        {
            "name": "Logout",
            "request": {
                "method": "POST",
                "header": [{"key": "Accept", "value": "application/json"}],
                "url": {"raw": "{{base_url}}/logout", "host": ["{{base_url}}"], "path": ["logout"]}
            }
        }
    ]
}

collection["item"].append(auth_folder)

# Save updated collection
with open('postman/Finance-API.postman_collection.json', 'w', encoding='utf-8') as f:
    json.dump(collection, f, indent=2)

print("✓ Added Authentication endpoints")
