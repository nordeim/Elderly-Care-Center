@extends('layouts.app')

@section('content')
    <div class="max-w-4xl mx-auto space-y-8">
        <header class="space-y-2">
            <p class="text-sm uppercase tracking-wide text-indigo-600">{{ __('Calendar Export') }}</p>
            <h1 class="text-3xl font-bold">{{ __('Sync Visits to Your Calendar') }}</h1>
            <p class="text-slate-600">{{ __('Download an ICS file or follow the instructions below to subscribe to your caregiver visits. Dates and times are shown in your timezone (:tz).', ['tz' => $profile->timezone ?? config('app.timezone')]) }}</p>
        </header>

        @if ($bookings->isEmpty())
            <div class="bg-white border border-slate-200 rounded-lg p-6">
                <p class="text-sm text-slate-500">{{ __('No bookings available to export yet. Once visits are scheduled, they will appear here.') }}</p>
            </div>
        @else
            <section class="bg-white border border-slate-200 rounded-lg p-6 space-y-4">
                <h2 class="text-xl font-semibold">{{ __('Download Your Calendar File') }}</h2>
                <p class="text-sm text-slate-600">{{ __('Use the button below to download an ICS file that can be imported into Google Calendar, Outlook, or Apple Calendar.') }}</p>
                <a href="{{ $downloadUrl }}" class="inline-flex items-center gap-2 px-5 py-3 bg-indigo-600 text-white rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:ring-offset-2">
                    {{ __('Download .ics File') }}
                </a>
            </section>

            <section class="bg-white border border-slate-200 rounded-lg p-6 space-y-4">
                <h2 class="text-xl font-semibold">{{ __('How to Import') }}</h2>
                <div class="grid gap-4 md:grid-cols-2 text-sm text-slate-600">
                    <div>
                        <h3 class="font-semibold text-slate-800">{{ __('Google Calendar (Web)') }}</h3>
                        <ol class="list-decimal ml-4 space-y-1">
                            <li>{{ __('Open Google Calendar and select **Other calendars → Import**.') }}</li>
                            <li>{{ __('Choose the downloaded ICS file and the calendar to import to.') }}</li>
                            <li>{{ __('Select **Import** to finish.') }}</li>
                        </ol>
                    </div>
                    <div>
                        <h3 class="font-semibold text-slate-800">{{ __('Outlook (Desktop)') }}</h3>
                        <ol class="list-decimal ml-4 space-y-1">
                            <li>{{ __('Open Outlook and choose **File → Open & Export → Import/Export**.') }}</li>
                            <li>{{ __('Select **Import an iCalendar (.ics)** and locate the downloaded file.') }}</li>
                            <li>{{ __('Choose whether to merge with your calendar or open as a new calendar.') }}</li>
                        </ol>
                    </div>
                </div>
            </section>

            <section class="bg-white border border-slate-200 rounded-lg p-6 space-y-4">
                <h2 class="text-xl font-semibold">{{ __('Frequently Asked Questions') }}</h2>
                <details class="border border-slate-200 rounded-md p-4">
                    <summary class="font-semibold cursor-pointer focus:outline-none focus-visible:ring-2 focus-visible:ring-indigo-400">{{ __('Will new visits update automatically?') }}</summary>
                    <p class="mt-2 text-sm text-slate-600">{{ __('Download a fresh ICS file whenever new visits are scheduled. Auto-updating subscriptions will be available in a future release.') }}</p>
                </details>
                <details class="border border-slate-200 rounded-md p-4">
                    <summary class="font-semibold cursor-pointer focus:outline-none focus-visible:ring-2 focus-visible:ring-indigo-400">{{ __('I imported twice—why do I see duplicates?') }}</summary>
                    <p class="mt-2 text-sm text-slate-600">{{ __('Most calendar apps add events each time you import. Remove the previous import before uploading an updated file to avoid duplicates.') }}</p>
                </details>
                <details class="border border-slate-200 rounded-md p-4">
                    <summary class="font-semibold cursor-pointer focus:outline-none focus-visible:ring-2 focus-visible:ring-indigo-400">{{ __('Need help?') }}</summary>
                    <p class="mt-2 text-sm text-slate-600">{{ __('Contact our care team at :phone or :email for assistance.', ['phone' => '+1-415-555-0100', 'email' => 'care@elderlydaycare.test']) }}</p>
                </details>
            </section>
        @endif

        <footer class="text-sm text-slate-500">
            <a href="{{ route('caregiver.dashboard') }}" class="text-indigo-600 hover:underline">{{ __('Back to dashboard') }}</a>
        </footer>
    </div>
@endsection
