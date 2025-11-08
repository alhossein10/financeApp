# Password Reset API Documentation

## Overview

The password reset functionality allows users to securely reset their passwords through a token-based system. The process involves two steps:

1. Request a password reset link (forgot password)
2. Reset the password using the token received via email

## Endpoints

### 1. Forgot Password (Request Reset Link)

**Endpoint:** `POST /api/v1/auth/forgot-password`

**Description:** Generates a password reset token and sends it to the user's email address.

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Password reset link sent to your email."
}
```

**Error Response (404 Not Found):**
```json
{
  "success": false,
  "message": "Failed to send password reset link.",
  "errors": {
    "email": ["We could not find a user with that email address."]
  }
}
```

**Validation Rules:**
- `email`: required, must be a valid email format

---

### 2. Reset Password

**Endpoint:** `POST /api/v1/auth/reset-password`

**Description:** Resets the user's password using the token received via email.

**Request Body:**
```json
{
  "email": "user@example.com",
  "token": "the-reset-token-from-email",
  "password": "newpassword123",
  "password_confirmation": "newpassword123"
}
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Password has been reset successfully."
}
```

**Error Response (422 Unprocessable Entity):**
```json
{
  "success": false,
  "message": "Failed to reset password.",
  "errors": {
    "token": ["Invalid password reset token."]
  }
}
```

**Validation Rules:**
- `email`: required, must be a valid email format
- `token`: required, must be a valid string
- `password`: required, minimum 8 characters, must match password_confirmation
- `password_confirmation`: required, must match password

---

## Token Expiration

Password reset tokens expire after **60 minutes**. After expiration, users must request a new reset link.

## Security Features

1. **Token Hashing**: Reset tokens are hashed before storage in the database
2. **Single Use**: Tokens are deleted after successful password reset
3. **Token Revocation**: All existing authentication tokens are revoked after password reset
4. **Email Verification**: Reset links are only sent to registered email addresses

## Email Notification

When a user requests a password reset, they receive an email containing:
- A reset link with the token embedded
- Expiration notice (60 minutes)
- Security notice if they didn't request the reset

The email template can be customized in `app/Notifications/ResetPasswordNotification.php`.

## Frontend Integration

The frontend application should:

1. Provide a "Forgot Password" form that collects the user's email
2. Call the `/api/v1/auth/forgot-password` endpoint
3. Display a success message instructing the user to check their email
4. Provide a "Reset Password" form that accepts:
   - Email (can be pre-filled from URL parameter)
   - Token (extracted from URL parameter)
   - New password
   - Password confirmation
5. Call the `/api/v1/auth/reset-password` endpoint
6. Redirect to login page on success

**Example Reset URL Format:**
```
https://your-app.com/reset-password?token=TOKEN_HERE&email=user@example.com
```

## Configuration

The frontend URL for password reset can be configured in your `.env` file:

```env
APP_FRONTEND_URL=https://your-app.com
```

This URL is used to generate the reset link in the email notification.

## Testing

Run the password reset tests:

```bash
# Unit tests
php artisan test --filter AuthServiceTest

# Feature tests
php artisan test --filter PasswordResetTest
```

## Error Codes

| Error | Status Code | Description |
|-------|-------------|-------------|
| Invalid email format | 422 | Email validation failed |
| User not found | 404 | No user with provided email |
| Invalid token | 422 | Token doesn't match or doesn't exist |
| Expired token | 422 | Token is older than 60 minutes |
| Password mismatch | 422 | Password and confirmation don't match |
| Password too short | 422 | Password less than 8 characters |

## Example Usage

### Using cURL

**Request Reset Link:**
```bash
curl -X POST http://localhost:8000/api/v1/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com"}'
```

**Reset Password:**
```bash
curl -X POST http://localhost:8000/api/v1/auth/reset-password \
  -H "Content-Type: application/json" \
  -d '{
    "email":"user@example.com",
    "token":"the-token-from-email",
    "password":"newpassword123",
    "password_confirmation":"newpassword123"
  }'
```

### Using JavaScript (Fetch API)

**Request Reset Link:**
```javascript
const response = await fetch('http://localhost:8000/api/v1/auth/forgot-password', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    email: 'user@example.com'
  })
});

const data = await response.json();
console.log(data);
```

**Reset Password:**
```javascript
const response = await fetch('http://localhost:8000/api/v1/auth/reset-password', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    email: 'user@example.com',
    token: 'the-token-from-email',
    password: 'newpassword123',
    password_confirmation: 'newpassword123'
  })
});

const data = await response.json();
console.log(data);
```
