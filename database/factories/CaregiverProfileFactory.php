<?php

namespace Database\Factories;

use App\Models\CaregiverProfile;
use App\Models\Client;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<CaregiverProfile>
 */
class CaregiverProfileFactory extends Factory
{
    /**
     * The name of the factory's corresponding model.
     *
     * @var class-string<CaregiverProfile>
     */
    protected $model = CaregiverProfile::class;

    /**
     * Define the model's default state.
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'client_id' => Client::factory(),
            'preferred_contact_method' => $this->faker->randomElement(['email', 'sms']),
            'timezone' => $this->faker->timezone(),
            'sms_opt_in' => $this->faker->boolean(80),
            'preferences' => [
                'notifications' => [
                    'email' => true,
                    'sms' => $this->faker->boolean(60),
                ],
            ],
        ];
    }

    /**
     * Indicate that the caregiver profile should be unsubscribed from SMS updates.
     */
    public function smsOptOut(): static
    {
        return $this->state(fn (array $attributes) => [
            'sms_opt_in' => false,
        ]);
    }

    /**
     * Create a caregiver profile without an associated client.
     */
    public function withoutClient(): static
    {
        return $this->state(fn (array $attributes) => [
            'client_id' => null,
        ]);
    }
}
