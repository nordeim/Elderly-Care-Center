<?php

namespace Tests\Feature\Media;

use App\Models\MediaItem;
use App\Models\Testimonial;
use Illuminate\Support\Str;
use Tests\TestCase;

class VirtualTourTest extends TestCase
{
    public function test_virtual_tour_page_displays_media_and_cta(): void
    {
        $heroMedia = MediaItem::create([
            'uuid' => (string) Str::uuid(),
            'title' => 'Campus Walkthrough',
            'file_url' => 'https://cdn.example.com/media/virtual-tour/hero.mp4',
            'mime_type' => 'video/mp4',
            'size_bytes' => 45_000_000,
            'conversions' => [
                'thumbnail' => [
                    'url' => 'https://cdn.example.com/media/virtual-tour/hero-thumb.jpg',
                    'width' => 640,
                    'height' => 360,
                ],
            ],
            'captions_url' => 'https://cdn.example.com/media/virtual-tour/hero-en.vtt',
            'attributes' => [
                'category' => 'virtual-tour-hero',
            ],
            'status' => MediaItem::STATUS_READY,
        ]);

        $galleryMedia = MediaItem::create([
            'uuid' => (string) Str::uuid(),
            'title' => 'Common Area Walkthrough',
            'file_url' => 'https://cdn.example.com/media/virtual-tour/common-area.mp4',
            'mime_type' => 'video/mp4',
            'size_bytes' => 28_000_000,
            'conversions' => [
                'thumbnail' => [
                    'url' => 'https://cdn.example.com/media/virtual-tour/common-area-thumb.jpg',
                    'width' => 640,
                    'height' => 360,
                ],
            ],
            'captions_url' => 'https://cdn.example.com/media/virtual-tour/common-area-en.vtt',
            'attributes' => [
                'category' => 'virtual-tour-gallery',
                'title' => 'Common Area Walkthrough',
            ],
            'status' => MediaItem::STATUS_READY,
        ]);

        $testimonial = Testimonial::create([
            'content' => 'The staff made my mom feel welcome from day one.',
            'status' => 'approved',
        ]);

        $testimonial->media()->attach($galleryMedia->id, [
            'role' => 'primary',
            'position' => 0,
        ]);

        $response = $this->get('/virtual-tour');

        $response->assertOk();
        $response->assertSee('Virtual Tour', false);
        $response->assertSee('Guided tour of our campus', false);
        $response->assertSee('Common Area Walkthrough', false);
        $response->assertSee('Book a Visit', false);
    }
}
