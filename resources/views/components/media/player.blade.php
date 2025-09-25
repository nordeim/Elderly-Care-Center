<figure class="media-player" x-data="mediaPlayer({ sources: {{ json_encode($sources ?? []) }}, captions: '{{ $captions ?? '' }}', poster: '{{ $poster ?? '' }}' })">
    <video
        x-ref="video"
        class="w-full rounded-lg shadow-sm"
        :poster="poster"
        controls
        playsinline
        preload="metadata"
    >
        <template x-for="source in sources" :key="source.url">
            <source :src="source.url" :type="source.type">
        </template>
        <track
            x-show="captions"
            kind="captions"
            srclang="en"
            label="English"
            :src="captions"
            default
        >
    </video>
    <figcaption class="mt-2 text-sm text-slate-600">
        <slot></slot>
    </figcaption>
</figure>

<script>
    document.addEventListener('alpine:init', () => {
        Alpine.data('mediaPlayer', ({ sources, captions, poster }) => ({
            sources,
            captions,
            poster,
        }));
    });
</script>
