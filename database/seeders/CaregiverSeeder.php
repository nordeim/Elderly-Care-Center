<?php

namespace Database\Seeders;

use App\Models\CaregiverProfile;
use App\Models\Client;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class CaregiverSeeder extends Seeder
{
    public function run(): void
    {
        $client = Client::first();

        if (! $client) {
            $client = Client::create([
                'first_name' => 'Avery',
                'last_name' => 'Williams',
                'email' => 'avery.williams@example.com',
                'phone' => '+1-415-555-0130',
                'language_preference' => 'en',
            ]);
        }

        $caregiverUser = User::firstOrCreate(
            ['email' => 'caregiver@example.com'],
            [
                'full_name' => 'Jordan Lee',
                'password_hash' => bcrypt('password'),
                'role' => 'caregiver',
                'is_active' => true,
            ]
        );

        CaregiverProfile::updateOrCreate(
            ['user_id' => $caregiverUser->id],
            [
                'client_id' => $client->id,
                'preferred_contact_method' => 'email',
                'timezone' => 'America/Los_Angeles',
                'sms_opt_in' => true,
                'preferences' => [
                    'reminder_window_hours' => 24,
                    'language' => 'en',
                ],
            ]
        );
    }
}
