<?php

return [
    'disk' => env('MEDIA_DISK', 's3'),
    'bucket' => env('MEDIA_BUCKET', 'elderly-daycare-media'),
    'prefix' => env('MEDIA_PREFIX', 'uploads/'),

    'signed_url' => [
        'expiry_seconds' => env('MEDIA_SIGNED_URL_EXPIRY', 600),
        'max_upload_size' => env('MEDIA_MAX_UPLOAD_SIZE', 200 * 1024 * 1024), // 200 MB
    ],

    'transcoding' => [
        'profiles' => [
            'default' => [
                'video' => [
                    ['resolution' => '1080p', 'bitrate' => '4M'],
                    ['resolution' => '720p', 'bitrate' => '2M'],
                ],
                'audio' => [
                    ['bitrate' => '128k'],
                ],
            ],
        ],
        'thumbnail' => [
            'width' => 640,
            'height' => 360,
            'seconds_offset' => 3,
        ],
    ],

    'virus_scanning' => [
        'enabled' => env('MEDIA_VIRUS_SCANNING', true),
        'script_path' => base_path('ops/scripts/scan-media.sh'),
    ],
];
