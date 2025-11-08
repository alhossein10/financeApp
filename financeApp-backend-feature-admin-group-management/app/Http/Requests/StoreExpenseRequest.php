<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreExpenseRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'description' => ['required', 'string', 'max:1000'],
            'price_usd' => ['nullable', 'numeric', 'min:0', 'max:999999.99'],
            'price_syp' => ['nullable', 'numeric', 'min:0', 'max:9999999999.99'],
            'price_try' => ['nullable', 'numeric', 'min:0', 'max:999999.99'],
            'expense_date' => ['required', 'date'],
            'photo' => ['nullable', 'file', 'image', 'max:10240', 'mimes:jpeg,jpg,png,gif,webp'], // Optional photo upload (max 10MB)
            'has_invoice' => ['nullable', 'boolean'],
            'invoice_path' => ['nullable', 'string', 'max:500'],
            'sync_status' => ['nullable', 'in:pending,syncing,synced,failed'],
            'synced_at' => ['nullable', 'date'],
            'sync_retry_count' => ['nullable', 'integer', 'min:0'],
            'sync_error_message' => ['nullable', 'string', 'max:500'],
            // Allow these fields but ignore them
            'user_id' => ['sometimes', 'integer'],
            'created_at' => ['sometimes', 'date'],
            'updated_at' => ['sometimes', 'date'],
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
            'description.required' => 'The expense description is required.',
            'price_usd.numeric' => 'The USD price must be a valid number.',
            'price_usd.min' => 'The USD price must be at least 0.',
            'price_syp.numeric' => 'The SYP price must be a valid number.',
            'price_try.numeric' => 'The TRY price must be a valid number.',
            'expense_date.required' => 'The expense date is required.',
            'expense_date.date' => 'The expense date must be a valid date.',
            'photo.file' => 'The photo must be a valid file.',
            'photo.image' => 'The photo must be an image file.',
            'photo.max' => 'The photo size must not exceed 10MB.',
            'photo.mimes' => 'The photo must be a file of type: jpeg, jpg, png, gif, webp.',
        ];
    }
}
