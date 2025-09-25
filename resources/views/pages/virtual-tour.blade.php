@extends('layouts.app')

@section('content')
    <div class="space-y-12">
        <section class="text-center space-y-4">
            <p class="text-sm uppercase tracking-wide text-indigo-600">See the space before you visit</p>
            <h1 class="text-3xl font-bold">Virtual Tour of {{ $facility->name ?? 'Our Daycare Community' }}</h1>
            <p class="text-lg text-slate-600 max-w-3xl mx-auto">
                Explore our welcoming environment, meet the caregivers, and get a feel for the daily experience we provide for seniors and their families.
            </p>
        </section>

        @if($heroMedia)
            <section>
                <x-media.player :sources="[
                    ['url' => $heroMedia->file_url, 'type' => $heroMedia->mime_type],
                ]" :captions="$heroMedia->captions_url" :poster="$heroMedia->conversions['thumbnail']['url'] ?? null">
                    Guided tour of our campus
                </x-media.player>
            </section>
        @endif

        @if($galleryMedia->isNotEmpty())
            <section>
                <h2 class="text-2xl font-semibold mb-4">Highlights from Around the Facility</h2>
                <div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                    @foreach ($galleryMedia as $media)
                        <article class="bg-white rounded-lg shadow p-4 space-y-3">
                            <x-media.player :sources="[
                                ['url' => $media->file_url, 'type' => $media->mime_type],
                            ]" :captions="$media->captions_url" :poster="$media->conversions['thumbnail']['url'] ?? null">
                                {{ $media->title ?? 'Facility highlight' }}
                            </x-media.player>
                            <p class="text-sm text-slate-600">{{ $media->title ?? 'Facility highlight' }}</p>
                        </article>
                    @endforeach
                </div>
            </section>
        @endif

        <section class="bg-white rounded-lg shadow p-6 space-y-4">
            <h2 class="text-2xl font-semibold">What Families Appreciate</h2>
            <ul class="grid gap-4 md:grid-cols-2">
                <li class="bg-slate-50 p-4 rounded">
                    <h3 class="font-semibold">Engaging Programs</h3>
                    <p class="text-sm text-slate-600">Daily activities designed for creativity, movement, and social connection.</p>
                </li>
                <li class="bg-slate-50 p-4 rounded">
                    <h3 class="font-semibold">Safety & Accessibility</h3>
                    <p class="text-sm text-slate-600">Secure entrances, accessible layouts, and attentive staff at every moment.</p>
                </li>
                <li class="bg-slate-50 p-4 rounded">
                    <h3 class="font-semibold">Clinical Oversight</h3>
                    <p class="text-sm text-slate-600">Nurses and therapists collaborate to personalize care plans.</p>
                </li>
                <li class="bg-slate-50 p-4 rounded">
                    <h3 class="font-semibold">Family Partnerships</h3>
                    <p class="text-sm text-slate-600">We work alongside families to ensure daily updates and long-term planning.</p>
                </li>
            </ul>
        </section>

        @if($testimonials->isNotEmpty())
            <section class="space-y-6">
                <h2 class="text-2xl font-semibold">Hear From Our Community</h2>
                <div class="grid gap-6 md:grid-cols-2">
                    @foreach ($testimonials as $testimonial)
                        <article class="bg-white rounded-lg shadow p-6 space-y-4">
                            @php
                                $featured = $testimonial->featuredMedia();
                            @endphp

                            @if($featured)
                                <x-media.player :sources="[
                                    ['url' => $featured->file_url, 'type' => $featured->mime_type],
                                ]" :captions="$featured->captions_url" :poster="$featured->conversions['thumbnail']['url'] ?? null">
                                    Video message from {{ optional($testimonial->client)->first_name ?? 'a family member' }}
                                </x-media.player>
                            @endif

                            <blockquote>
                                <p class="italic">“{{ $testimonial->content }}”</p>
                                <footer class="mt-4 text-sm text-slate-500">— {{ optional($testimonial->client)->first_name ?? 'Family Caregiver' }}</footer>
                            </blockquote>
                        </article>
                    @endforeach
                </div>
            </section>
        @endif

        <section class="text-center bg-indigo-50 border border-indigo-100 rounded-lg p-10 space-y-4">
            <h2 class="text-2xl font-semibold">Ready to See More?</h2>
            <p class="text-slate-600">Schedule an in-person visit or speak with our care team to customize a plan for your loved one.</p>
            <div class="flex flex-wrap justify-center gap-4">
                <a href="{{ route('booking.create') }}" class="px-6 py-3 bg-indigo-600 text-white rounded-md">Book a Visit</a>
                <a href="tel:+14155550100" class="px-6 py-3 border border-indigo-600 text-indigo-600 rounded-md">Call Our Team</a>
            </div>
        </section>
    </div>
@endsection
