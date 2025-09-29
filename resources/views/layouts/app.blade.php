<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="Where compassionate care meets modern comfort for every family.">
    <meta name="theme-color" content="#1C3D5A">
    <title>{{ config('app.name', 'Elderly Daycare Platform') }}</title>

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Playfair+Display:wght@500;600;700&display=swap">

    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <link rel="stylesheet" href="{{ asset('css/accessibility.css') }}">

    @stack('head')
</head>
<body class="bg-brand-mist text-brand-slate">
    <div x-data="{ mobileMenuOpen: false }" id="app">
        <a href="#main-content" class="skip-to-content">Skip to main content</a>

        @yield('navigation')

        <main id="main-content" role="main" tabindex="-1">
            @yield('content')
        </main>

        @yield('footer')
    </div>
</body>
</html>
