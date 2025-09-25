@extends('layouts.app')

@section('content')
    <div class="max-w-xl mx-auto space-y-8">
        <header class="space-y-2 text-center">
            <p class="text-sm uppercase tracking-wide text-indigo-600">{{ __('Booking Deposit') }}</p>
            <h1 class="text-3xl font-bold">{{ __('Secure Your Visit') }}</h1>
            <p class="text-slate-600">{{ __('Complete the deposit below to confirm your booking.') }}</p>
        </header>

        <section class="bg-white shadow rounded-lg p-6 space-y-4" aria-labelledby="booking-summary">
            <h2 id="booking-summary" class="text-xl font-semibold">{{ __('Booking Summary') }}</h2>
            <dl class="grid grid-cols-1 gap-2 text-sm text-slate-600">
                <div>
                    <dt class="font-medium text-slate-500">{{ __('Service') }}</dt>
                    <dd>{{ optional($booking->slot->service)->name ?? __('Scheduled visit') }}</dd>
                </div>
                <div>
                    <dt class="font-medium text-slate-500">{{ __('Date & Time') }}</dt>
                    <dd>{{ optional($booking->slot)->start_at?->timezone(optional(auth()->user()->caregiverProfile)->timezone ?? config('app.timezone'))->format('M d, Y h:i A') ?? __('TBD') }}</dd>
                </div>
                <div>
                    <dt class="font-medium text-slate-500">{{ __('Deposit Amount') }}</dt>
                    <dd>{{ $currency }} {{ $amountFormatted }}</dd>
                </div>
            </dl>
        </section>

        <section class="bg-white shadow rounded-lg p-6 space-y-6" aria-labelledby="payment-form">
            <h2 id="payment-form" class="text-xl font-semibold">{{ __('Payment Details') }}</h2>
            <form id="stripe-deposit-form" class="space-y-4" data-client-secret="{{ $clientSecret }}" data-publishable-key="{{ $publishableKey }}">
                @csrf
                <div class="space-y-2">
                    <label for="card-element" class="block text-sm font-medium text-slate-700">{{ __('Card Information') }}</label>
                    <div id="card-element" class="rounded-md border border-slate-300 p-3" aria-live="polite" aria-label="{{ __('Card input') }}"></div>
                </div>
                <button type="submit" class="w-full inline-flex justify-center items-center px-4 py-2 bg-indigo-600 text-white rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:ring-offset-2">
                    {{ __('Pay Deposit') }}
                </button>
                <p id="payment-errors" class="text-sm text-red-600" role="alert" hidden></p>
            </form>
        </section>

        <footer class="text-center text-sm text-slate-500">
            <a href="{{ route('caregiver.dashboard') }}" class="text-indigo-600 hover:underline">{{ __('Return to dashboard') }}</a>
        </footer>
    </div>
@endsection

@push('scripts')
    <script src="https://js.stripe.com/v3/"></script>
    <script>
        document.addEventListener('DOMContentLoaded', () => {
            const form = document.querySelector('#stripe-deposit-form');
            if (!form) {
                return;
            }

            const clientSecret = form.dataset.clientSecret;
            const publishableKey = form.dataset.publishableKey;

            if (!clientSecret || !publishableKey) {
                console.error('Stripe client secret or publishable key missing.');
                return;
            }

            const stripe = Stripe(publishableKey);
            const elements = stripe.elements();
            const card = elements.create('card');
            card.mount('#card-element');

            const errorContainer = document.querySelector('#payment-errors');

            card.on('change', (event) => {
                if (event.error) {
                    errorContainer.textContent = event.error.message;
                    errorContainer.hidden = false;
                } else {
                    errorContainer.textContent = '';
                    errorContainer.hidden = true;
                }
            });

            form.addEventListener('submit', async (event) => {
                event.preventDefault();

                const { error } = await stripe.confirmCardPayment(clientSecret, {
                    payment_method: {
                        card,
                    },
                });

                if (error) {
                    errorContainer.textContent = error.message;
                    errorContainer.hidden = false;
                } else {
                    errorContainer.hidden = true;
                    window.location.href = '{{ route('caregiver.dashboard') }}?payment=success';
                }
            });
        });
    </script>
@endpush
