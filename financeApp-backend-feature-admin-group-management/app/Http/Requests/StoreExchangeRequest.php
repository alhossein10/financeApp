<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreExchangeRequest extends FormRequest
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
            'converted_amount_syp' => ['nullable', 'numeric', 'min:0', 'max:999999999999.99'],
            'converted_amount_try' => ['nullable', 'numeric', 'min:0', 'max:999999999.99'],
            'exchange_rate_usd_to_syp' => [
                'nullable',
                'numeric',
                'min:0',
                'max:999999.9999',
                'required_with:converted_amount_syp',
            ],
            'exchange_rate_usd_to_try' => [
                'nullable',
                'numeric',
                'min:0',
                'max:999999.9999',
                'required_with:converted_amount_try',
            ],
            'exchange_date' => ['nullable', 'date', 'before_or_equal:today'],
        ];
    }

    /**
     * Configure the validator instance.
     *
     * @param \Illuminate\Validation\Validator $validator
     * @return void
     */
    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            // At least one currency conversion must be provided
            $data = $validator->getData();
            
            $hasSyp = !empty($data['converted_amount_syp']) || !empty($data['exchange_rate_usd_to_syp']);
            $hasTry = !empty($data['converted_amount_try']) || !empty($data['exchange_rate_usd_to_try']);
            
            if (!$hasSyp && !$hasTry) {
                $validator->errors()->add(
                    'exchange',
                    'At least one currency conversion (SYP or TRY) must be provided'
                );
            }

            // If converted amount is provided, exchange rate must also be provided
            if (!empty($data['converted_amount_syp']) && empty($data['exchange_rate_usd_to_syp'])) {
                $validator->errors()->add(
                    'exchange_rate_usd_to_syp',
                    'Exchange rate USD to SYP is required when converted amount in SYP is provided'
                );
            }

            if (!empty($data['converted_amount_try']) && empty($data['exchange_rate_usd_to_try'])) {
                $validator->errors()->add(
                    'exchange_rate_usd_to_try',
                    'Exchange rate USD to TRY is required when converted amount in TRY is provided'
                );
            }
        });
    }

    /**
     * Get custom messages for validator errors.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'converted_amount_syp.numeric' => 'Converted amount in SYP must be a valid number',
            'converted_amount_syp.min' => 'Converted amount in SYP must be at least 0',
            'converted_amount_try.numeric' => 'Converted amount in TRY must be a valid number',
            'converted_amount_try.min' => 'Converted amount in TRY must be at least 0',
            'exchange_rate_usd_to_syp.numeric' => 'Exchange rate USD to SYP must be a valid number',
            'exchange_rate_usd_to_syp.min' => 'Exchange rate USD to SYP must be greater than 0',
            'exchange_rate_usd_to_syp.required_with' => 'Exchange rate USD to SYP is required when converted amount in SYP is provided',
            'exchange_rate_usd_to_try.numeric' => 'Exchange rate USD to TRY must be a valid number',
            'exchange_rate_usd_to_try.min' => 'Exchange rate USD to TRY must be greater than 0',
            'exchange_rate_usd_to_try.required_with' => 'Exchange rate USD to TRY is required when converted amount in TRY is provided',
            'exchange_date.before_or_equal' => 'Exchange date cannot be in the future',
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
            'converted_amount_syp' => 'converted amount in SYP',
            'converted_amount_try' => 'converted amount in TRY',
            'exchange_rate_usd_to_syp' => 'exchange rate USD to SYP',
            'exchange_rate_usd_to_try' => 'exchange rate USD to TRY',
            'exchange_date' => 'exchange date',
        ];
    }
}
