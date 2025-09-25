<?php

namespace App\Http\Controllers\Site;

use App\Http\Controllers\Controller;
use App\Models\Testimonial;
use Illuminate\View\View;

class TestimonialsController extends Controller
{
    public function __invoke(): View
    {
        $testimonials = Testimonial::query()->where('status', 'approved')->latest()->paginate(10);

        return view('pages.testimonials', compact('testimonials'));
    }
}
