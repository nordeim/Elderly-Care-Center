# Phase C Validation Plan — Accessibility & Experience

## Objectives

- Confirm public discovery pages and booking flow meet WCAG 2.1 AA baseline.
- Validate admin booking inbox usability for operations staff.
- Capture user feedback from caregiver + elder sessions to feed Phase D enhancements.

## Test Participants

- 3 family caregivers (persona: Daughter/Primary Decision Maker)
- 1 daycare staff operator (persona: Operations Coordinator)
- 1 elderly client (persona: Day Program Visitor)

## Session Outline

1. Guided scenario: discover services, view staff bios, initiate booking.
2. Complete booking request, confirm confirmation messaging.
3. Admin scenario: review booking inbox, confirm and cancel sample bookings.
4. Accessibility spot checks using screen reader + keyboard only navigation.

## Tools & Evidence

- Automated axe scan (CI) — capture results in pipeline artifacts.
- Manual audit using `docs/accessibility/manual-audit-template.md`.
- Session recordings (with consent) stored in secure drive.
- Survey responses captured via Typeform (placeholder link).

## Issues Tracking

- Log all defects in issue tracker with labels `phase-c`, `accessibility`, `usability`.
- Prioritize Critical/High issues for Phase C fix; medium/low fed into Phase D backlog.

## Acceptance Criteria

- No Critical/High severity accessibility defects open.
- AxE CI scan free of violations in key flows.
- Booking flow completion rate ≥ 80% in moderated sessions.
- Admin operator successfully updates booking status without assistance.

## Sign-off Checklist

- **Product Owner:** Validates user feedback addressed.
- **QA Lead:** Confirms test evidence stored and accessible.
- **Accessibility Lead:** Signs off manual audit results.
- **Operations Lead:** Confirms staff training plan updated.
