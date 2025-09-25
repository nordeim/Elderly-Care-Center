<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            FacilitySeeder::class,
            ServiceSeeder::class,
            StaffSeeder::class,
            TestimonialSeeder::class,
            MediaSeeder::class,
        ]);
    }
}
