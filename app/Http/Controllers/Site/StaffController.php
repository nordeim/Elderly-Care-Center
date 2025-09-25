<?php

namespace App\Http\Controllers\Site;

use App\Http\Controllers\Controller;
use App\Models\StaffMember;
use Illuminate\View\View;

class StaffController extends Controller
{
    public function __invoke(): View
    {
        $staff = StaffMember::query()->orderBy('full_name')->get();

        return view('pages.staff', compact('staff'));
    }
}
