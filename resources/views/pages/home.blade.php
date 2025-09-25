@extends('layouts.app')

@section('content')
    <div class="space-y-12">
        <section class="text-center">
            <h1 class="text-3xl font-bold">Compassionate Daycare for Your Loved Ones</h1>
            <p class="mt-4 text-lg">Discover programs, trusted staff, and welcoming spaces designed for seniors.</p>
            <a href="{{ url('/book') }}" class="mt-6 inline-block bg-indigo-600 text-white px-6 py-3 rounded-md">Book a Visit</a>
        </section>

        <section>
            <h2 class="text-2xl font-semibold">Featured Services</h2>
            <div class="mt-6 grid gap-6 md:grid-cols-2">
                @foreach ($services as $service)
                    <article class="bg-white p-6 rounded-lg shadow">
                        <h3 class="text-xl font-semibold">{{ $service->name }}</h3>
                        <p class="mt-2 text-sm text-slate-600">{{ Str::limit($service->description, 140) }}</p>
                        <p class="mt-4 font-medium">Duration: {{ $service->duration_minutes }} minutes</p>
                    </article>
                @endforeach
            </div>
        </section>

        <section>
            <h2 class="text-2xl font-semibold">Testimonials</h2>
            <div class="mt-6 space-y-6">
                @foreach ($testimonials as $testimonial)
                    <blockquote class="bg-white p-6 rounded-lg shadow">
                        <p class="italic">“{{ $testimonial->content }}”</p>
                        <footer class="mt-4 text-sm text-slate-500">— {{ optional($testimonial->client)->first_name ?? 'Family Caregiver' }}</footer>
                    </blockquote>
                @endforeach
            </div>
        </section>
    </div>
@endsection
