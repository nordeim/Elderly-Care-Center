<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class BookingStatusRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->can('access-admin') ?? false;
    }

    public function rules(): array
    {
        return [
            'status' => ['required', 'in:pending,confirmed,attended,cancelled,no_show,archived'],
        ];
    }
}
