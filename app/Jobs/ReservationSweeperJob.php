<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ReservationSweeperJob implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

    public $tries = 3;

    public function handle(): void
    {
        try {
            DB::statement('CALL sp_reservation_sweeper()');
            Log::info('Reservation sweeper executed successfully.');
        } catch (\Throwable $exception) {
            Log::error('Reservation sweeper failed', [
                'message' => $exception->getMessage(),
            ]);

            throw $exception;
        }
    }
}
