<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class BookingRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'slot_id' => ['required', 'integer', 'exists:booking_slots,id'],
            'email' => ['required_without:client.email', 'nullable', 'email:rfc'],
            'caregiver_name' => ['nullable', 'string', 'max:255'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'client.first_name' => ['nullable', 'string', 'max:255'],
            'client.last_name' => ['nullable', 'string', 'max:255'],
            'client.email' => ['nullable', 'email:rfc'],
            'client.phone' => ['nullable', 'string', 'max:64'],
            'client.language_preference' => ['nullable', 'string', 'max:16'],
            'client.consent_version' => ['nullable', 'string', 'max:64'],
        ];
    }
}
