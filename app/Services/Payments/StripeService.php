<?php

namespace App\Services\Payments;

use App\Models\Booking;
use App\Models\Payment;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Log;
use Stripe\Exception\ApiErrorException;
use Stripe\StripeClient;
use Throwable;

class StripeService
{
    public function __construct(private readonly StripeClient $client)
    {
    }

    public function createDepositIntent(Booking $booking, int $amountCents, array $metadata = []): Payment
    {
        $payload = [
            'amount' => $amountCents,
            'currency' => config('payments.currency', 'usd'),
            'payment_method_types' => ['card'],
            'metadata' => array_merge([
                'booking_id' => $booking->id,
                'client_id' => $booking->client_id,
            ], $metadata),
        ];

        try {
            $intent = $this->client->paymentIntents->create($payload);
        } catch (ApiErrorException $exception) {
            Log::error('Stripe create intent failed.', [
                'booking_id' => $booking->id,
                'amount_cents' => $amountCents,
                'exception' => $exception->getMessage(),
            ]);

            throw $exception;
        }

        return Payment::create([
            'booking_id' => $booking->id,
            'stripe_payment_intent_id' => $intent->id,
            'status' => $intent->status ?? Payment::STATUS_PENDING,
            'amount_cents' => $amountCents,
            'currency' => config('payments.currency', 'usd'),
            'metadata' => $payload['metadata'],
        ]);
    }

    public function retrieveIntent(string $intentId)
    {
        return $this->client->paymentIntents->retrieve($intentId);
    }

    public function syncFromIntent(Payment $payment): Payment
    {
        $intent = $this->retrieveIntent($payment->stripe_payment_intent_id);

        $payment->fill([
            'status' => $intent->status ?? $payment->status,
            'receipt_url' => Arr::get($intent, 'charges.data.0.receipt_url', $payment->receipt_url),
            'metadata' => $intent->metadata ? $intent->metadata->toArray() : $payment->metadata,
        ])->save();

        return $payment;
    }

    public function handleRefund(Payment $payment, array $options = []): Payment
    {
        try {
            $this->client->refunds->create([
                'payment_intent' => $payment->stripe_payment_intent_id,
                'amount' => $options['amount_cents'] ?? null,
            ]);
        } catch (Throwable $exception) {
            Log::error('Stripe refund failed.', [
                'payment_id' => $payment->id,
                'exception' => $exception->getMessage(),
            ]);

            throw $exception;
        }

        $payment->update(['status' => Payment::STATUS_REFUNDED]);

        return $payment;
    }
}
