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
                        <p class="mt-2 text-sm text-slate-600">{{ \Illuminate\Support\Str::limit($service->description, 140) }}</p>
                        <p class="mt-4 font-medium">Duration: {{ $service->duration_minutes }} minutes</p>
                    </article>
                @endforeach
            </div>
        </section>

        <section>
            <h2 class="text-2xl font-semibold">Testimonials</h2>
            <div class="mt-6 space-y-6">
                @foreach ($testimonials as $testimonial)
                    <article class="bg-white p-6 rounded-lg shadow space-y-4">
                        @php
                            $featured = $testimonial->featuredMedia();
                        @endphp

                        @if($featured)
                            <x-media.player :sources="[
                                ['url' => $featured->file_url, 'type' => $featured->mime_type],
                            ]" :captions="$featured->captions_url" :poster="$featured->conversions['thumbnail']['url'] ?? null">
                                Video testimonial from our community
                            </x-media.player>
                        @endif

                        <blockquote>
                            <p class="italic">“{{ $testimonial->content }}”</p>
                            <footer class="mt-4 text-sm text-slate-500">— {{ optional($testimonial->client)->first_name ?? 'Family Caregiver' }}</footer>
                        </blockquote>
                    </article>
                @endforeach
            </div>
            <div class="mt-8 text-center">
                <a href="{{ route('virtual-tour.show') }}" class="inline-flex items-center gap-2 px-6 py-3 bg-indigo-600 text-white rounded-md">
                    Explore Our Virtual Tour
                </a>
            </div>
        </section>
    </div>
@endsection
