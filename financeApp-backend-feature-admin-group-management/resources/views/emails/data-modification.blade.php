@component('mail::message')
# Data Modification Alert

Hello {{ $user->name }},

This is to inform you that an administrator has {{ $action }}d your {{ $resource }} data.

**Action:** {{ ucfirst($action) }}<br>
**Resource Type:** {{ ucfirst($resource) }}<br>
**Date & Time:** {{ now()->format('Y-m-d H:i:s') }}

If you did not expect this change or have any concerns, please contact your system administrator immediately.

@component('mail::button', ['url' => config('app.frontend_url')])
View Your Account
@endcomponent

Thanks,<br>
{{ config('app.name') }}
@endcomponent
