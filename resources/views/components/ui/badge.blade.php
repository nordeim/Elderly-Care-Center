@props([
    'variant' => 'default',
])

@php
    $base = 'inline-flex items-center rounded-full border px-3 py-1 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2';

    $variants = [
        'default' => 'border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80',
        'secondary' => 'border-transparent bg-brand-mist text-brand-navy hover:bg-brand-mist/80',
        'outline' => 'border-border text-brand-slate hover:bg-brand-mist/60',
    ];

    $class = collect([
        $base,
        $variants[$variant] ?? $variants['default'],
    ])->implode(' ');
@endphp

<span {{ $attributes->merge(['class' => $class]) }}>
    {{ $slot }}
</span>
