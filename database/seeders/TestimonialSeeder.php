<?php

namespace Database\Seeders;

use App\Models\Client;
use App\Models\Testimonial;
use Illuminate\Database\Seeder;

class TestimonialSeeder extends Seeder
{
    public function run(): void
    {
        $entries = [
            [
                'content' => 'The staff made my mom feel welcome from day one and kept us informed every step.',
                'client' => [
                    'first_name' => 'Eleanor',
                    'last_name' => 'Nguyen',
                    'email' => 'eleanor.nguyen@example.com',
                    'phone' => '+1-415-555-0122',
                    'language_preference' => 'en',
                ],
            ],
            [
                'content' => 'Their memory care specialists brought back my dad’s love for music and conversation.',
                'client' => [
                    'first_name' => 'Calvin',
                    'last_name' => 'Hernandez',
                    'email' => 'calvin.hernandez@example.com',
                    'phone' => '+1-628-555-0155',
                    'language_preference' => 'en',
                ],
            ],
            [
                'content' => 'As a caregiver, the respite support and coaching empowered me to recharge and learn new skills.',
                'client' => null,
            ],
            [
                'content' => 'Warm meals, transportation, and engaging art sessions keep my aunt excited for each visit.',
                'client' => [
                    'first_name' => 'Amelia',
                    'last_name' => 'Singh',
                    'email' => 'amelia.singh@example.com',
                    'phone' => '+1-669-555-0199',
                    'language_preference' => 'en',
                ],
            ],
            [
                'content' => 'Their wellness check-ins helped us coordinate with our family physician seamlessly.',
                'client' => null,
            ],
            [
                'content' => 'The team celebrates every small victory—my grandmother feels valued and safe.',
                'client' => [
                    'first_name' => 'Lina',
                    'last_name' => 'Rodriguez',
                    'email' => 'lina.rodriguez@example.com',
                    'phone' => '+1-650-555-0111',
                    'language_preference' => 'es',
                ],
            ],
        ];

        foreach ($entries as $entry) {
            $clientId = null;

            if (! empty($entry['client'])) {
                $client = Client::updateOrCreate(
                    ['email' => $entry['client']['email']],
                    $entry['client']
                );

                $clientId = $client->id;
            }

            Testimonial::updateOrCreate(
                ['content' => $entry['content']],
                [
                    'client_id' => $clientId,
                    'status' => 'approved',
                ]
            );
        }
    }
}
