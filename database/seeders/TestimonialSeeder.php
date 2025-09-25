<?php

namespace Database\Seeders;

use App\Models\Client;
use App\Models\Testimonial;
use Illuminate\Database\Seeder;

class TestimonialSeeder extends Seeder
{
    public function run(): void
    {
        $client = Client::first() ?? Client::create([
            'first_name' => 'Eleanor',
            'last_name' => 'Nguyen',
            'email' => 'eleanor.nguyen@example.com',
            'phone' => '+1-415-555-0122',
            'language_preference' => 'en',
        ]);

        Testimonial::updateOrCreate(
            ['content' => 'The staff made my mom feel welcome from day one.'],
            [
                'client_id' => $client->id,
                'status' => 'approved',
            ]
        );

        Testimonial::updateOrCreate(
            ['content' => 'Beautiful facility and engaging activities for seniors.'],
            [
                'client_id' => null,
                'status' => 'approved',
            ]
        );
    }
}
