# Testing Remediation Plan

## Goal
Restore green `php artisan test` execution after transitioning to Laravel 11 / PHPUnit 11 and updated frontend toolchain.

## Summary of Failures
- Missing dependency: `Mockery` referenced across feature tests.
- Metrics cache binding assumes config-loaded store; unit test bypass should reuse framework container or provide config stub.
- Feature tests rely on seeded data and routes; ensure factories/utilities align with Laravel 11 defaults (guards, hashing, CSRF, notifications).
- Config contract command may not exist or requires context.

## Action Plan

### 1. Dependencies & Autoloading
- **composer.json**
  - [ ] Add `mockery/mockery` to `require-dev`.
  - [ ] Ensure `nunomaduro/collision` is compatible with PHPUnit 11 (already ^8.0).
  - [ ] Consider adding Pest removal (tests already migrated to PHPUnit style).
- **composer.lock** / install step
  - [ ] Run `composer update mockery/mockery --dev` or `composer install` after editing.

### 2. Base TestCase & Framework Setup
- **tests/TestCase.php**
  - [x] `createApplication()` public via `RefreshDatabase` trait (done).
  - [ ] Audit need for custom migration runs; rely on `RefreshDatabase` with sqlite memory or mysql.
  - [ ] Configure default DB connection for tests (env/database.php?). Document steps.

### 3. Config Contract Test
- **tests/Feature/ConfigContractCheckTest.php**
  - [ ] Validate command `contract:config` exists (`app/Console/Commands`?).
  - [ ] If command removed, replace with relevant configuration validation or delete test.
  - [ ] Ensure environment variables set via `config()` instead of `putenv` if command reads config helper.

### 4. Booking Metrics Unit Test
- **tests/Unit/Metrics/BookingMetricsTest.php**
  - [x] Use `ArrayStore` repository (done).
  - [ ] Bind metrics config globally before instantiating `BookingMetrics` or pass store.
  - [ ] Provide booking statuses config to avoid `config()` call (use `Config::set`).

### 5. Feature Tests requiring Mockery
- **tests/Feature/Admin/AnalyticsDashboardTest.php**
  - [ ] Confirm dependencies (seed data uses various models). Ensure migrations cover columns.
  - [ ] Use factories if available for maintainability.
  - [ ] Confirm route names `admin.analytics` exist.
- **routes/web.php / app/Http/Controllers/Admin/AnalyticsController.php**
  - [x] Register `Route::get('/analytics', AnalyticsController::class)->name('analytics')` within the admin group.
  - [ ] Ensure controller invocation returns expected dataset (align with view `resources/views/admin/analytics.blade.php`).
- **seedAnalyticsData() adjustments**
  - [x] Create distinct booking slots per booking (duplicate slot currently causes unique constraint violation).
  - [ ] Prefer using helper to generate slots dynamically rather than hard-coding IDs.
- **tests/Feature/Bookings/CreateBookingTest.php**
  - [x] Ensure booking store route accessible without auth (CSRF?). Possibly disable mail job.
  - [x] Plan: override `setUp()` to disable CSRF via `$this->withoutMiddleware(VerifyCsrfToken::class)`.
**VerifyCsrfToken middleware handling**
  - [x] Disable CSRF middleware for targeted test (use `$this->withoutMiddleware(VerifyCsrfToken::class)` in `setUp`).
- **tests/Feature/ExampleTest.php**
  - [ ] Confirm root route returns 200 (requires seeding initial data?).
- **tests/Feature/Media/VirtualTourTest.php**
  - [ ] Validate `MediaItem` relationship definitions present; ensure database seeds/migrations align.
- **media pivot schema alignment**
  - [x] Update `Testimonial::media()` relation to set foreign pivot key to `media_id` so attach uses correct column.
  - [x] Confirm attach calls remain the same (`role`, `position` only).
- **tests/Feature/Notifications/ReminderTest.php**
  - [ ] Ensure jobs & notifications dependencies set (queues, metrics). Provide configuration and service container bindings (Notification fake). Requires Mockery for metrics? verify.
- **tests/Feature/Payments/StripeFlowTest.php**
  - [ ] After adding Mockery, confirm `StripeService` dependencies (config, routes) satisfied.
  - [ ] Optionally wrap with `withoutExceptionHandling()` for debug.
- **Payments routing & Stripe SDK**
  - [x] Register caregiver checkout route pointing to `Payments\CheckoutController@show` (`payments.checkout.show`).
  - [x] Register webhook route(s) for `StripeWebhookController` (e.g., `Route::post('/payments/stripe/webhook', StripeWebhookController::class)`).
  - [x] Add `stripe/stripe-php` dependency (done) so `Stripe\Event` is available to tests.

### 6. Global Config Adjustments for Tests
- **config/metrics.php**
  - [ ] Provide testing override (e.g., `METRICS_CACHE_STORE=array`). Document .env.testing.
- **.env.testing**
  - [ ] Ensure DB connection matches container (mysql vs sqlite). Possibly create file.
- **phpunit.xml**
  - [ ] Review (manual due to gitignore) to ensure bootstrap includes `.env.testing` and parallelization disabled if not configured.

### 7. Execution Sequence
1. Update composer dev dependencies (Mockery) & install.
2. Create `.env.testing` with DB + queue/test config (if missing).
3. Adjust `phpunit.xml` (or document manual change) to load `.env.testing`.
4. Patch tests needing config context (Config::set for metrics statuses, etc.).
5. Implement routes/controller adjustments and test helpers per sections above.
6. Re-run `php artisan test` inside container.
7. Iterate on remaining failures until suite passes.

## Validation Checklist
- [ ] `composer install` completes with new dev dependency.
- [ ] `php artisan test` passes locally (container environment) without warnings.
- [ ] Documented instructions added to README or docs if test setup changed.
