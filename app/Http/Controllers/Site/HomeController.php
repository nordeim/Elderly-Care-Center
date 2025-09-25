<?php

namespace App\Http\Controllers\Site;

use App\Http\Controllers\Controller;
use App\Models\Service;
use App\Models\Testimonial;
use Illuminate\View\View;

class HomeController extends Controller
{
    public function __invoke(): View
    {
        $services = Service::query()->limit(4)->get();
        $testimonials = Testimonial::query()
            ->with(['client', 'media'])
            ->where('status', 'approved')
            ->latest()
            ->limit(3)
            ->get();

        return view('pages.home', compact('services', 'testimonials'));
    }
}
