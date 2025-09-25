<?php

namespace App\Http\Controllers\Site;

use App\Http\Controllers\Controller;
use App\Models\Service;
use Illuminate\View\View;

class ServicesController extends Controller
{
    public function __invoke(): View
    {
        $services = Service::with('facility')->orderBy('name')->get();

        return view('pages.services', compact('services'));
    }
}
