<?php

namespace Database\Seeders;

use App\Models\MediaItem;
use App\Models\Testimonial;
use Illuminate\Database\Seeder;
use Carbon\Carbon;
use Illuminate\Support\Str;

class MediaSeeder extends Seeder
{
    public function run(): void
    {
        $uploadedAt = Carbon::now()->subDays(3);

        $hero = MediaItem::updateOrCreate(
            ['uuid' => '9c09f7e6-74ad-4d15-8d13-4c47cb4cf301'],
            [
                'file_url' => 'https://cdn.example.com/media/virtual-tour/hero.mp4',
                'mime_type' => 'video/mp4',
                'size_bytes' => 45_000_000,
                'conversions' => [
                    'thumbnail' => [
                        'url' => 'https://cdn.example.com/media/virtual-tour/hero-thumb.jpg',
                        'width' => 640,
                        'height' => 360,
                    ],
                    'video' => [[
                        'resolution' => '1080p',
                        'bitrate' => '4M',
                        'url' => 'https://cdn.example.com/media/virtual-tour/hero-1080p.mp4',
                    ]],
                ],
                'captions_url' => 'https://cdn.example.com/media/virtual-tour/hero-en.vtt',
                'attributes' => [
                    'category' => 'virtual-tour-hero',
                ],
                'status' => MediaItem::STATUS_READY,
                'uploaded_at' => $uploadedAt,
            ]
        );

        $galleryItems = collect([
            [
                'uuid' => 'aa8b2242-a962-4da2-bb75-0fd463afaa77',
                'file_url' => 'https://cdn.example.com/media/virtual-tour/common-area.mp4',
                'title' => 'Common Area Walkthrough',
            ],
            [
                'uuid' => '42e4c4d2-1a4c-4701-8a92-0a9066790f0f',
                'file_url' => 'https://cdn.example.com/media/virtual-tour/therapy-room.mp4',
                'title' => 'Therapy Room Overview',
            ],
            [
                'uuid' => 'c0b6a3bd-2481-4cb6-a726-42bf05d9b1ab',
                'file_url' => 'https://cdn.example.com/media/virtual-tour/garden.mp4',
                'title' => 'Sensory Garden',
            ],
        ])->map(function (array $item) use ($uploadedAt) {
            return MediaItem::updateOrCreate(
                ['uuid' => $item['uuid']],
                [
                    'file_url' => $item['file_url'],
                    'mime_type' => 'video/mp4',
                    'size_bytes' => 28_000_000,
                    'conversions' => [
                        'thumbnail' => [
                            'url' => Str::replace('.mp4', '-thumb.jpg', $item['file_url']),
                            'width' => 640,
                            'height' => 360,
                        ],
                        'video' => [[
                            'resolution' => '720p',
                            'bitrate' => '2M',
                            'url' => Str::replace('.mp4', '-720p.mp4', $item['file_url']),
                        ]],
                    ],
                    'captions_url' => Str::replace('.mp4', '-en.vtt', $item['file_url']),
                    'attributes' => [
                        'category' => 'virtual-tour-gallery',
                        'title' => $item['title'],
                    ],
                    'status' => MediaItem::STATUS_READY,
                    'uploaded_at' => $uploadedAt->copy()->addMinutes(5),
                ]
            );
        });

        $testimonialVideo = MediaItem::updateOrCreate(
            ['uuid' => '8c77356d-9745-471f-93f1-e55f0079f829'],
            [
                'file_url' => 'https://cdn.example.com/media/testimonials/family-message.mp4',
                'mime_type' => 'video/mp4',
                'size_bytes' => 32_000_000,
                'conversions' => [
                    'thumbnail' => [
                        'url' => 'https://cdn.example.com/media/testimonials/family-message-thumb.jpg',
                        'width' => 640,
                        'height' => 360,
                    ],
                    'video' => [[
                        'resolution' => '720p',
                        'bitrate' => '2M',
                        'url' => 'https://cdn.example.com/media/testimonials/family-message-720p.mp4',
                    ]],
                ],
                'captions_url' => 'https://cdn.example.com/media/testimonials/family-message-en.vtt',
                'attributes' => [
                    'category' => 'testimonial',
                ],
                'status' => MediaItem::STATUS_READY,
                'uploaded_at' => $uploadedAt->copy()->addMinutes(10),
            ]
        );

        $testimonial = Testimonial::query()
            ->where('content', 'The staff made my mom feel welcome from day one.')
            ->first();

        if ($testimonial) {
            $testimonial->media()->syncWithoutDetaching([
                $testimonialVideo->id => [
                    'role' => 'primary',
                    'position' => 0,
                ],
            ]);
        }
    }
}
