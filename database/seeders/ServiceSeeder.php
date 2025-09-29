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

        $services = [
            [
                'name' => 'Day Program Tours',
                'description' => 'Guided walkthrough showcasing community spaces, enrichment studios, and wellness suites to help families experience a typical day.',
                'duration_minutes' => 60,
            ],
            [
                'name' => 'Caregiver Consultation',
                'description' => 'Personalized meeting with our care coordinator to evaluate needs, build schedules, and discuss individualized support plans.',
                'duration_minutes' => 45,
            ],
            [
                'name' => 'Memory Wellness Studio',
                'description' => 'Evidence-based cognitive stimulation sessions led by specialists focused on memory retention, music therapy, and storytelling circles.',
                'duration_minutes' => 90,
            ],
            [
                'name' => 'Creative Arts & Movement',
                'description' => 'Adaptive art, dance, and gentle movement classes designed to improve mobility, coordination, and emotional expression.',
                'duration_minutes' => 75,
            ],
            [
                'name' => 'Family Support Workshops',
                'description' => 'Monthly workshops offering practical caregiver coaching, respite planning, and peer connection with other families.',
                'duration_minutes' => 120,
            ],
            [
                'name' => 'Wellness & Nutrition Check-ins',
                'description' => 'Registered dietitian consultations paired with light wellness screenings to tailor meals and daily routines.',
                'duration_minutes' => 50,
            ],
        ];

        foreach ($services as $service) {
            Service::updateOrCreate(
                ['name' => $service['name'], 'facility_id' => $facility->id],
                [
                    'description' => $service['description'],
                    'duration_minutes' => $service['duration_minutes'],
                ]
            );
        }
    }
}
