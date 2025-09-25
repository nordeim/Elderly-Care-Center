<?php

namespace App\Actions\Auth;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class RegisterAdminAction
{
    public function execute(string $email, string $fullName, string $password): User
    {
        return DB::transaction(function () use ($email, $fullName, $password) {
            $user = new User([
                'email' => strtolower($email),
                'full_name' => $fullName,
                'role' => 'admin',
                'is_active' => true,
            ]);

            $user->password_hash = $password;
            if (property_exists($user, 'remember_token')) {
                $user->setRememberToken(Str::random(60));
            }

            $user->save();

            return $user;
        });
    }
}
