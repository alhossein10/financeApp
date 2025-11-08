@component('mail::message')
# Welcome to Finance Management System

Hello {{ $user->name }},

Thank you for registering with our Finance Management System! We're excited to have you on board.

Your account has been successfully created and you can now start managing your financial records, including:

- **Expenses** - Track your spending with multi-currency support
- **Transfers** - Record money transfers with exchange rates
- **Incoming Funds** - Monitor revenue and money received
- **Invoice Management** - Attach and manage invoice documents

@component('mail::button', ['url' => config('app.frontend_url')])
Get Started
@endcomponent

If you have any questions or need assistance, please don't hesitate to reach out to our support team.

Thanks,<br>
{{ config('app.name') }}
@endcomponent
