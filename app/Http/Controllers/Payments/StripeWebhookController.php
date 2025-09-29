<?php

namespace App\Http\Controllers\Payments;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Payment;
use App\Services\Payments\StripeService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Stripe\Event;
use Stripe\Webhook;
use Symfony\Component\HttpFoundation\Response;
use Throwable;

class StripeWebhookController extends Controller
{
    public function __construct(private readonly StripeService $stripeService)
    {
    }

    public function __invoke(Request $request): Response
    {
        $payload = $request->getContent();
        $signature = $request->header('Stripe-Signature');
        $secret = config('payments.stripe.webhook_secret');

        try {
            $event = Webhook::constructEvent($payload, $signature, $secret);
        } catch (Throwable $exception) {
            Log::warning('Stripe webhook signature verification failed.', [
                'exception' => $exception->getMessage(),
            ]);

            return response()->json(['error' => 'signature_verification_failed'], 400);
        }

        $type = $event->type ?? '';

        if ($type === 'payment_intent.succeeded') {
            $this->handleSucceeded($event);
        } elseif ($type === 'payment_intent.payment_failed') {
            $this->handleFailed($event);
        } elseif ($type === 'charge.refunded') {
            $this->handleRefunded($event);
        } else {
            Log::info('Unhandled Stripe webhook event.', ['type' => $type]);
        }

        return response()->json(['status' => 'ok']);
    }

    public function handleSucceeded(Event $event): void
    {
        $intent = $event->data->object;
        $payment = Payment::where('stripe_payment_intent_id', $intent->id)->first();

        if (! $payment) {
            Log::warning('Payment intent succeeded but local record missing.', ['intent_id' => $intent->id]);

            return;
        }

        $this->stripeService->syncFromIntent($payment);
        $payment->update(['status' => Payment::STATUS_SUCCEEDED]);

        AuditLog::record(
            'payment.succeeded',
            $payment->booking?->client ?? $payment->booking?->creator ?? $payment->booking,
            $payment,
            ['intent_id' => $intent->id]
        );
    }

    public function handleFailed(Event $event): void
    {
        $intent = $event->data->object;
        $payment = Payment::where('stripe_payment_intent_id', $intent->id)->first();

        if (! $payment) {
            Log::warning('Payment intent failed but local record missing.', ['intent_id' => $intent->id]);

            return;
        }

        $payment->update(['status' => Payment::STATUS_CANCELLED]);

        AuditLog::record(
            'payment.failed',
            $payment->booking?->client ?? $payment->booking?->creator ?? $payment->booking,
            $payment,
            ['intent_id' => $intent->id]
        );
    }

    public function handleRefunded(Event $event): void
    {
        $charge = $event->data->object;
        $intentId = $charge->payment_intent ?? null;

        if (! $intentId) {
            Log::warning('Refund event missing intent reference.', ['charge_id' => $charge->id ?? null]);

            return;
        }

        $payment = Payment::where('stripe_payment_intent_id', $intentId)->first();

        if (! $payment) {
            Log::warning('Refund processed but local payment missing.', ['intent_id' => $intentId]);

            return;
        }

        $payment->update(['status' => Payment::STATUS_REFUNDED]);

        AuditLog::record(
            'payment.refunded',
            $payment->booking?->client ?? $payment->booking?->creator ?? $payment->booking,
            $payment,
            ['intent_id' => $intentId]
        );
    }
}
