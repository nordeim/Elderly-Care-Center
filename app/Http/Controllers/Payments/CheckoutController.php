<?php

namespace App\Http\Controllers\Payments;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\CaregiverProfile;
use App\Models\Payment;
use App\Services\Payments\StripeService;
use Illuminate\Contracts\Auth\Authenticatable;
use Illuminate\Contracts\View\View;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Response;
use Throwable;

class CheckoutController extends Controller
{
    public function __construct(private readonly StripeService $stripeService)
    {
        $this->middleware(['auth']);
    }

    public function show(Request $request, Booking $booking): View|Response
    {
        Gate::authorize('access-caregiver');

        $profile = $this->resolveProfile($request->user());

        if ($booking->client_id !== $profile->client_id) {
            abort(403, 'Unauthorized booking access.');
        }

        $amountCents = $this->determineDepositAmount($booking);

        $payment = Payment::where('booking_id', $booking->id)
            ->whereIn('status', [
                Payment::STATUS_PENDING,
                Payment::STATUS_REQUIRES_ACTION,
            ])
            ->latest()
            ->first();

        if (! $payment) {
            [$payment, $intentSecret] = $this->createIntent($booking, $amountCents);
        } else {
            $intentSecret = $this->syncIntent($payment);
        }

        return view('payments.deposit', [
            'booking' => $booking,
            'payment' => $payment,
            'amountCents' => $amountCents,
            'amountFormatted' => number_format($amountCents / 100, 2),
            'currency' => strtoupper(config('payments.currency', 'USD')),
            'publishableKey' => config('payments.stripe.publishable_key'),
            'clientSecret' => $intentSecret,
        ]);
    }

    protected function determineDepositAmount(Booking $booking): int
    {
        $default = (int) config('payments.default_deposit_cents', 1000);
        $servicePrice = optional($booking->slot?->service)->metadata['deposit_cents'] ?? null;

        return (int) ($servicePrice ?? $default);
    }

    protected function createIntent(Booking $booking, int $amountCents): array
    {
        try {
            $intent = $this->stripeService->createDepositIntent($booking, $amountCents);
            $secret = $this->stripeService->retrieveIntent($intent->stripe_payment_intent_id)->client_secret ?? null;

            return [$intent, $secret];
        } catch (Throwable $exception) {
            Log::error('Unable to create Stripe payment intent.', [
                'booking_id' => $booking->id,
                'exception' => $exception->getMessage(),
            ]);

            abort(500, 'Unable to start payment at this time.');
        }
    }

    protected function syncIntent(Payment $payment): ?string
    {
        try {
            $intent = $this->stripeService->syncFromIntent($payment);
            $stripeIntent = $this->stripeService->retrieveIntent($payment->stripe_payment_intent_id);

            return $stripeIntent->client_secret ?? null;
        } catch (Throwable $exception) {
            Log::error('Unable to synchronize Stripe payment intent.', [
                'payment_id' => $payment->id,
                'exception' => $exception->getMessage(),
            ]);

            return null;
        }
    }

    protected function resolveProfile(?Authenticatable $user): CaregiverProfile
    {
        $profile = optional($user)->caregiverProfile;

        if (! $profile) {
            abort(403, 'Caregiver profile not found.');
        }

        return $profile;
    }
}
