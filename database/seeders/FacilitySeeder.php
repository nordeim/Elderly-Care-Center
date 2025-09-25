<?php

namespace Database\Seeders;

use App\Models\Facility;
use Illuminate\Database\Seeder;

class FacilitySeeder extends Seeder
{
    public function run(): void
    {
        Facility::updateOrCreate(
            ['name' => 'Downtown Care Center'],
            [
                'address' => [
                    'street' => '123 Market Street',
                    'city' => 'San Francisco',
                    'state' => 'CA',
                    'postal_code' => '94105',
                ],
                'phone' => '+1-415-555-0100',
            ]
        );

        Facility::updateOrCreate(
            ['name' => 'Sunset Support Hub'],
            [
                'address' => [
                    'street' => '456 Sunset Blvd',
                    'city' => 'San Francisco',
                    'state' => 'CA',
                    'postal_code' => '94122',
                ],
                'phone' => '+1-415-555-0111',
            ]
        );
    }
}
