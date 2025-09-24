## 1. Concept, Vision & UX Blueprint

### 1.1 Guiding Principles & Design Philosophy

For a website serving older adults, caregivers, and families, the UX must emphasize:

* **Accessibility & readability**: large fonts, high contrast, ample spacing, clear interactive elements
* **Simplicity & clarity**: minimal clutter, clear navigation, no cognitive overload
* **Emotional reassurance & trust**: warm images, human faces, testimonials, staff profiles
* **Ease of action**: booking, inquiry, video viewing with minimal friction
* **Responsiveness & mobile first**: many users will access via tablets or phones
* **Progressive enhancement**: mimic traditional websites for all users, but layering interactivity (via Livewire / Alpine) for enhanced UX
* **Scalable modular structure**: as services grow, new content/pages can be added with minimal refactor

Design inspirations:

* Many adult day services / senior service sites focus on clearly laying out services, staff, FAQs, and contact forms. ([IlluminAge Communication Partners][1])
* A design with large hero images (showing real people), section anchors to “Services”, “Programs”, “Videos”, “Book a Visit”, “Resources / Caregiver Info”
* Strong emphasis on **accessibility compliance**: WCAG 2.1 A/AA, skip‑to-content, aria labels, alt texts etc. ([IlluminAge Communication Partners][2])

### 1.2 Personas & Key User Journeys

**Primary personas / audiences:**

| Persona                            | Needs / Goals                                                                  | Key Tasks                                                                                   |
| ---------------------------------- | ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------- |
| Family caregiver (adult child)     | Quickly understand the services, check eligibility, see schedule, book a visit | Browse “Services”, view “Videos / gallery”, check availability, complete booking or contact |
| Prospective adult client           | Understand daily activities, see what to expect, view gallery/videos           | View “A Day in Our Center”, staff intro, guided tour video, FAQs                            |
| Referral agencies / social workers | Verify credentials, view program structure, access resources                   | View “About Us”, accreditation, staff qualifications, downloadable resources                |
| Admin / internal staff             | Manage bookings, upload videos, manage content                                 | Admin dashboard, content CMS, reports                                                       |

**Key user flows:**

1. **From home → service page → check schedule → book a slot / contact**
2. **Watch video / virtual tour → decide → fill inquiry / booking form**
3. **Access caregiver resources (PDFs, FAQs, blog posts)**
4. **View staff profiles / meet the team → trust building**
5. **Admin logs in → sees dashboard → manage bookings, manage content, view analytics**

### 1.3 Site Map & Content Model

**Top-level pages / sections:**

* Home
* About Us

  * Mission, Vision
  * Facility Tour / Virtual Walkthrough (video + photos)
  * Staff & Care Team
  * Accreditation / Certifications
* Services / Programs

  * Daily Activities (schedule)
  * Therapeutic Programs
  * Memory Care / Dementia Support
  * Transportation
  * Meals / Nutrition
* Booking / Visit

  * Check Availability
  * Book a Visit / Enrollment
  * Tour Request Form
* Media / Gallery

  * Videos
  * Photo Gallery
  * Testimonials & Stories
* Caregiver Resources

  * FAQs
  * PDFs / Downloads
  * Blog / News
  * Glossary / Terms
* Contact Us
* Login (for staff/admin)
* Privacy Policy, Accessibility Policy

**Data / Content Entities (with relationships):**

* **Service** (name, description, schedule, images, video)
* **Booking Slot / Session** (date, time, capacity, status)
* **Staff Member** (name, role, bio, photo, credentials)
* **Video / Media** (title, description, video file or embed, thumbnail)
* **Testimonial** (client name, photo, quote, date)
* **Resource / Article / PDF** (title, content, file link)
* **User / Admin** (roles, login, permissions)
* **Inquiry / Contact Submission**
* **Client / Enrollee** (profile, schedule, assigned sessions)

### 1.4 Wireframes & Layout Concepts (Sketch)

Here’s a sketch-level idea:

* **Homepage**:

  * Hero section: full-width image or video, headline (e.g. “A Warm, Engaging Day Program for Older Adults”)
  * Key service categories (cards)
  * “Why Choose Us” section (icons + short copy)
  * Video intro / virtual tour
  * Testimonials carousel
  * Call to Action (Book a Visit)
  * Footer with contact, quick links

* **Service / Program Page**:

  * Header (breadcrumb)
  * Hero banner + short introduction
  * Tabs or accordions: “Overview”, “Daily Schedule”, “Benefits”, “Eligibility”
  * Images / carousel
  * CTA (Book this Program / Check Availability)

* **Booking Page / Calendar**:

  * Calendar view or list of upcoming slots
  * Click a slot → modal or slide-in form to book
  * Option for “Join Waitlist”
  * Confirmation page

* **Video / Media Page**:

  * Grid or list of videos / media cards with thumbnail + title
  * Watch overlay / lightbox
  * Filter by program / topic

* **Caregiver Resources / Blog**:

  * List of articles / PDFs
  * Search, filter by topic
  * Article page with “related resources”

* **Staff / About**:

  * Grid/list of staff with photos
  * Click to expand bio modal or navigate to detail page
  * Accreditation & logos

* **Admin Dashboard (after login)**:

  * Overview / KPI widgets (bookings count, upcoming sessions, etc.)
  * Manage Bookings / Sessions
  * Manage Services / Content
  * Media / Video upload
  * Article / Resources management
  * Staff management
  * Reports / export

### 1.5 UI / Design Style Suggestions

* Color palette: warm, calming tones (soft blues, beiges, gentle greens)
* Typography: large base font (e.g. 18px+), good line height, high contrast
* Buttons: large clickable targets, clear labels
* Spacing generous — white space to separate elements
* Use real photos of people / facility, avoid generic stock where possible
* Micro-interactions: smooth transitions, hover feedback, slide-in modals
* Progressive loading of media (lazy load)
* Accessibility: keyboard nav, alt text, ARIA, good contrast, skip links

---

## 2. Project Requirement Document (PRD)

Below is the PRD in **Markdown** format for use or ingestion by a coding agent like Claude Code. It is structured with clear phases, responsibilities, checklists, and deliverables.

```markdown
# Project Requirement Document (PRD)  
**Elderly Daycare / Adult Day Services Website**

---

## 1. Project Overview & Goals

### 1.1 Purpose  
Build a modern, responsive, accessible web platform for an elderly daycare / adult day services provider. The site will present service information, media (videos/photos), caregiver resources, and enable online bookings / enrollment. It should instill trust, ease-of-use, and scalability.

### 1.2 Objectives  
- Provide a clear, warm, and trustworthy online presence  
- Allow potential clients / caregivers to explore services and book visits easily  
- Offer multimedia content (photos / videos) for storytelling  
- Manage content (services, staff, resources) via a backend admin panel  
- Be accessible (WCAG A/AA) and performant  
- Be modular and maintainable for future expansion  

### 1.3 Success Metrics  
- Increase in online booking / inquiries  
- Lower bounce rate, especially on mobile  
- Page load times <2s (mobile)  
- Accessibility audit score (WCAG AA)  
- Admin usability: non-technical staff can update content  

---

## 2. Scope & Features

### 2.1 Core Features (Phase 1)

| Feature | Description |
|---|---|
| Home / Landing page | Hero, service cards, video intro, CTA, testimonials |
| Services module | Detail pages for each program, daily schedule, eligibility |
| Booking / Visit Request | Calendar or slot listing, form to request booking |
| Media / Gallery | Video & photo library, embed or upload |
| Staff / About | Staff bios, accreditation, mission |
| Caregiver Resources | FAQs, downloadable resources, blog / articles |
| Contact / Inquiry Form | Basic contact and map |
| Admin Dashboard | CRUD for all content entities, booking management |
| Authentication / Roles | Admin login, internal staff role |
| Basic Reporting | Bookings per day, upcoming sessions |
| SEO & Metadata | Page meta titles, schema markup, sitemaps |
| Accessibility & WCAG | Keyboard nav, alt text, ARIA, contrast |

### 2.2 Extended / Phase 2 Features

- Payment / deposit during booking  
- Waitlist / cancellation management  
- User accounts for clients / caregivers to view bookings  
- Notifications / email reminders  
- Multilingual support  
- Advanced search / filtering of resources  
- Analytics dashboard / charts  
- Integration with calendar tools (e.g. Google Calendar)  
- SMS / push notifications  
- Video streaming optimization (adaptive streaming)  

---

## 3. Technical Architecture & Stack

### 3.1 Proposed Stack

- **Backend / Framework**: Laravel 12 (PHP 8.4)  
- **Database**: MariaDB 11.8  
- **Frontend**: Tailwind CSS, Alpine.js, Livewire  
- **Server**: Apache 2.4  
- **Dev Tools**: Composer, Artisan, npm / Vite  
- **Containerization**: Docker + Docker Compose  
- **Storage / Media**: Local or cloud (S3 / object storage)  
- **Video delivery**: HLS / adaptive where required  
- **Authentication & Authorization**: Laravel built‑in + roles / gates  
- **API (optional)**: JSON API endpoints (for possible future mobile app)  

### 3.2 Non‑Functional Requirements

| Requirement | Target |
|---|---|
| Performance | Page load <2s on mobile, <1.5s desktop |
| Scalability | Able to scale horizontally (web nodes) |
| Security | CSRF protection, input validation, secure file uploads, role-based access |
| Accessibility | WCAG 2.1 A/AA compliance |
| Maintainability | Clean modular architecture, tests |
| Backup & Recovery | Daily DB backups, media backups |
| Logging & Monitoring | Error logging (Sentry, etc.), performance metrics |
| SEO | Schema, meta tags, Open Graph, sitemap, robots.txt |

---

## 4. Phased Execution Plan & Milestones

Each phase describes the deliverables, acceptance criteria, and tasks. The coding agent should treat each phase as independently deployable / testable.

| Phase | Deliverables | Tasks / Checklist | Acceptance Criteria |
|---|---|---|---|
| **Phase 0 – Setup / Infrastructure** | Docker + local dev environment, Laravel skeleton, deployment pipeline | - Setup Docker Compose with web, PHP, DB, storage volumes <br> - Configure Apache vhost, environment variables <br> - Scaffold Laravel app <br> - Setup basic CI/CD (optional) <br> - Setup basic seeding and migrations | Developer can spin up `docker-compose up` and see Laravel welcome page <br> DB connection works <br> repository build passes |
| **Phase 1 – Core Content / Pages** | Home, About, Services, Staff, Contact pages (static + CMS) | - Define database migrations and models (Service, Staff, Resource) <br> - Build controllers / Livewire / blade templates for listing and detail pages <br> - Admin CRUD UI for content (Livewire) <br> - Navigation, layout, footer <br> - SEO metadata per page | Static pages render properly, admin can create/edit content, navigation flows user to those pages |
| **Phase 2 – Media / Gallery / Video Module** | Video gallery / photo gallery, media upload, video viewing | - Media migration / model <br> - Upload pipeline, validation, storage <br> - Gallery listing + filtering <br> - Video playback (embed or HLS) <br> - Admin UI for uploads & metadata | Videos & images can be uploaded, listed, viewed by front end. Admin UI to manage media |
| **Phase 3 – Booking / Visit Request** | Booking module (basic request) | - Booking sessions model, migrations <br> - Public booking UI (list slots, select, submit) <br> - Booking form with validation, confirmation email <br> - Admin UI to view/manage bookings <br> - Conflict checking (capacity) | Users can submit booking, admin sees bookings, slot conflicts prevented |
| **Phase 4 – Authentication / Roles / Admin Enhancements** | Secure admin / staff login, roles, fine access control | - Laravel auth setup <br> - Role / permission model (e.g. “admin”, “staff”) <br> - Gate / policies for content access <br> - Staff user CRUD in admin <br> - Audit logs / change logs | Only authorized roles can access admin, permissions enforced |
| **Phase 5 – UX Polish, Performance & Accessibility** | UI refinements, accessibility compliance, performance tuning | - WCAG checks, keyboard nav, ARIA labels <br> - Lazy loading of images & videos <br> - CSS / JS bundling, cache headers <br> - SEO enhancements, sitemap, robots <br> - Error pages, fallback UI | Accessibility audit passes AA, performance metrics acceptable, SEO validated |
| **Phase 6 – Extended Features / Enhancements** | Payment, waitlist, client accounts, notifications etc. | - Payment integration (Stripe / PayPal) <br> - Waitlist logic <br> - Client / caregiver user accounts <br> - Email / SMS notifications <br> - Analytics dashboard <br> - Multilingual / i18n | Extended features work end-to-end, each feature is covered by tests |
| **Phase 7 – Deployment, QA & Launch** | Production deployment, final QA, monitoring and training | - Setup production Docker / hosting <br> - Environment config (SSL, domains) <br> - Final test suite, security audit <br> - Admin user onboarding / documentation <br> - Monitoring & logging setup | Production URL live, all features tested, backup & rollback in place, stakeholders accept |

---

## 5. Detailed Checklists & Microtasks

For each phase, the coding agent should work with tasks broken down further:

### Phase 0 Checklist (Setup)

- [ ] Define folder structure (e.g. `app/`, `resources/`, `modules/`, `dashboard/`)  
- [ ] Create `docker-compose.yml` with services: `web`, `php`, `db`, `storage`  
- [ ] Setup `.env.example`  
- [ ] Setup vhost for Apache (document `DocumentRoot` pointing to Laravel `public`)  
- [ ] Configure `.htaccess` or apache conf for Laravel rewrite  
- [ ] Install base Laravel via Composer  
- [ ] Git init, .gitignore, initial commit  
- [ ] Seed minimal data (e.g. example staff, services)  
- [ ] Validate DB connection and artisan commands  

### Phase 1 Checklist (Core Content)

- [ ] Migrations: `services`, `staff`, `resources` tables  
- [ ] Models + relationships (e.g. Service hasMany Resources)  
- [ ] Admin UI (Livewire) CRUD for those models  
- [ ] Public controllers / blade templates to list & show service, staff  
- [ ] Navigation / layout blade, header, footer  
- [ ] SEO metadata fields (title, description) in model + template  

### Phase 2 Checklist (Media / Gallery)

- [ ] `media` table migration (type, path, title, description, mime)  
- [ ] Storage driver (local filesystem or cloud)  
- [ ] Admin UI for upload, validation (file size, type)  
- [ ] Public gallery listing (with pagination)  
- [ ] Video playback component (Lightbox / modal)  
- [ ] Lazy load images / thumbnails  

### Phase 3 Checklist (Booking)

- [ ] `bookings` or `visits` table with slot references  
- [ ] Session / slot generation logic (admin or cron)  
- [ ] Booking request form, validation (name, contact, preferred date)  
- [ ] Conflict / capacity logic  
- [ ] Confirmation emails / notifications  
- [ ] Admin booking list, filter, approve / deny  

### Phase 4 Checklist (Auth & Roles)

- [ ] Laravel built-in auth scaffolding (or custom)  
- [ ] Roles & permissions model (roles, role_user pivot)  
- [ ] Define policies / gates for CRUD  
- [ ] Staff user management (create / edit staff users)  
- [ ] Audit trail (who changed what)  

### Phase 5 Checklist (UX / Perf / Accessibility)

- [ ] ARIA attributes, alt texts  
- [ ] Focus order, skip-to-content link  
- [ ] Contrast ratio checks  
- [ ] Lazy loading, prefetch  
- [ ] Static asset versioning, cache headers  
- [ ] Sitemap.xml, robots.txt  
- [ ] 404 / error pages  

### Phase 6 Checklist (Extended Features)

- [ ] Payment integration (test mode)  
- [ ] Waitlist logic and UI  
- [ ] Client accounts: registration, dashboard, booking history  
- [ ] Email and SMS templates & sending  
- [ ] Analytics charts (bookings per week etc.)  
- [ ] i18n / translations  

### Phase 7 Checklist (Launch)

- [ ] Set up production environment (Docker on server or K8s)  
- [ ] SSL / TLS, domain configuration  
- [ ] DB migration in production  
- [ ] Backup schedule, rollback plan  
- [ ] Documentation (admin manual, developer notes)  
- [ ] Training session for client / staff  
- [ ] Monitoring, error alerting  

---

## 6. Non‑Functional & Operational Considerations

- **Testing & Quality Assurance**  
  - Unit tests (models, business logic)  
  - Feature / Dusk tests for critical flows  
  - Accessibility tests / audit tools  
  - Load / performance tests on booking / media pages  

- **Security**  
  - Validate / sanitize all inputs  
  - CSRF / XSS protections  
  - File upload restrictions, virus scanning  
  - Rate limiting for booking, login brute force  
  - Role-based access  
  - HTTPS only  

- **Performance / Caching**  
  - Use caching (e.g. Laravel cache) for repeated queries (service list, media)  
  - Optimize images (compression, responsive src sets)  
  - Use lazy loading for media  
  - HTTP caching headers  
  - Possibly a CDN for media delivery  

- **Logging & Monitoring**  
  - Error logging via Sentry / Laravel logging  
  - Performance metrics (New Relic, etc.)  
  - Uptime monitoring  

- **Backup / Recovery**  
  - Daily database dumps + offsite storage  
  - Media file backup  
  - Rollback scripts  

- **Scalability & Deployment**  
  - Docker-based architecture supports horizontal scaling  
  - Use environment variables / configuration for scaling  
  - Plan for sticky sessions or session store if multiple web nodes  
  - Use third-party video/CDN streaming if scaling media usage  

---

## 7. Deliverables & Milestones

- **Commit history & versioning**  
- **Phase-based deployments**  
- **Documentation** (README, API docs, admin user guide)  
- **Test suites**  
- **Production deployment setup**  
- **Training/hand‑off to stakeholder**

---

## 8. Assumptions & Risks

- The client will provide high-quality photos, videos, and staff bios  
- Video file sizes and formats are manageable / small  
- Booking volume is moderate initially  
- Network & infrastructure resources are sufficient  
- Changes in scope (e.g. needing real-time streaming or large concurrency) may require architectural tweaks  

---

## 9. Requirements Summary (Checklist)

- [ ] Responsive, mobile-first UI  
- [ ] Accessibility (WCAG A/AA)  
- [ ] Clean information architecture  
- [ ] Multimedia (video + photo) support  
- [ ] Booking / enrollment module  
- [ ] Admin backend for content management  
- [ ] Role-based access & security  
- [ ] SEO & performance  
- [ ] Testing & QA pipelines  
- [ ] Deployment & backup  
- [ ] Monitoring & analytics  

---

## 10. How Claude Code (or coding agent) Can Execute

1. **Phase-by-phase execution**: Each phase is self-contained; the agent should complete and test one phase before proceeding to the next.  
2. **Use migrations & seeders**: The agent can generate initial dummy data to test content flows.  
3. **Livewire & Alpine scaffolding**: Use standard patterns for CRUD, reactive components, modal forms.  
4. **Test-driven approach**: For each critical flow (booking, media upload), write tests first.  
5. **CI / build scripts**: The agent should maintain a CI script (e.g. GitHub Actions) to run tests, lint, build assets.  
6. **Config management**: Use `.env` files for environment-specific config; don’t hardcode secrets.  
7. **Graceful error handling**: Provide fallback views for missing media, 404s, etc.  
8. **Iterative UI / accessibility enhancements**: After functional features, refine styling, ARIA, performance.  
9. **Deployment manifests / scripts**: The agent should generate a Docker Compose or Kubernetes manifest for production.  
10. **Documentation generation**: At end of each phase, produce a short markdown summary and API docs.

---

This PRD should give a clear, phase-wise path for the coding agent to build out the complete website, from zero to launch, in manageable, testable stages.  
