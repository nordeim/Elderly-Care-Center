@extends('layouts.app')

@section('content')
    <div class="space-y-8">
        <header>
            <h1 class="text-3xl font-bold">Our Daycare Services</h1>
            <p class="mt-2 text-slate-600">Personalized programs designed to engage, nurture, and support seniors.</p>
        </header>

        <div class="grid gap-6 md:grid-cols-2">
            @forelse ($services as $service)
                <article class="bg-white p-6 rounded-lg shadow-sm">
                    <h2 class="text-xl font-semibold">{{ $service->name }}</h2>
                    <p class="mt-2 text-sm text-slate-600">{{ $service->description }}</p>
                    <p class="mt-4 text-sm"><strong>Duration:</strong> {{ $service->duration_minutes }} minutes</p>
                    <p class="text-sm"><strong>Location:</strong> {{ $service->facility?->name ?? 'Main Center' }}</p>
                </article>
            @empty
                <p>No services published yet. Please check back soon.</p>
            @endforelse
        </div>
    </div>
@endsection
