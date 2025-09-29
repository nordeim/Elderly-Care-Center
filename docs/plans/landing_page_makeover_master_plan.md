# Landing Page Makeover Master Plan

## Experience Vision
- **Goal**: Present Elderly Daycare Platform as a premier, compassionate service with a modern, trustworthy digital presence.
- **Emotion**: Warmth, reliability, and innovation balanced with clinical credibility.
- **Primary Caption**: *"Where compassionate care meets modern comfort for every family."*

## UX & Visual Principles
- **[ ] Human-centered storytelling**: Combine authentic photography/videography with concise copy to communicate trust.
- **[ ] Accessibility-first**: WCAG AA contrast, keyboard-friendly navigation, descriptive media alternatives.
- **[ ] Performance mindfulness**: Lazy-load video, optimize images, defer non-critical scripts.
- **[ ] Micro-interactions**: Subtle hover states, scroll-triggered fades, button pulses for key CTAs.

## Branding System
- **Color Palette**
  - **Trust Base**: `#1C3D5A` (deep blue for headers/nav), `#F7F9FC` (off-white background).
  - **Warm Accents**: `#F0A500` (gold highlight), `#FCDFA6` (soft amber backgrounds).
  - **Wellness Greens**: `#3D9A74` for success states and care assurances.
  - **Supportive Neutrals**: Slate grays `#334155`, `#64748B` for readable body text.
- **Typography**
  - Headings: `Playfair Display` (serif elegance) paired with `Inter` for body for modern legibility.
  - **[ ] Load fonts via Google Fonts with proper font-display.
- **Iconography & Imagery**
  - **[ ] Curate outline icons (phosphor/lucide) for services.
  - **[ ] Use lifestyle photography with seniors engaging in activities.
- **Motion Language**
  - **[ ] Hover scale (1.03) with drop shadow for cards.
  - **[ ] IntersectionObserver-triggered fade-in for section entrances.
  - **[ ] Reviews carousel auto-scroll with pause-on-hover.

## Section Blueprint (5+ Sections)
- **Section 1 — Header (Persistent)**
  - Navigation with logo, program links, and CTA button (`Book a Visit`).
  - Sticky behavior after scroll with glassmorphism blur.
  - **[ ] Implement mobile menu overlay with smooth slide-in animation.
- **Section 2 — Hero with Immersive Video**
  - Full-width background looping video of center activities, 60% dark overlay.
  - Headline, subhead, CTA pair (`Schedule a Tour`, `Watch Virtual Tour`).
  - Secondary CTA opens lightbox video player.
  - **[ ] Provide static fallback image for reduced-motion users.
- **Section 3 — Program Highlights**
  - Three-card layout (Day Programs, Wellness Services, Family Support) with shadcn `Card` components.
  - Animated icons, bullet benefits, link to detail pages.
  - **[ ] Include balanced color blocks alternating warm and neutral backgrounds.
- **Section 4 — "Care Philosophy" Story Strip**
  - Two-column section with imagery + copy describing mission pillars (Safety, Engagement, Dignity).
  - Timeline/steps component using shadcn `Steps`.
  - **[ ] Add animated counters for years of service, caregivers certified.
- **Section 5 — Testimonials Carousel (Horizontal Scroll)**
  - Auto-scrolling marquee of caregiver & family quotes.
  - Pause on hover, accessible controls (prev/next buttons, ARIA labels).
  - **[ ] Integrate shadcn `Carousel` or custom Embla-powered slider with Tailwind.
- **Section 6 — Facility Virtual Tour CTA**
  - Split layout with still image + overlay button launching virtual tour.
  - Secondary highlights (transportation, meals, safety tech) as badges.
  - **[ ] Provide animated gradient border around CTA card.
- **Section 7 — Footer**
  - Contact info, quick links, newsletter subscription form using shadcn `Input` + `Button`.
  - Certifications and association badges with grayscale hover colorization.
  - **[ ] Include social proof row (press logos) above footer line.

## Content & Copy Tasks
- **[ ] Draft concise value propositions for top 3 services.
- **[ ] Collect 5 authentic testimonial quotes (caregivers & family).
- **[ ] Outline mission pillars referencing regulatory compliance.
- **[ ] Curate media assets (video, imagery, icons) and confirm licensing.

## Technical Considerations
- **[ ] Integrate reduced-motion preference checks for animations.
- **[ ] Ensure hero video loads via optimized source (H.265/MP4 + WebM fallback).
- **[ ] Prefetch booking route for snappy CTA response.
- **[ ] Validate layout at breakpoints (320px, 768px, 1024px, 1440px).

## Validation Checklist
- **[ ] Accessibility audit (axe, keyboard navigation, alt text completeness).
- **[ ] Lighthouse performance > 90 on desktop/mobile.
- **[ ] Visual QA across Chrome, Safari, Firefox.
- **[ ] Content stakeholder review for tone & compliance.
