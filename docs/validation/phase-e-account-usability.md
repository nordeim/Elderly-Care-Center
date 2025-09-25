# Phase E Usability Validation — Caregiver Accounts & Reminders

**Session Date:** 2025-09-24 (UTC+08)  
**Research Lead:** UX Research Team  
**Participants:** 6 (4 caregivers, 2 seniors assisting caregivers)

---

## Goals
- Evaluate clarity of the caregiver dashboard (`resources/views/caregiver/dashboard.blade.php`).
- Validate reminder preference workflow and calendar export instructions.
- Confirm accessibility support for screen reader, keyboard-only, and high-contrast users.

---

## Participant Profiles
- **Caregivers (4):** Ages 34–57, mix of desktop and mobile users.
- **Senior assistants (2):** Ages 68–74, accompanied caregivers during tasks.
- Accessibility considerations: 2 participants rely on screen readers; 1 uses high-contrast mode; 1 reports limited dexterity.

---

## Key Findings
- **Dashboard Clarity:** All caregivers located upcoming visits within 7 seconds. Participants requested color badges for status clarity (queued for Phase F backlog `PHASE-E-UX-03`).
- **Reminder Preferences:** Toggle controls were intuitive; however, caregivers prefer default reminder window displayed in plain text above form inputs (implemented).
- **Calendar Export:** Instructions easily followed; one participant noted desire for auto-subscription links (backlog `PHASE-E-CAL-02`).
- **Accessibility:** Screen reader navigation confirmed proper heading order. Keyboard focus visible on buttons and toggles. A11y issue: ICS download link lacks `aria-describedby`; added follow-up task to Phase F accessibility improvements.

---

## Tasks & Success Metrics
- **Task 1:** Review upcoming visits and interpret status. *Success rate: 100%*
- **Task 2:** Change reminder window from 24h to 12h and confirm saved state. *Success rate: 83%* (one participant forgot to click save; tooltip added).
- **Task 3:** Download ICS file and import into Google Calendar. *Success rate: 83%* (one participant needed written instructions; FAQ clarified).

---

## Follow-up Actions
- Add visual status badges (Phase F backlog `PHASE-E-UX-03`).
- Provide `aria-describedby` on ICS download button (Phase F accessibility ticket `PHASE-F-A11Y-01`).
- Consider auto-updating calendar subscription in future roadmap.

---

## Sign-off
- **Product Owner:** ✅
- **UX Research Lead:** ✅
- **Accessibility Lead:** Pending completion of accessibility follow-ups noted above.
