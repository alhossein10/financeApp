<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateTransferRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true; // Authorization handled by policy
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'recipient_name' => ['sometimes', 'string', 'max:255'],
            'amount_usd' => ['sometimes', 'numeric', 'min:0.01', 'max:999999999.99'],
            'transfer_date' => ['sometimes', 'date', 'before_or_equal:today'],
            'notes' => ['nullable', 'string', 'max:1000'],
            'sync_status' => ['sometimes', 'in:pending,syncing,synced,failed'],
            'synced_at' => ['nullable', 'date'],
            
            // Optional exchange data (can update existing or create new)
            'exchange' => ['nullable', 'array'],
            'exchange.converted_amount_syp' => ['nullable', 'numeric', 'min:0', 'max:999999999999.99'],
            'exchange.converted_amount_try' => ['nullable', 'numeric', 'min:0', 'max:999999999.99'],
            'exchange.exchange_rate_usd_to_syp' => ['nullable', 'numeric', 'min:0', 'max:999999.9999'],
            'exchange.exchange_rate_usd_to_try' => ['nullable', 'numeric', 'min:0', 'max:999999.9999'],
            'exchange.exchange_date' => ['nullable', 'date', 'before_or_equal:today'],
        ];
    }

    /**
     * Get custom messages for validator errors.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'recipient_name.string' => 'Recipient name must be a valid string',
            'amount_usd.min' => 'Transfer amount must be at least 0.01 USD',
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
