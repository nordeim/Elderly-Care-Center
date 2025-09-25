<?php

namespace Tests\Feature\Payments;

use App\Http\Controllers\Payments\StripeWebhookController;
use App\Models\Booking;
use App\Models\BookingSlot;
use App\Models\CaregiverProfile;
use App\Models\Client;
use App\Models\Facility;
use App\Models\Payment;
use App\Models\Service;
use App\Models\User;
use App\Services\Payments\StripeService;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\Str;
use Mockery;
use Stripe\Event;
use Stripe\PaymentIntent;
use Stripe\StripeClient;
use Tests\TestCase;

class StripeFlowTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config([
            'payments.currency' => 'usd',
            'payments.stripe.publishable_key' => 'pk_test_123',
            'payments.stripe.webhook_secret' => 'whsec_test',
            'payments.default_deposit_cents' => 5000,
        ]);

        Log::spy();
    }

    public function test_caregiver_can_view_checkout_page(): void
    {
        [$user, $booking] = $this->createBookingScenario();

        $stripeClient = Mockery::mock(StripeClient::class);
        $stripeClient->paymentIntents = Mockery::mock();
        $stripeClient->paymentIntents->shouldReceive('create')->once()->andReturn((object) [
            'id' => 'pi_test_1',
            'status' => 'requires_action',
        ]);
        $stripeClient->paymentIntents->shouldReceive('retrieve')->andReturn((object) [
            'id' => 'pi_test_1',
            'client_secret' => 'secret_test',
        ]);

        $this->app->instance(StripeClient::class, $stripeClient);

        $response = $this->actingAs($user)->get(route('payments.checkout.show', $booking));

        $response->assertOk();
        $response->assertViewIs('payments.deposit');
        $response->assertViewHas('clientSecret', 'secret_test');
        $this->assertDatabaseHas('payments', [
            'booking_id' => $booking->id,
            'stripe_payment_intent_id' => 'pi_test_1',
            'status' => 'requires_action',
            'amount_cents' => 5000,
        ]);
    }

    public function test_webhook_marks_payment_succeeded(): void
    {
        [$user, $booking] = $this->createBookingScenario();
        $payment = Payment::create([
            'booking_id' => $booking->id,
            'stripe_payment_intent_id' => 'pi_test_2',
            'status' => Payment::STATUS_PENDING,
            'amount_cents' => 5000,
            'currency' => 'usd',
        ]);

        $stripeClient = Mockery::mock(StripeClient::class);
        $stripeClient->paymentIntents = Mockery::mock();
        $stripeClient->paymentIntents->shouldReceive('retrieve')->andReturn((object) [
            'id' => 'pi_test_2',
            'status' => 'succeeded',
            'charges' => (object) [
                'data' => [
                    (object) ['receipt_url' => 'https://stripe.test/receipt'],
                ],
            ],
            'metadata' => collect(['booking_id' => $booking->id]),
        ]);
        $this->app->instance(StripeClient::class, $stripeClient);

        $service = app(StripeService::class);
        $controller = new StripeWebhookController($service);

        $event = new Event();
        $event->type = 'payment_intent.succeeded';
        $event->data = (object) ['object' => (object) ['id' => 'pi_test_2']];

        $controller->handleSucceeded($event);

        $payment->refresh();
        $this->assertSame(Payment::STATUS_SUCCEEDED, $payment->status);
        $this->assertSame('https://stripe.test/receipt', $payment->receipt_url);
    }

    private function createBookingScenario(): array
    {
        $user = User::create([
            'full_name' => 'Taylor Caregiver',
            'email' => 'caregiver@example.com',
            'password_hash' => Hash::make('secret123'),
            'role' => 'caregiver',
            'is_active' => true,
        ]);

        $client = Client::create([
            'first_name' => 'Avery',
            'last_name' => 'Williams',
            'email' => 'avery@example.com',
            'phone' => '+1-415-555-0100',
            'language_preference' => 'en',
        ]);

        CaregiverProfile::create([
            'user_id' => $user->id,
            'client_id' => $client->id,
            'preferred_contact_method' => 'email',
            'timezone' => 'UTC',
            'sms_opt_in' => true,
        ]);

        $facility = Facility::create([
            'name' => 'Downtown Center',
            'address' => ['street' => '123 Market St', 'city' => 'SF'],
            'phone' => '+1-415-555-0100',
        ]);

        $service = Service::create([
            'facility_id' => $facility->id,
            'name' => 'Day Program',
            'description' => 'Full-day engagement.',
            'duration_minutes' => 180,
            'metadata' => ['deposit_cents' => 5000],
        ]);

        $start = Carbon::now()->addDays(2)->setTime(10, 0);
        $end = (clone $start)->addHours(3);

        $slot = BookingSlot::create([
            'service_id' => $service->id,
            'facility_id' => $facility->id,
            'start_at' => $start,
            'end_at' => $end,
            'capacity' => 5,
            'available_count' => 4,
            'lock_version' => 1,
        ]);

        $booking = Booking::create([
            'slot_id' => $slot->id,
            'client_id' => $client->id,
            'status' => 'confirmed',
            'uuid' => (string) Str::uuid(),
        ]);

        return [$user, $booking];
    }
}
