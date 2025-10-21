# PocketBase Backend for Finance App

This is the PocketBase backend deployed on Render.

## Deployment

This repository is automatically deployed to Render when changes are pushed to the main branch.

## Local Development

1. Download PocketBase from https://pocketbase.io/
2. Run: `./pocketbase serve`
3. Access admin UI at http://127.0.0.1:8090/_/

## Production URL

https://your-app-name.onrender.com

## Collections

### expenses
- user_id (number)
- username (text)
- user_email (email)
- local_expense_id (number)
- description (text)
- price_usd (number)
- price_syp (number)
- price_try (number)
- invoice_status (number)
- invoice_file_id (relation)
- expense_date (date)
- created_at (date)
- synced_at (date)

### invoice_files
- user_id (number)
- expense_id (number)
- file (file attachment)

### users
- Built-in collection with additional field:
- role (select: "user" or "admin")
