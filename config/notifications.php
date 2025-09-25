<?php

return [
    'channels' => [
        'email' => [
            'driver' => env('NOTIFICATIONS_EMAIL_DRIVER', 'mail'),
        ],
        'sms' => [
            'driver' => env('NOTIFICATIONS_SMS_DRIVER', 'vonage'),
            'from' => env('NOTIFICATIONS_SMS_FROM', null),
        ],
    ],

    'queues' => [
        'notifications' => env('NOTIFICATIONS_QUEUE', 'notifications'),
    ],

    'reminders' => [
        'default_window_hours' => env('NOTIFICATIONS_REMINDER_WINDOW_HOURS', 24),
        'quiet_hours' => [
            'start' => env('NOTIFICATIONS_QUIET_HOURS_START', '21:00'),
            'end' => env('NOTIFICATIONS_QUIET_HOURS_END', '08:00'),
        ],
        'max_attempts' => env('NOTIFICATIONS_MAX_ATTEMPTS', 3),
        'retry_backoff_seconds' => env('NOTIFICATIONS_RETRY_BACKOFF', '60,300,900'),
    ],

    'feature_flags' => [
        'simulate_delivery' => env('NOTIFICATIONS_SIMULATE_DELIVERY', false),
    ],
];
