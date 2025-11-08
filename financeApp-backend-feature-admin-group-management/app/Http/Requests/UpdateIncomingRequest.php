<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateIncomingRequest extends FormRequest
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
            'description' => ['sometimes', 'required', 'string', 'max:1000'],
            'amount_usd' => ['sometimes', 'required', 'numeric', 'min:0.01', 'max:999999999.99'],
            'incoming_date' => ['sometimes', 'required', 'date', 'before_or_equal:today'],
            'sync_status' => ['nullable', 'in:pending,syncing,synced,failed'],
            'synced_at' => ['nullable', 'date'],
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
            'description.required' => 'Description is required',
            'description.max' => 'Description cannot exceed 1000 characters',
            'amount_usd.required' => 'Amount in USD is required',
            'amount_usd.min' => 'Amount must be at least 0.01 USD',
            'amount_usd.max' => 'Amount cannot exceed 999,999,999.99 USD',
            'incoming_date.required' => 'Incoming date is required',
            'incoming_date.before_or_equal' => 'Incoming date cannot be in the future',
            'sync_status.in' => 'Sync status must be one of: pending, syncing, synced, failed',
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
            'description' => 'description',
            'amount_usd' => 'amount in USD',
            'incoming_date' => 'incoming date',
            'sync_status' => 'sync status',
            'synced_at' => 'synced at',
        ];
    }
}
