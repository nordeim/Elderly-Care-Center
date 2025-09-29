@props([
    'header' => null,
    'footer' => null,
])

@php
    $base = 'card-elevated flex flex-col rounded-3xl bg-white/95 shadow-xl-soft backdrop-blur transition-transform transition-shadow duration-300 ease-out';
@endphp

<div {{ $attributes->merge(['class' => $base]) }}>
    @isset($header)
        <div class="mb-4">
            {{ $header }}
        </div>
    @endisset

    <div class="flex-1">
        {{ $slot }}
    </div>

    @isset($footer)
        <div class="mt-6">
            {{ $footer }}
        </div>
    @endisset
</div>
