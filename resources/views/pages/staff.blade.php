@extends('layouts.app')

@section('content')
    <div class="space-y-8">
        <header>
            <h1 class="text-3xl font-bold">Meet Our Care Team</h1>
            <p class="mt-2 text-slate-600">Compassionate professionals dedicated to every guest's wellbeing.</p>
        </header>

        <div class="grid gap-6 md:grid-cols-2">
            @forelse ($staff as $member)
                <article class="bg-white p-6 rounded-lg shadow-sm">
                    <div class="flex items-center space-x-4">
                        @if ($member->photo_url)
                            <img src="{{ $member->photo_url }}" alt="{{ $member->full_name }}" class="h-16 w-16 rounded-full object-cover" />
                        @endif
                        <div>
                            <h2 class="text-xl font-semibold">{{ $member->full_name }}</h2>
                            <p class="text-sm text-slate-500">{{ $member->role }}</p>
                        </div>
                    </div>
                    <p class="mt-4 text-sm text-slate-600">{{ $member->bio }}</p>
                    @if (!empty($member->certifications))
                        <ul class="mt-4 space-y-1 text-sm">
                            @foreach ($member->certifications as $cert)
                                <li>• {{ $cert }}</li>
                            @endforeach
                        </ul>
                    @endif
                </article>
            @empty
                <p>No staff profiles yet. Please check back soon.</p>
            @endforelse
        </div>
    </div>
@endsection
