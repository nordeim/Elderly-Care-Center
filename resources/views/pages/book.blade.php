@extends('layouts.app')

@section('content')
    <div class="bg-white p-6 rounded-lg shadow-md">
        <h1 class="text-2xl font-semibold">Book a Visit</h1>
        <p class="mt-2 text-sm text-slate-600">Choose an available slot and provide your details.</p>

        @if (session('status'))
            <div class="mt-4 p-4 rounded bg-green-100 text-green-800" role="status">
                {{ session('status') }}
            </div>
        @endif

        <form method="POST" action="{{ route('booking.store') }}" class="mt-6 space-y-4">
            @csrf
            <div>
                <label for="slot_id" class="block text-sm font-medium text-slate-700">Select a slot</label>
                <select id="slot_id" name="slot_id" class="mt-1 w-full border rounded px-3 py-2">
                    <option value="">Choose…</option>
                    @foreach ($slots as $slot)
                        <option value="{{ $slot->id }}" @selected(old('slot_id') == $slot->id)>
                            {{ $slot->start_at->format('M d, Y g:i A') }} — {{ $slot->service->name }} ({{ $slot->service->facility->name }})
                        </option>
                    @endforeach
                </select>
                @error('slot_id')
                    <p class="mt-2 text-sm text-red-600">{{ $message }}</p>
                @enderror
            </div>

            <fieldset class="space-y-2">
                <legend class="text-sm font-semibold">Caregiver contact</legend>
                <div>
                    <label for="email" class="block text-sm">Email</label>
                    <input id="email" name="email" type="email" value="{{ old('email') }}" class="mt-1 w-full border rounded px-3 py-2" />
                    @error('email')
                        <p class="mt-2 text-sm text-red-600">{{ $message }}</p>
                    @enderror
                </div>
                <div>
                    <label for="caregiver_name" class="block text-sm">Caregiver Name</label>
                    <input id="caregiver_name" name="caregiver_name" type="text" value="{{ old('caregiver_name') }}" class="mt-1 w-full border rounded px-3 py-2" />
                </div>
            </fieldset>

            <fieldset class="space-y-2">
                <legend class="text-sm font-semibold">Client details (optional)</legend>
                <div>
                    <label for="client_first_name" class="block text-sm">First Name</label>
                    <input id="client_first_name" name="client[first_name]" value="{{ old('client.first_name') }}" class="mt-1 w-full border rounded px-3 py-2" />
                </div>
                <div>
                    <label for="client_last_name" class="block text-sm">Last Name</label>
                    <input id="client_last_name" name="client[last_name]" value="{{ old('client.last_name') }}" class="mt-1 w-full border rounded px-3 py-2" />
                </div>
                <div>
                    <label for="client_email" class="block text-sm">Client Email</label>
                    <input id="client_email" name="client[email]" type="email" value="{{ old('client.email') }}" class="mt-1 w-full border rounded px-3 py-2" />
                </div>
                <div>
                    <label for="client_phone" class="block text-sm">Client Phone</label>
                    <input id="client_phone" name="client[phone]" value="{{ old('client.phone') }}" class="mt-1 w-full border rounded px-3 py-2" />
                </div>
            </fieldset>

            <div>
                <label for="notes" class="block text-sm font-medium">Special notes</label>
                <textarea id="notes" name="notes" rows="3" class="mt-1 w-full border rounded px-3 py-2">{{ old('notes') }}</textarea>
            </div>

            <button type="submit" class="w-full bg-indigo-600 text-white py-2 rounded-md">Submit</button>
        </form>
    </div>
@endsection
