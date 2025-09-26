<?php

use Illuminate\Foundation\Application;

define('LARAVEL_START', microtime(true));

require __DIR__.'/../vendor/autoload.php';

/** @var Application $app */
$app = require_once __DIR__.'/../bootstrap/app.php';

$app->handleRequest(
    request: $app->make(Illuminate\Http\Request::class)
)->send();

$app->terminate();
