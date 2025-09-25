@php
    $sources = $sources ?? [];
    $captions = $captions ?? null;
    $poster = $poster ?? null;
@endphp

<figure class="media-player">
    <video
        class="w-full rounded-lg shadow-sm"
        @if($poster) poster="{{ $poster }}" @endif
        controls
        playsinline
        preload="metadata"
    >
        @foreach ($sources as $source)
            <source src="{{ $source['url'] ?? '' }}" type="{{ $source['type'] ?? 'video/mp4' }}">
        @endforeach

        @if($captions)
            <track
                kind="captions"
                srclang="en"
                label="English"
                src="{{ $captions }}"
                default
            >
        @endif
    </video>
    <figcaption class="mt-2 text-sm text-slate-600">
        {{ $slot ?? '' }}
    </figcaption>
</figure>
