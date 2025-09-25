<?php

namespace Tests\Feature\Accessibility;

use PHPUnit\Framework\TestCase;

class SkipLinkTest extends TestCase
{
    public function test_skip_link_placeholder(): void
    {
        $this->markTestSkipped('Accessibility integration tests run once Laravel HTTP kernel is available.');
    }
}
