<?php

namespace Database\Seeders;

use App\Models\Facility;
use App\Models\Service;
use Illuminate\Database\Seeder;

class ServiceSeeder extends Seeder
{
    public function run(): void
    {
        $facility = Facility::first();

        if (! $facility) {
            return;
        }

        Service::updateOrCreate(
            ['name' => 'Day Program Tours', 'facility_id' => $facility->id],
            [
                'description' => 'Guided walkthrough of daily activities, dining, and wellness programs.',
                'duration_minutes' => 60,
            ]
        );

        Service::updateOrCreate(
            ['name' => 'Caregiver Consultation', 'facility_id' => $facility->id],
            [
                'description' => 'One-on-one consultation with care coordinator to discuss needs and goals.',
                'duration_minutes' => 45,
            ]
        );
    }
}
