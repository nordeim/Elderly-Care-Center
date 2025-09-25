@extends('admin.layout')

@section('content')
    <div class="space-y-6">
        <header class="flex items-center justify-between">
            <div>
                <h1 class="text-2xl font-semibold">Booking Inbox</h1>
                <p class="text-sm text-slate-500">Monitor pending requests and manage confirmations.</p>
            </div>
            <form method="GET" action="{{ route('admin.bookings.index') }}" class="flex items-center space-x-2">
                <label for="status" class="text-sm font-medium">Filter</label>
                <select id="status" name="status" class="border rounded px-3 py-2">
                    <option value="">All statuses</option>
                    @foreach ($availableStatuses as $status)
                        <option value="{{ $status }}" @selected($currentStatus === $status)>{{ ucfirst(str_replace('_', ' ', $status)) }}</option>
                    @endforeach
                </select>
                <button type="submit" class="bg-indigo-600 text-white px-4 py-2 rounded">Apply</button>
            </form>
        </header>

        @if (session('status'))
            <div class="rounded border border-green-200 bg-green-50 p-4 text-green-800" role="status">
                {{ session('status') }}
            </div>
        @endif

        <section class="grid grid-cols-2 gap-4">
            @foreach ($availableStatuses as $status)
                <div class="rounded-lg border p-4">
                    <p class="text-sm text-slate-500">{{ ucfirst(str_replace('_', ' ', $status)) }}</p>
                    <p class="mt-2 text-2xl font-semibold">{{ $statusCounts[$status] ?? 0 }}</p>
                </div>
            @endforeach
        </section>

        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-slate-200">
                <thead class="bg-slate-50">
                    <tr>
                        <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500">Booking</th>
                        <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500">Client / Contact</th>
                        <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500">Slot</th>
                        <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500">Status</th>
                        <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100 bg-white">
                    @forelse ($bookings as $booking)
                        <tr>
                            <td class="px-4 py-3 text-sm">
                                <div class="font-medium">{{ $booking->uuid }}</div>
                                <div class="text-xs text-slate-500">Created {{ $booking->created_at->diffForHumans() }}</div>
                            </td>
                            <td class="px-4 py-3 text-sm">
                                @if ($booking->client)
                                    <div>{{ $booking->client->first_name }} {{ $booking->client->last_name }}</div>
                                    <div class="text-xs text-slate-500">{{ $booking->client->email }}</div>
                                @else
                                    <div>{{ $booking->guest_email }}</div>
                                @endif
                            </td>
                            <td class="px-4 py-3 text-sm">
                                <div>{{ optional($booking->slot->service)->name }}</div>
                                <div class="text-xs text-slate-500">{{ optional($booking->slot)->start_at?->format('M d, Y g:i A') }}</div>
                            </td>
                            <td class="px-4 py-3 text-sm">
                                <span class="inline-flex items-center rounded-full bg-slate-100 px-3 py-1 text-xs font-medium">
                                    {{ ucfirst(str_replace('_', ' ', $booking->status)) }}
                                </span>
                            </td>
                            <td class="px-4 py-3 text-sm">
                                <form method="POST" action="{{ route('admin.bookings.status', $booking) }}" class="flex items-center space-x-2">
                                    @csrf
                                    <select name="status" class="border rounded px-2 py-1 text-xs">
                                        @foreach ($availableStatuses as $status)
                                            <option value="{{ $status }}" @selected($status === $booking->status)>{{ ucfirst(str_replace('_', ' ', $status)) }}</option>
                                        @endforeach
                                    </select>
                                    <button type="submit" class="text-xs bg-indigo-600 text-white px-3 py-1 rounded">Update</button>
                                </form>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" class="px-4 py-6 text-center text-sm text-slate-500">No bookings found.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        {{ $bookings->links() }}
    </div>
@endsection
