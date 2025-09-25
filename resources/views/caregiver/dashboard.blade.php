@extends('layouts.app')

@section('content')
    <div class="space-y-10 max-w-5xl mx-auto">
        <header class="space-y-2 text-center md:text-left">
            <p class="text-sm uppercase tracking-wide text-indigo-600">{{ __('Caregiver Portal') }}</p>
            <h1 class="text-3xl font-bold">{{ __('Your Dashboard') }}</h1>
            <p class="text-slate-600">{{ __('Review upcoming visits, adjust reminders, and access calendar exports for your caregiving schedule.') }}</p>
        </header>

        @if(session('status'))
            <div class="bg-emerald-50 border border-emerald-200 text-emerald-800 rounded-md px-4 py-3" role="status">
                {{ session('status') }}
            </div>
        @endif

        <section class="bg-white shadow rounded-lg p-6 space-y-4">
            <header class="flex items-center justify-between flex-wrap gap-4">
                <div>
                    <h2 class="text-xl font-semibold">{{ __('Upcoming Visits') }}</h2>
                    <p class="text-sm text-slate-500">{{ __('These bookings are scheduled for the future based on your timezone (:tz).', ['tz' => $timezone]) }}</p>
                </div>
                <a href="{{ route('caregiver.calendar.export') }}" class="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:ring-offset-2">
                    {{ __('Download Calendar (.ics)') }}
                </a>
            </header>

            @forelse ($upcomingBookings as $booking)
                <article class="border border-slate-200 rounded-md p-4 space-y-2">
                    <h3 class="text-lg font-semibold">
                        {{ optional($booking->slot->service)->name ?? __('Service') }}
                    </h3>
                    <dl class="grid grid-cols-1 md:grid-cols-2 gap-2 text-sm text-slate-600">
                        <div>
                            <dt class="font-medium text-slate-500">{{ __('Date & Time') }}</dt>
                            <dd>{{ optional($booking->slot)->start_at?->timezone($timezone)->format('M d, Y h:i A') ?? __('TBD') }}</dd>
                        </div>
                        <div>
                            <dt class="font-medium text-slate-500">{{ __('Location') }}</dt>
                            <dd>{{ optional($booking->slot->facility)->name ?? __('Assigned facility') }}</dd>
                        </div>
                        <div>
                            <dt class="font-medium text-slate-500">{{ __('Status') }}</dt>
                            <dd class="capitalize">{{ __($booking->status) }}</dd>
                        </div>
                        <div>
                            <dt class="font-medium text-slate-500">{{ __('Reminder Window') }}</dt>
                            <dd>{{ data_get($preferences, 'reminder_window_hours', 24) }} {{ __('hours prior') }}</dd>
                        </div>
                    </dl>
                </article>
            @empty
                <p class="text-sm text-slate-500">{{ __('No upcoming visits found. New bookings will appear here.') }}</p>
            @endforelse
        </section>

        <section class="bg-white shadow rounded-lg p-6 space-y-4">
            <h2 class="text-xl font-semibold">{{ __('Visit History') }}</h2>
            @forelse ($pastBookings as $booking)
                <details class="border border-slate-200 rounded-md p-4" @if($loop->first) open @endif>
                    <summary class="font-semibold cursor-pointer focus:outline-none focus-visible:ring-2 focus-visible:ring-indigo-400">
                        {{ optional($booking->slot->service)->name ?? __('Service') }} — {{ optional($booking->slot)->start_at?->timezone($timezone)->format('M d, Y h:i A') ?? __('TBD') }}
                    </summary>
                    <div class="mt-3 grid grid-cols-1 md:grid-cols-2 gap-2 text-sm text-slate-600">
                        <div>
                            <span class="font-medium text-slate-500">{{ __('Facility') }}:</span>
                            <span>{{ optional($booking->slot->facility)->name ?? __('Assigned facility') }}</span>
                        </div>
                        <div>
                            <span class="font-medium text-slate-500">{{ __('Status') }}:</span>
                            <span class="capitalize">{{ __($booking->status) }}</span>
                        </div>
                    </div>
                </details>
            @empty
                <p class="text-sm text-slate-500">{{ __('No past visits recorded.') }}</p>
            @endforelse
        </section>

        <section class="bg-white shadow rounded-lg p-6 space-y-4">
            <header>
                <h2 class="text-xl font-semibold">{{ __('Reminder & Contact Preferences') }}</h2>
                <p class="text-sm text-slate-500">{{ __('Update how and when you receive notifications for upcoming visits.') }}</p>
            </header>

            <form action="{{ route('caregiver.preferences.update') }}" method="post" class="space-y-4">
                @csrf
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <label class="flex flex-col gap-1 text-sm font-medium text-slate-600" for="preferred_contact_method">
                        {{ __('Preferred Contact Method') }}
                        <select id="preferred_contact_method" name="preferred_contact_method" class="rounded-md border-slate-300 focus:border-indigo-500 focus:ring-indigo-500">
                            <option value="email" @selected(old('preferred_contact_method', $profile->preferred_contact_method) === 'email')>{{ __('Email') }}</option>
                            <option value="sms" @selected(old('preferred_contact_method', $profile->preferred_contact_method) === 'sms')>{{ __('SMS') }}</option>
                        </select>
                    </label>

                    <label class="flex flex-col gap-1 text-sm font-medium text-slate-600" for="timezone">
                        {{ __('Timezone') }}
                        <input id="timezone" name="timezone" type="text" value="{{ old('timezone', $profile->timezone) }}" class="rounded-md border-slate-300 focus:border-indigo-500 focus:ring-indigo-500" placeholder="UTC">
                    </label>

                    <label class="flex items-center gap-2 text-sm font-medium text-slate-600">
                        <input type="checkbox" name="sms_opt_in" value="1" @checked(old('sms_opt_in', $profile->sms_opt_in)) class="rounded border-slate-300 text-indigo-600 focus:ring-indigo-500">
                        {{ __('Opt in to SMS reminders') }}
                    </label>

                    <label class="flex flex-col gap-1 text-sm font-medium text-slate-600" for="reminder_window_hours">
                        {{ __('Reminder Window (hours)') }}
                        <input id="reminder_window_hours" name="reminder_window_hours" type="number" min="1" max="168" value="{{ old('reminder_window_hours', data_get($preferences, 'reminder_window_hours', 24)) }}" class="rounded-md border-slate-300 focus:border-indigo-500 focus:ring-indigo-500">
                    </label>
                </div>

                <button type="submit" class="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:ring-offset-2">
                    {{ __('Save Preferences') }}
                </button>
            </form>
        </section>
    </div>
@endsection
