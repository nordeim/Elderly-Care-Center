<?php

namespace App\Http\Controllers\Site;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\CaregiverProfile;
use App\Models\Service;
use App\Models\Testimonial;
use Illuminate\View\View;

class HomeController extends Controller
{
    public function index(): View
    {
        $services = Service::query()
            ->select(['id', 'name', 'description', 'duration_minutes'])
            ->latest()
            ->limit(6)
            ->get();

        $testimonials = Testimonial::query()
            ->with(['client', 'media'])
            ->where('status', 'approved')
            ->latest()
            ->limit(6)
            ->get();

        $impactMetrics = [
            'years_in_service' => 12,
            'families_served' => Booking::count(),
            'caregivers_certified' => CaregiverProfile::count(),
        ];

        return view('pages.landing', [
            'services' => $services,
            'testimonials' => $testimonials,
            'impactMetrics' => $impactMetrics,
        ]);
    }
}
