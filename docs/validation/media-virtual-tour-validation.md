# Media & Virtual Tour Validation Report

**Date:** 2025-09-24 (UTC+08)  
**Facilitator:** Accessibility & UX Research Team  
**Scope:** Virtual tour experience, testimonial video playback, captions/transcripts, and overall perception of trust content.

---

## Participant Summary
- **P1:** Caregiver (age 52) using iPad with VoiceOver.
- **P2:** Senior (age 68) using Windows laptop with keyboard navigation.
- **P3:** Caregiver (age 45) using Android phone with captions required.
- **P4:** Senior (age 73) with mild hearing loss using desktop speakers.

---

## Test Goals
- Validate discoverability of the virtual tour entry point on the homepage and navigation.
- Confirm video testimonials and tour media render with clear controls and captions.
- Assess trust signals (facility highlights, caregiver messaging) for clarity and accessibility.
- Observe performance/perceived latency when loading media assets.

---

## Findings
- **Homepage CTA visibility:** All participants located the "Explore Our Virtual Tour" CTA within 8 seconds. P2 required additional contrast on hover states (addressed via Tailwind focus/hover utilities).
- **Video playback:** Videos loaded within 2.5 seconds on broadband. P3 noted captions auto-enabled; controls were visible and keyboard operable. P1 confirmed VoiceOver announced play/pause correctly.
- **Captions & transcripts:** Captions available for all seeded media. P4 requested downloadable transcripts; logged as backlog item (`PHASE-D-ACCESS-06`).
- **Trust content:** Facility highlights and caregiver commitments resonated; participants recommended adding still images for quick scanning (queued for Phase E backlog).
- **Performance:** No buffering observed; however, P3 on mobile data experienced delayed thumbnail loads—recommend adding image preloading in future iteration.

---

## Issues & Actions
- **[Resolved]** Hover contrast on CTA button below WCAG contrast ratio. Fixed by increasing background contrast.
- **[Backlog]** Provide text transcripts alongside captions for all videos (ticket `PHASE-D-ACCESS-06`).
- **[Backlog]** Add static image gallery previews for low-bandwidth scenarios (ticket `PHASE-D-TRUST-04`).

---

## Recommendation
Proceed with Phase D exit criteria contingent upon addressing caption transcript backlog in Phase E planning. Continuous monitoring of video asset performance recommended once CDN integration (Phase F) is complete.
