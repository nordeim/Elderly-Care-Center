<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\ServiceRequest;
use App\Models\Facility;
use App\Models\Service;
use Illuminate\Http\RedirectResponse;
use Illuminate\View\View;

class ServiceController extends Controller
{
    public function index(): View
    {
        $services = Service::with('facility')->orderBy('name')->paginate(15);

        return view('admin.services.index', compact('services'));
    }

    public function create(): View
    {
        $facilities = Facility::orderBy('name')->pluck('name', 'id');

        return view('admin.services.create', compact('facilities'));
    }

    public function store(ServiceRequest $request): RedirectResponse
    {
        Service::create($request->validated());

        return redirect()->route('admin.services.index')->with('status', 'Service created successfully.');
    }

    public function edit(Service $service): View
    {
        $facilities = Facility::orderBy('name')->pluck('name', 'id');

        return view('admin.services.edit', compact('service', 'facilities'));
    }

    public function update(ServiceRequest $request, Service $service): RedirectResponse
    {
        $service->update($request->validated());

        return redirect()->route('admin.services.index')->with('status', 'Service updated successfully.');
    }

    public function destroy(Service $service): RedirectResponse
    {
        $service->delete();

        return redirect()->route('admin.services.index')->with('status', 'Service removed.');
    }
}
