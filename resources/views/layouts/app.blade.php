<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ config('app.name', 'Elderly Daycare Platform') }}</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/tailwindcss@3.4.1/dist/tailwind.min.css">
    <link rel="stylesheet" href="{{ asset('css/accessibility.css') }}">
</head>
<body class="bg-slate-100 text-slate-900">
    <a href="#main-content" class="skip-to-content">Skip to main content</a>
    <div class="min-h-screen flex items-center justify-center p-6">
        <main id="main-content" role="main" tabindex="-1" class="w-full max-w-md">
            @yield('content')
        </main>
    </div>
</body>
</html>
