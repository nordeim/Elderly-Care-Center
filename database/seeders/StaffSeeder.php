<?php

namespace Database\Seeders;

use App\Models\StaffMember;
use Illuminate\Database\Seeder;

class StaffSeeder extends Seeder
{
    public function run(): void
    {
        StaffMember::updateOrCreate(
            ['full_name' => 'Dr. Aanya Patel'],
            [
                'role' => 'Medical Director',
                'bio' => 'Board-certified geriatric specialist overseeing care plans.',
                'photo_url' => 'https://via.placeholder.com/150',
                'certifications' => ['MD', 'Geriatric Medicine Fellowship'],
            ]
        );

        StaffMember::updateOrCreate(
            ['full_name' => 'Miguel Santos'],
            [
                'role' => 'Activities Coordinator',
                'bio' => 'Designs engaging cognitive and social programs for elders.',
                'photo_url' => 'https://via.placeholder.com/150',
                'certifications' => ['Certified Recreational Therapist'],
            ]
        );
    }
}
