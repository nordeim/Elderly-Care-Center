<?php

namespace App\Http\Controllers\Site;

use App\Http\Controllers\Controller;
use App\Models\Facility;
use App\Models\MediaItem;
use App\Models\Testimonial;
use Illuminate\View\View;

class VirtualTourController extends Controller
{
    public function __invoke(): View
    {
        $facility = Facility::query()->first();

        $heroMedia = MediaItem::query()
            ->where('status', MediaItem::STATUS_READY)
            ->where('attributes->category', 'virtual-tour-hero')
            ->first();

        $galleryMedia = MediaItem::query()
            ->where('status', MediaItem::STATUS_READY)
            ->where('attributes->category', 'virtual-tour-gallery')
            ->orderByDesc('uploaded_at')
            ->limit(6)
            ->get();

        $testimonials = Testimonial::query()
            ->with(['client', 'media'])
            ->where('status', 'approved')
            ->orderByDesc('updated_at')
            ->limit(6)
            ->get();

        return view('pages.virtual-tour', [
            'facility' => $facility,
            'heroMedia' => $heroMedia,
            'galleryMedia' => $galleryMedia,
            'testimonials' => $testimonials,
        ]);
    }
}
