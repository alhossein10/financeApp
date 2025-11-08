@component('mail::message')
# Sync Failure Alert

Hello {{ $user->name }},

We've detected that your data synchronization has failed multiple times.

**Retry Attempts:** {{ $retryCount }}<br>
**Status:** Failed<br>
**Date & Time:** {{ now()->format('Y-m-d H:i:s') }}

This may be due to:
- Network connectivity issues
- Data conflicts between your device and the server
- Invalid data format

## What to do next:

1. Check your internet connection
2. Try syncing again from your app
3. If the problem persists, contact support

@component('mail::button', ['url' => config('app.frontend_url')])
Open App
@endcomponent

If you continue to experience issues, please contact our support team for assistance.

Thanks,<br>
{{ config('app.name') }}
@endcomponent
