<?php

namespace App\Providers;

use App\Models\User;
use App\Policies\RolePolicy;
use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;
use Illuminate\Support\Facades\Gate;

class AuthServiceProvider extends ServiceProvider
{
    protected $policies = [
        User::class => RolePolicy::class,
    ];

    public function boot(): void
    {
        $this->registerPolicies();

        Gate::define('access-admin', fn (User $user) => $user->hasAnyRole(['admin', 'super_admin']));
        Gate::define('access-staff', fn (User $user) => $user->hasAnyRole(['staff', 'admin', 'super_admin']));
        Gate::define('access-caregiver', fn (User $user) => $user->hasAnyRole(['caregiver', 'admin', 'super_admin']));
    }
}
