@extends('layouts.admin')

@section('content')
    <div class="space-y-8" x-data="analyticsDashboard(@json($filters), @json($bookingsByStatus), @json($funnel), @json($trend), @json($paymentStats), @json($mediaStats), @json($notificationStats))">
        <header class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
                <h1 class="text-3xl font-bold">{{ __('Platform Analytics') }}</h1>
                <p class="text-slate-600">{{ __('Monitor bookings, payments, and media engagement across the platform.') }}</p>
            </div>
            <form class="flex flex-wrap gap-3" @submit.prevent="submitFilters">
                <label class="flex flex-col text-sm font-medium text-slate-600">
                    {{ __('Start date') }}
                    <input type="date" x-model="filters.start" class="rounded-md border-slate-300 focus:border-indigo-500 focus:ring-indigo-500">
                </label>
                <label class="flex flex-col text-sm font-medium text-slate-600">
                    {{ __('End date') }}
                    <input type="date" x-model="filters.end" class="rounded-md border-slate-300 focus:border-indigo-500 focus:ring-indigo-500">
                </label>
                <button type="submit" class="inline-flex items-center px-4 py-2 bg-indigo-600 text-white rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:ring-offset-2">
                    {{ __('Apply') }}
                </button>
            </form>
        </header>

        <section class="grid grid-cols-1 md:grid-cols-3 gap-4" aria-labelledby="kpi-cards">
            <h2 id="kpi-cards" class="sr-only">{{ __('Key performance indicators') }}</h2>
            <div class="bg-white border border-slate-200 rounded-lg p-6 shadow">
                <p class="text-sm uppercase text-slate-500">{{ __('Bookings (confirmed)') }}</p>
                <p class="text-3xl font-semibold" x-text="funnel.confirmed"></p>
                <p class="text-xs text-slate-500 mt-2">{{ __('Conversion rate:') }} <span x-text="funnel.conversion_rate + '%'" aria-live="polite"></span></p>
            </div>
            <div class="bg-white border border-slate-200 rounded-lg p-6 shadow">
                <p class="text-sm uppercase text-slate-500">{{ __('Payments (success rate)') }}</p>
                <p class="text-3xl font-semibold" x-text="paymentStats.success_rate + '%'" aria-live="polite"></p>
                <p class="text-xs text-slate-500 mt-2">{{ __('Revenue:') }} $<span x-text="paymentStats.revenue.toFixed(2)"></span></p>
            </div>
            <div class="bg-white border border-slate-200 rounded-lg p-6 shadow">
                <p class="text-sm uppercase text-slate-500">{{ __('Notifications delivered') }}</p>
                <p class="text-3xl font-semibold" x-text="notificationStats.sent" aria-live="polite"></p>
                <p class="text-xs text-slate-500 mt-2">{{ __('Failed:') }} <span x-text="notificationStats.failed"></span></p>
            </div>
        </section>

        <section class="grid grid-cols-1 lg:grid-cols-2 gap-6" aria-labelledby="analytics-charts">
            <div class="bg-white border border-slate-200 rounded-lg p-6 shadow space-y-4">
                <header>
                    <h2 class="text-lg font-semibold">{{ __('Booking trend') }}</h2>
                    <p class="text-xs text-slate-500">{{ __('Daily bookings within selected range.') }}</p>
                </header>
                <canvas id="booking-trend-chart" role="img" aria-label="{{ __('Line chart of bookings per day') }}"></canvas>
            </div>
            <div class="bg-white border border-slate-200 rounded-lg p-6 shadow space-y-4">
                <header>
                    <h2 class="text-lg font-semibold">{{ __('Conversion funnel') }}</h2>
                    <p class="text-xs text-slate-500">{{ __('Requested vs confirmed vs attended bookings.') }}</p>
                </header>
                <canvas id="booking-funnel-chart" role="img" aria-label="{{ __('Bar chart of booking funnel stages') }}"></canvas>
            </div>
        </section>

        <section class="grid grid-cols-1 lg:grid-cols-2 gap-6" aria-labelledby="analytics-secondary">
            <div class="bg-white border border-slate-200 rounded-lg p-6 shadow space-y-4">
                <header>
                    <h2 class="text-lg font-semibold">{{ __('Payment status breakdown') }}</h2>
                    <p class="text-xs text-slate-500">{{ __('Succeeded, failed, refunded totals.') }}</p>
                </header>
                <canvas id="payment-breakdown-chart" role="img" aria-label="{{ __('Donut chart of payment statuses') }}"></canvas>
            </div>
            <div class="bg-white border border-slate-200 rounded-lg p-6 shadow space-y-4">
                <header>
                    <h2 class="text-lg font-semibold">{{ __('Media + notifications') }}</h2>
                    <p class="text-xs text-slate-500">{{ __('Uploads vs virtual tours and notification outcomes.') }}</p>
                </header>
                <ul class="space-y-2 text-sm text-slate-600" aria-live="polite">
                    <li>{{ __('Media uploads:') }} <span x-text="mediaStats.uploads"></span></li>
                    <li>{{ __('Virtual tours:') }} <span x-text="mediaStats.virtualTours"></span></li>
                    <li>{{ __('Notifications skipped:') }} <span x-text="notificationStats.skipped"></span></li>
                </ul>
            </div>
        </section>

        <section role="status" x-show="notificationStats.failed > 5" class="bg-amber-50 border border-amber-200 text-amber-800 rounded-md p-4" aria-live="assertive">
            <p class="text-sm">{{ __('Heads up: Notification failures exceed expected thresholds. Review the notification pipeline runbook.') }}</p>
        </section>
    </div>
@endsection

@push('scripts')
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
        function analyticsDashboard(filters, bookingsByStatus, funnel, trend, paymentStats, mediaStats, notificationStats) {
            return {
                filters,
                bookingsByStatus,
                funnel,
                trend,
                paymentStats,
                mediaStats,
                notificationStats,
                trendChart: null,
                funnelChart: null,
                paymentChart: null,
                init() {
                    this.renderTrendChart();
                    this.renderFunnelChart();
                    this.renderPaymentChart();
                },
                renderTrendChart() {
                    const ctx = document.getElementById('booking-trend-chart');
                    if (!ctx) return;
                    const labels = this.trend.map(item => item.date);
                    const data = this.trend.map(item => item.count);
                    if (this.trendChart) this.trendChart.destroy();
                    this.trendChart = new Chart(ctx, {
                        type: 'line',
                        data: {
                            labels,
                            datasets: [{
                                label: '{{ __('Bookings') }}',
                                data,
                                borderColor: '#4f46e5',
                                backgroundColor: 'rgba(79, 70, 229, 0.1)',
                                tension: 0.3,
                                fill: true,
                            }]
                        },
                        options: {
                            responsive: true,
                            scales: {
                                y: { beginAtZero: true }
                            }
                        }
                    });
                },
                renderFunnelChart() {
                    const ctx = document.getElementById('booking-funnel-chart');
                    if (!ctx) return;
                    if (this.funnelChart) this.funnelChart.destroy();
                    this.funnelChart = new Chart(ctx, {
                        type: 'bar',
                        data: {
                            labels: ['{{ __('Requested') }}', '{{ __('Confirmed') }}', '{{ __('Attended') }}', '{{ __('Cancelled') }}'],
                            datasets: [{
                                label: '{{ __('Bookings') }}',
                                data: [this.funnel.requested, this.funnel.confirmed, this.funnel.attended, this.funnel.cancelled],
                                backgroundColor: ['#6366f1', '#22d3ee', '#10b981', '#f97316'],
                            }]
                        },
                        options: {
                            responsive: true,
                            scales: {
                                y: { beginAtZero: true }
                            }
                        }
                    });
                },
                renderPaymentChart() {
                    const ctx = document.getElementById('payment-breakdown-chart');
                    if (!ctx) return;
                    if (this.paymentChart) this.paymentChart.destroy();
                    this.paymentChart = new Chart(ctx, {
                        type: 'doughnut',
                        data: {
                            labels: ['{{ __('Succeeded') }}', '{{ __('Failed') }}', '{{ __('Refunded') }}'],
                            datasets: [{
                                data: [this.paymentStats.succeeded, this.paymentStats.failed, this.paymentStats.refunded],
                                backgroundColor: ['#10b981', '#ef4444', '#f59e0b'],
                            }]
                        },
                        options: {
                            responsive: true,
                            plugins: {
                                legend: {
                                    position: 'bottom'
                                }
                            }
                        }
                    });
                },
                submitFilters() {
                    const params = new URLSearchParams({
                        start: this.filters.start,
                        end: this.filters.end,
                    });
                    window.location = `${window.location.pathname}?${params.toString()}`;
                }
            };
        }
    </script>
@endpush
