<?php

namespace Tests;

use Illuminate\Contracts\Console\Kernel;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        $this->artisan('migrate', ['--database' => 'sqlite', '--force' => true]);
    }

    protected function tearDown(): void
    {
        $this->artisan('migrate:reset', ['--database' => 'sqlite', '--force' => true]);

        parent::tearDown();
    }

    protected function createApplication()
    {
        $app = require __DIR__.'/../bootstrap/app.php';

        $app->make(Kernel::class)->bootstrap();

        return $app;
    }
}
