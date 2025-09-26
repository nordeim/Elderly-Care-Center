<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class ConfigContractCheck extends Command
{
    protected $signature = 'contract:config';
    protected $description = 'Validate required environment variables and configuration contracts';

    public function handle(): int
    {
        $required = [
            'APP_ENV', 'APP_URL',
            'DB_HOST','DB_PORT','DB_DATABASE','DB_USERNAME','DB_PASSWORD',
            'REDIS_HOST','REDIS_PORT',
        ];

        $missing = [];
        foreach ($required as $key) {
            if (empty(env($key))) $missing[] = $key;
        }

        if (!empty($missing)) {
            $this->error('Missing required env vars: '.implode(', ', $missing));
            return self::FAILURE;
        }

        // Simple format checks
        if (!preg_match('#^https?://#', env('APP_URL',''))) {
            $this->error('APP_URL must start with http:// or https://');
            return self::FAILURE;
        }
        if (!ctype_digit((string)env('DB_PORT')) || !ctype_digit((string)env('REDIS_PORT'))) {
            $this->error('DB_PORT and REDIS_PORT must be numeric');
            return self::FAILURE;
        }

        $this->info('Config contract OK');
        return self::SUCCESS;
    }
}
