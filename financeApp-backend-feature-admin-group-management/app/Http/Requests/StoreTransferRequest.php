<?php

namespace App\Http\Requests;

use App\Services\AdminGroupService;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class StoreTransferRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true; // Authorization handled by middleware
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'recipient_name' => ['required', 'string', 'max:255'],
            'recipient_user_id' => ['nullable', 'integer', 'exists:users,id'],
            'amount_usd' => ['required', 'numeric', 'min:0.01', 'max:999999999.99'],
            'transfer_date' => ['required', 'date', 'before_or_equal:today'],
            'notes' => ['nullable', 'string', 'max:1000'],
            'sync_status' => ['nullable', 'in:pending,syncing,synced,failed'],
            'synced_at' => ['nullable', 'date'],
            
            // Optional exchange data
            'exchange' => ['nullable', 'array'],
            'exchange.converted_amount_syp' => ['nullable', 'numeric', 'min:0', 'max:999999999999.99'],
            'exchange.converted_amount_try' => ['nullable', 'numeric', 'min:0', 'max:999999999.99'],
            'exchange.exchange_rate_usd_to_syp' => ['nullable', 'numeric', 'min:0', 'max:999999.9999'],
            'exchange.exchange_rate_usd_to_try' => ['nullable', 'numeric', 'min:0', 'max:999999.9999'],
            'exchange.exchange_date' => ['nullable', 'date', 'before_or_equal:today'],
        ];
    }

    /**
     * Configure the validator instance.
     *
     * @param Validator $validator
     * @return void
     */
    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator) {
            // Only validate group membership if recipient_user_id is provided
            if ($this->filled('recipient_user_id')) {
                $this->validateRecipientInGroup($validator);
            }
        });
    }

    /**
     * Validate that the recipient user is in the admin's group.
     *
     * @param Validator $validator
     * @return void
     */
    protected function validateRecipientInGroup(Validator $validator): void
    {
        $user = $this->user();
        $recipientUserId = $this->input('recipient_user_id');

        // Only validate for admin users
        if (!$user || !$user->isAdmin()) {
            return;
        }

        // Get AdminGroupService from container
        $adminGroupService = app(AdminGroupService::class);

        // Get available transfer recipients (users in admin's group)
        $availableRecipients = $adminGroupService->getAvailableTransferRecipients($user);

        // Check if the recipient is in the list
        $recipientInGroup = $availableRecipients->contains('id', $recipientUserId);

        if (!$recipientInGroup) {
            $validator->errors()->add(
                'recipient_user_id',
                'Cannot transfer to user outside your group.'
            );
        }
    }

    /**
     * Get custom messages for validator errors.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'recipient_name.required' => 'Recipient name is required',
            'recipient_user_id.integer' => 'Recipient user ID must be a valid number',
            'recipient_user_id.exists' => 'The selected recipient user does not exist',
            'amount_usd.required' => 'Transfer amount in USD is required',
            'amount_usd.min' => 'Transfer amount must be at least 0.01 USD',
            'transfer_date.required' => 'Transfer date is required',
            'transfer_date.before_or_equal' => 'Transfer date cannot be in the future',
            'exchange.converted_amount_syp.numeric' => 'Converted amount in SYP must be a valid number',
            'exchange.converted_amount_try.numeric' => 'Converted amount in TRY must be a valid number',
            'exchange.exchange_rate_usd_to_syp.numeric' => 'Exchange rate USD to SYP must be a valid number',
            'exchange.exchange_rate_usd_to_try.numeric' => 'Exchange rate USD to TRY must be a valid number',
        ];
    }

    /**
     * Get custom attributes for validator errors.
     *
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'recipient_name' => 'recipient name',
            'recipient_user_id' => 'recipient user',
            'amount_usd' => 'amount in USD',
            'transfer_date' => 'transfer date',
            'exchange.converted_amount_syp' => 'converted amount in SYP',
            'exchange.converted_amount_try' => 'converted amount in TRY',
            'exchange.exchange_rate_usd_to_syp' => 'exchange rate USD to SYP',
            'exchange.exchange_rate_usd_to_try' => 'exchange rate USD to TRY',
            'exchange.exchange_date' => 'exchange date',
        ];
    }
}
