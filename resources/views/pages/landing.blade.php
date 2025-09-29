@extends('layouts.app')

@section('navigation')
    <header class="sticky top-0 z-40 w-full backdrop-glass" data-animate>
        <div class="mx-auto flex w-full max-w-6xl items-center justify-between px-6 py-4">
            <a href="{{ url('/') }}" class="flex items-center gap-2 text-lg font-semibold text-brand-navy">
                <span class="inline-flex h-10 w-10 items-center justify-center rounded-full bg-brand-gold text-brand-navy font-display text-xl">ED</span>
                <span>Elderly Daycare Platform</span>
            </a>
            <nav class="hidden items-center gap-8 text-sm font-medium text-brand-slate md:flex">
                <a href="{{ route('services.index') }}" class="transition hover:text-brand-navy">Programs</a>
                <a href="{{ route('staff.index') }}" class="transition hover:text-brand-navy">Our Team</a>
                <a href="{{ route('virtual-tour.show') }}" class="transition hover:text-brand-navy">Virtual Tour</a>
                <a href="{{ route('testimonials.index') }}" class="transition hover:text-brand-navy">Stories</a>
            </nav>
            <div class="hidden items-center gap-4 md:flex">
                <a href="{{ route('booking.create') }}" class="cta-button">Book a Visit</a>
            </div>
            <button
                class="inline-flex h-10 w-10 items-center justify-center rounded-full border border-brand-navy/20 text-brand-navy md:hidden"
                type="button"
                x-on:click="mobileMenuOpen = !mobileMenuOpen"
                aria-label="Toggle navigation"
                aria-expanded="false"
            >
                <span class="ph ph-list text-2xl"></span>
            </button>
        </div>
        <div
            x-cloak
            x-show="mobileMenuOpen"
            x-transition
            class="border-t border-brand-navy/10 bg-white/95 px-6 py-4 md:hidden"
        >
            <nav class="flex flex-col gap-4 text-base text-brand-slate">
                <a href="{{ route('services.index') }}" class="hover:text-brand-navy">Programs</a>
                <a href="{{ route('staff.index') }}" class="hover:text-brand-navy">Our Team</a>
                <a href="{{ route('virtual-tour.show') }}" class="hover:text-brand-navy">Virtual Tour</a>
                <a href="{{ route('testimonials.index') }}" class="hover:text-brand-navy">Stories</a>
                <a href="{{ route('booking.create') }}" class="cta-button text-center">Book a Visit</a>
            </nav>
        </div>
    </header>
@endsection

@section('content')
    <div class="flex flex-col gap-24">
        <section class="relative overflow-hidden" data-animate>
            <div class="absolute inset-0">
                <video
                    class="h-full w-full object-cover"
                    autoplay
                    muted
                    loop
                    playsinline
                    poster="{{ asset('images/hero-fallback.jpg') }}"
                >
                    <source src="{{ asset('media/hero.webm') }}" type="video/webm">
                    <source src="{{ asset('media/hero.mp4') }}" type="video/mp4">
                </video>
                <div class="hero-overlay"></div>
            </div>
            <div class="relative mx-auto flex w-full max-w-6xl flex-col gap-10 px-6 py-24 text-white md:flex-row md:items-center">
                <div class="max-w-xl space-y-6">
                    <p class="text-sm uppercase tracking-[0.4em] text-brand-amber">Trusted Senior Care</p>
                    <h1 class="text-4xl font-semibold leading-tight md:text-5xl">
                        Where compassionate care meets modern comfort for every family
                    </h1>
                    <p class="text-lg text-white/80">
                        Experience day programs designed to enrich, empower, and embrace the seniors you love with evidence-based activities and dedicated caregivers.
                    </p>
                    <div class="flex flex-wrap items-center gap-4">
                        <a href="{{ route('booking.create') }}" class="cta-button">Schedule a Tour</a>
                        <a href="{{ route('virtual-tour.show') }}" class="inline-flex items-center gap-2 rounded-full border border-white/40 px-6 py-3 text-base font-semibold text-white transition hover:bg-white/10">
                            <span class="ph ph-play"></span>
                            Watch Virtual Tour
                        </a>
                    </div>
                </div>
                <div class="grid w-full max-w-sm grid-cols-1 gap-4 rounded-3xl bg-white/10 p-6 text-white backdrop-blur md:grid-cols-3 md:max-w-none">
                    <div class="flex flex-col gap-2">
                        <span class="text-3xl font-semibold">{{ number_format($impactMetrics['years_in_service']) }}+</span>
                        <span class="text-sm text-white/70">Years providing joyful day programs</span>
                    </div>
                    <div class="flex flex-col gap-2">
                        <span class="text-3xl font-semibold">{{ number_format($impactMetrics['families_served']) }}</span>
                        <span class="text-sm text-white/70">Families supported with personalized plans</span>
                    </div>
                    <div class="flex flex-col gap-2">
                        <span class="text-3xl font-semibold">{{ number_format($impactMetrics['caregivers_certified']) }}</span>
                        <span class="text-sm text-white/70">Certified caregivers on our team</span>
                    </div>
                </div>
            </div>
        </section>

        <section class="mx-auto w-full max-w-6xl px-6" data-animate>
            <div class="flex flex-col gap-6 md:flex-row md:items-end md:justify-between">
                <div>
                    <p class="text-sm uppercase tracking-[0.3em] text-brand-amber">Programs</p>
                    <h2 class="text-3xl font-semibold text-brand-navy">Curated experiences for every family</h2>
                </div>
                <a href="{{ route('services.index') }}" class="inline-flex items-center gap-2 text-sm font-semibold text-brand-navy">
                    Explore all services
                    <span class="ph ph-arrow-right"></span>
                </a>
            </div>
            <div class="mt-10 grid gap-6 md:grid-cols-2 xl:grid-cols-3">
                @forelse ($services as $service)
                    <article class="card-elevated h-full p-8" data-animate>
                        <div class="flex items-center gap-3 text-sm font-semibold text-brand-amber">
                            <span class="ph ph-sparkle text-lg"></span>
                            Featured Program
                        </div>
                        <h3 class="mt-4 text-2xl font-semibold text-brand-navy">{{ $service->name }}</h3>
                        <p class="mt-3 text-sm text-brand-ash">{{ Str::limit($service->description, 160) }}</p>
                        <div class="mt-6 flex items-center gap-3 text-sm text-brand-slate">
                            <span class="inline-flex h-10 w-10 items-center justify-center rounded-full bg-brand-mist text-brand-navy">
                                <span class="ph ph-clock"></span>
                            </span>
                            <span>{{ $service->duration_minutes }} minute sessions</span>
                        </div>
                    </article>
                @empty
                    <p class="text-brand-slate">Our program highlights are being curated. Check back soon.</p>
                @endforelse
            </div>
        </section>

        <section class="bg-gradient-to-br from-brand-mist to-white py-20" data-animate>
            <div class="mx-auto grid w-full max-w-6xl items-center gap-12 px-6 md:grid-cols-2">
                <div class="space-y-6">
                    <p class="text-sm uppercase tracking-[0.3em] text-brand-amber">Care Philosophy</p>
                    <h2 class="text-3xl font-semibold text-brand-navy">Dignity-first care, enriched by community</h2>
                    <p class="text-brand-slate">
                        We partner with families to craft meaningful everyday experiences—combining clinical expertise, warm hospitality, and technology-enabled safety.
                    </p>
                    <ul class="space-y-4 text-brand-slate">
                        <li class="flex items-start gap-3">
                            <span class="mt-1 inline-flex h-6 w-6 items-center justify-center rounded-full bg-brand-amber/30 text-brand-amber">
                                <span class="ph ph-shield-check"></span>
                            </span>
                            Comprehensive safety protocols with registered nurses on-site.
                        </li>
                        <li class="flex items-start gap-3">
                            <span class="mt-1 inline-flex h-6 w-6 items-center justify-center rounded-full bg-brand-amber/30 text-brand-amber">
                                <span class="ph ph-heart"></span>
                            </span>
                            Daily enrichment activities tailored to cognitive and mobility needs.
                        </li>
                        <li class="flex items-start gap-3">
                            <span class="mt-1 inline-flex h-6 w-6 items-center justify-center rounded-full bg-brand-amber/30 text-brand-amber">
                                <span class="ph ph-handshake"></span>
                            </span>
                            Family touchpoints every step of the journey with transparent updates.
                        </li>
                    </ul>
                </div>
                <div class="card-elevated relative overflow-hidden p-8" data-animate>
                    <div class="absolute -top-16 -right-16 h-48 w-48 rounded-full bg-brand-amber/40 blur-3xl"></div>
                    <div class="relative space-y-6">
                        <h3 class="text-xl font-semibold text-brand-navy">Our Promise</h3>
                        <ol class="space-y-4 border-l-2 border-brand-amber/70 pl-6 text-brand-slate">
                            <li>
                                <h4 class="text-lg font-semibold text-brand-navy">Warm Welcome</h4>
                                Every member is greeted personally with a tailored onboarding experience.
                            </li>
                            <li>
                                <h4 class="text-lg font-semibold text-brand-navy">Engaged Days</h4>
                                We balance wellness, social, and creative sessions led by certified specialists.
                            </li>
                            <li>
                                <h4 class="text-lg font-semibold text-brand-navy">Empowered Families</h4>
                                Transparent communication with digital updates and caregiver training resources.
                            </li>
                        </ol>
                    </div>
                </div>
            </div>
        </section>

        <section class="bg-brand-navy py-20 text-white" data-testimonials data-animate>
            <div class="mx-auto flex w-full max-w-6xl flex-col gap-8 px-6">
                <div class="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
                    <div>
                        <p class="text-sm uppercase tracking-[0.3em] text-brand-amber">Testimonials</p>
                        <h2 class="text-3xl font-semibold">Families who trust us</h2>
                    </div>
                    <div class="flex gap-2">
                        <button type="button" class="h-3 w-3 rounded-full bg-white/40 opacity-40 transition" data-testimonials-dot aria-label="Go to previous testimonial"></button>
                        <button type="button" class="h-3 w-3 rounded-full bg-white/40 opacity-40 transition" data-testimonials-dot aria-label="Go to next testimonial"></button>
                        <button type="button" class="h-3 w-3 rounded-full bg-white/40 opacity-40 transition" data-testimonials-dot aria-label="Go to next testimonial"></button>
                    </div>
                </div>
                <div class="relative" data-testimonials-viewport>
                    <div class="testimonial-marquee">
                        @forelse ($testimonials as $testimonial)
                            <article class="card-elevated mx-4 flex w-80 shrink-0 flex-col gap-4 bg-white/95 p-6 text-brand-slate">
                                <div class="flex items-center gap-3 text-brand-amber">
                                    <span class="ph ph-quotes text-2xl"></span>
                                    <span class="text-sm font-semibold uppercase tracking-[0.3em]">Success Story</span>
                                </div>
                                <p class="text-sm italic text-brand-slate">“{{ Str::limit($testimonial->content, 180) }}”</p>
                                <div class="mt-4 text-xs uppercase tracking-[0.2em] text-brand-ash">
                                    {{ optional($testimonial->client)->first_name ?? 'Family Caregiver' }}
                                </div>
                            </article>
                        @empty
                            <p class="px-4 text-white/80">Testimonials are coming soon. Check back for stories from our families.</p>
                        @endforelse
                    </div>
                </div>
                <div class="mt-4 text-sm text-white/70">
                    Hover to pause. Stories auto-advance every few seconds and can be navigated with the dots.
                </div>
            </div>
        </section>

        <section class="mx-auto w-full max-w-6xl px-6" data-animate>
            <div class="grid gap-10 rounded-3xl bg-brand-mist p-10 md:grid-cols-[2fr,1fr]">
                <div class="space-y-4">
                    <p class="text-sm uppercase tracking-[0.3em] text-brand-amber">Virtual Tour</p>
                    <h2 class="text-3xl font-semibold text-brand-navy">Step inside from anywhere</h2>
                    <p class="text-brand-slate">
                        Explore our sensory rooms, wellness lounges, and technology-enabled safety systems. Schedule an in-person visit to feel the warmth first-hand.
                    </p>
                    <div class="flex flex-wrap gap-3">
                        <span class="inline-flex items-center gap-2 rounded-full bg-white px-3 py-1 text-sm text-brand-navy">
                            <span class="ph ph-car"></span>
                            Accessible transport
                        </span>
                        <span class="inline-flex items-center gap-2 rounded-full bg-white px-3 py-1 text-sm text-brand-navy">
                            <span class="ph ph-bowl-food"></span>
                            Chef-crafted meals
                        </span>
                        <span class="inline-flex items-center gap-2 rounded-full bg-white px-3 py-1 text-sm text-brand-navy">
                            <span class="ph ph-brain"></span>
                            Memory care support
                        </span>
                    </div>
                    <div class="flex gap-4">
                        <a href="{{ route('virtual-tour.show') }}" class="cta-button">Explore Virtual Tour</a>
                        <a href="{{ route('booking.create') }}" class="inline-flex items-center gap-2 rounded-full border border-brand-navy px-6 py-3 text-brand-navy transition hover:bg-brand-navy hover:text-white">
                            Plan a Visit
                            <span class="ph ph-arrow-right"></span>
                        </a>
                    </div>
                </div>
                <div class="relative overflow-hidden rounded-3xl">
                    <img src="{{ asset('images/virtual-tour-preview.jpg') }}" alt="Preview of Elderly Daycare facility" class="h-full w-full object-cover" loading="lazy">
                    <div class="absolute inset-0 bg-brand-navy/20"></div>
                </div>
            </div>
        </section>
    </div>
@endsection

@section('footer')
    <footer class="mt-24 bg-brand-navy py-16 text-white" data-animate>
        <div class="mx-auto grid w-full max-w-6xl gap-10 px-6 md:grid-cols-4">
            <div class="space-y-4">
                <span class="inline-flex h-12 w-12 items-center justify-center rounded-full bg-brand-gold text-brand-navy font-display text-xl">ED</span>
                <p class="text-sm text-white/70">Building inclusive communities where seniors thrive every day.</p>
            </div>
            <div class="space-y-3 text-sm">
                <h3 class="text-base font-semibold">Quick Links</h3>
                <a href="{{ route('services.index') }}" class="block text-white/80 hover:text-white">Programs</a>
                <a href="{{ route('staff.index') }}" class="block text-white/80 hover:text-white">Our Team</a>
                <a href="{{ route('virtual-tour.show') }}" class="block text-white/80 hover:text-white">Virtual Tour</a>
                <a href="{{ route('booking.create') }}" class="block text-white/80 hover:text-white">Book a Visit</a>
            </div>
            <div class="space-y-3 text-sm">
                <h3 class="text-base font-semibold">Contact</h3>
                <p class="text-white/80">123 Compassion Lane<br>San Francisco, CA</p>
                <a href="tel:+15551234567" class="block text-white/80 hover:text-white">(555) 123-4567</a>
                <a href="mailto:care@elderly-daycare.com" class="block text-white/80 hover:text-white">care@elderly-daycare.com</a>
            </div>
            <div class="space-y-4">
                <h3 class="text-base font-semibold">Newsletter</h3>
                <p class="text-sm text-white/70">Stay informed about caregiver resources, events, and new programs.</p>
                <form action="#" method="post" class="flex flex-col gap-3" aria-label="Newsletter subscription">
                    <label for="newsletter-email" class="sr-only">Email</label>
                    <input id="newsletter-email" type="email" placeholder="you@example.com" class="w-full rounded-full border border-white/30 bg-white/10 px-4 py-3 text-sm text-white placeholder:text-white/60 focus:border-white focus:outline-none" required>
                    <button type="submit" class="cta-button w-full">Subscribe</button>
                </form>
            </div>
        </div>
        <div class="mt-12 border-t border-white/10 pt-6 text-center text-xs text-white/60">
            © {{ now()->year }} Elderly Daycare Platform. All rights reserved.
        </div>
    </footer>
@endsection
