<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class JoinGroupRequest extends FormRequest
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
            'group_code' => ['required', 'string', 'min:4', 'max:6', 'regex:/^[0-9]+$/'],
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
            'group_code.required' => 'The group code is required.',
            'group_code.string' => 'The group code must be a string.',
            'group_code.min' => 'The group code must be at least 4 digits.',
            'group_code.max' => 'The group code must not exceed 6 digits.',
            'group_code.regex' => 'The group code must contain only numeric digits.',
        ];
    }
}
