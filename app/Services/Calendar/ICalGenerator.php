<?php

namespace App\Services\Calendar;

use App\Models\Booking;
use App\Models\CaregiverProfile;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Str;

class ICalGenerator
{
    public function generate(CaregiverProfile $profile, Collection $bookings): string
    {
        $timezone = $profile->timezone ?? config('app.timezone', 'UTC');
        $lines = [
            'BEGIN:VCALENDAR',
            'VERSION:2.0',
            'PRODID:-//Elderly Daycare Platform//Calendar Export//EN',
            'CALSCALE:GREGORIAN',
            'METHOD:PUBLISH',
        ];

        foreach ($bookings as $booking) {
            $lines = array_merge($lines, $this->formatEvent($booking, $timezone));
        }

        $lines[] = 'END:VCALENDAR';

        return implode("\r\n", $lines) . "\r\n";
    }

    protected function formatEvent(Booking $booking, string $timezone): array
    {
        $slot = $booking->slot;
        $service = optional($slot)->service;
        $facility = optional($slot)->facility;

        $start = optional($slot)->start_at ? Carbon::parse($slot->start_at)->setTimezone($timezone) : null;
        $end = optional($slot)->end_at ? Carbon::parse($slot->end_at)->setTimezone($timezone) : null;

        $uid = $booking->uuid ?? sprintf('%s@elderlydaycare.local', Str::uuid());
        $summary = $service?->name ?? 'Elderly Daycare Visit';
        $description = trim(sprintf(
            "%s\nStatus: %s",
            $facility?->name ?? 'Facility TBD',
            ucfirst($booking->status)
        ));

        $lines = ['BEGIN:VEVENT'];
        $lines[] = sprintf('UID:%s', $this->escapeText($uid));

        if ($start) {
            $lines[] = sprintf('DTSTART;TZID=%s:%s', $timezone, $start->format('Ymd\THis'));
        }

        if ($end) {
            $lines[] = sprintf('DTEND;TZID=%s:%s', $timezone, $end->format('Ymd\THis'));
        }

        $lines[] = sprintf('SUMMARY:%s', $this->escapeText($summary));
        $lines[] = sprintf('DESCRIPTION:%s', $this->escapeText($description));

        if ($facility) {
            $location = trim(sprintf('%s, %s', $facility->name, data_get($facility->address, 'street', '')));
            $lines[] = sprintf('LOCATION:%s', $this->escapeText($location));
        }

        $lines[] = sprintf('DTSTAMP:%s', now()->setTimezone('UTC')->format('Ymd\THis\Z'));
        $lines[] = 'END:VEVENT';

        return $lines;
    }

    protected function escapeText(string $value): string
    {
        $escaped = str_replace(["\\", ",", ";", "\n"], ['\\\\', '\\,', '\\;', '\\n'], $value);

        return preg_replace('/[\r\n]+/', '\\n', $escaped);
    }
}
