<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\Artisan;
use Tests\TestCase;

class ConfigContractCheckTest extends TestCase
{
    public function test_config_contract_passes_with_valid_env(): void
    {
        putenv('APP_URL=http://localhost:8000');
        putenv('DB_PORT=3306');
        putenv('REDIS_PORT=6379');

        $exitCode = Artisan::call('contract:config');

        $this->assertSame(0, $exitCode);
    }
}
