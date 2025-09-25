<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\StaffMember;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class StaffController extends Controller
{
    public function index(): View
    {
        $staffMembers = StaffMember::orderBy('full_name')->paginate(15);

        return view('admin.staff.index', compact('staffMembers'));
    }

    public function create(): View
    {
        return view('admin.staff.create');
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $this->validated($request);
        StaffMember::create($data);

        return redirect()->route('admin.staff.index')->with('status', 'Staff member added.');
    }

    public function edit(StaffMember $staff): View
    {
        return view('admin.staff.edit', compact('staff'));
    }

    public function update(Request $request, StaffMember $staff): RedirectResponse
    {
        $staff->update($this->validated($request));

        return redirect()->route('admin.staff.index')->with('status', 'Staff member updated.');
    }

    public function destroy(StaffMember $staff): RedirectResponse
    {
        $staff->delete();

        return redirect()->route('admin.staff.index')->with('status', 'Staff member removed.');
    }

    private function validated(Request $request): array
    {
        return $request->validate([
            'full_name' => ['required', 'string', 'max:255'],
            'role' => ['nullable', 'string', 'max:255'],
            'bio' => ['nullable', 'string'],
            'photo_url' => ['nullable', 'url'],
            'certifications' => ['nullable', 'array'],
            'certifications.*' => ['string', 'max:255'],
        ]);
    }
}
