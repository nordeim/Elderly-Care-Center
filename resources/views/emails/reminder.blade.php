@component('mail::message')
# {{ __('Upcoming Visit Reminder') }}

{{ __('Hello :name,', ['name' => $booking->client?->first_name ?? __('Caregiver')]) }}

{{ __('This is a friendly reminder of your scheduled visit.') }}

@component('mail::panel')
- **{{ __('Service') }}**: {{ $service?->name ?? __('Elderly Day Program') }}
- **{{ __('Date & Time') }}**: {{ $slot?->start_at?->timezone($timezone)->format('M d, Y h:i A') ?? __('TBD') }}
- **{{ __('Location') }}**: {{ $facility?->name ?? __('Assigned facility') }}
@endcomponent

@component('mail::button', ['url' => route('caregiver.dashboard')])
{{ __('View Dashboard') }}
@endcomponent

{{ __('Need to make a change?') }}
- **{{ __('Reschedule') }}**: {{ __('Contact us or use your dashboard to request a new time.') }}
- **{{ __('Cancel') }}**: {{ __('Please notify us at least 24 hours in advance.') }}

{{ __('If you have questions, reach out at :phone or :email.', [
    'phone' => '+1-415-555-0100',
    'email' => 'care@elderlydaycare.test',
]) }}

{{ __('Thank you for partnering with our care team!') }}

{{ config('app.name') }}
@endcomponent
