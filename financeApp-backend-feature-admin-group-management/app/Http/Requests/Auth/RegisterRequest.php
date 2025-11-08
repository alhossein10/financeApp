<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
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
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'role' => ['sometimes', 'string', 'in:admin,user'],
            'organization_name' => ['required', 'string', 'min:2', 'max:255'],
            'department_name' => ['nullable', 'string', 'min:2', 'max:255'],
            'group_code' => [
                'nullable',
                'string',
                'digits_between:4,6',
                function ($attribute, $value, $fail) {
                    if ($value) {
                        $adminGroup = \App\Models\AdminGroup::where('group_code', $value)->first();
                        if (!$adminGroup) {
                            $fail('رمز المجموعة غير صحيح');
                        } elseif (!$adminGroup->is_active) {
                            $fail('رمز المجموعة غير نشط');
                        }
                    }
                },
            ],
        ];
    }

    /**
     * Get custom validation messages.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'organization_name.required' => 'اسم المنظمة مطلوب',
            'organization_name.min' => 'اسم المنظمة يجب أن يكون على الأقل حرفين',
            'organization_name.max' => 'اسم المنظمة يجب ألا يتجاوز 255 حرف',
            'department_name.min' => 'اسم القسم يجب أن يكون على الأقل حرفين',
            'department_name.max' => 'اسم القسم يجب ألا يتجاوز 255 حرف',
            'group_code.digits_between' => 'رمز المجموعة يجب أن يكون بين 4 و 6 أرقام',
        ];
    }

    /**
     * Configure the validator instance.
     *
     * @param \Illuminate\Validation\Validator $validator
     * @return void
     */
    public function withValidator($validator)
    {
        $validator->after(function ($validator) {
            $role = $this->input('role', 'user');
            $departmentName = $this->input('department_name');

            // Regular users must have a department
            if ($role === 'user' && !$departmentName) {
                $validator->errors()->add('department_name', 'القسم مطلوب للمستخدمين العاديين');
            }
        });
    }
}
