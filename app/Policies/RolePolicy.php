<?php

namespace App\Policies;

use App\Models\User;

class RolePolicy
{
    /**
     * Determine if the user has any of the provided roles.
     */
    public function hasAnyRole(User $user, array $roles): bool
    {
        return in_array($user->role, $roles, true);
    }

    /**
     * Determine if the user has the exact role required.
     */
    public function hasRole(User $user, string $role): bool
    {
        return $user->role === $role;
    }
}
