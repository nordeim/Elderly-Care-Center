<?php

namespace App\Jobs\Media;

use App\Jobs\Media\TranscodeJob;
use App\Models\MediaItem;
use App\Support\Metrics\MediaMetrics;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use RuntimeException;
use Symfony\Component\Process\Exception\ProcessFailedException;
use Symfony\Component\Process\Process;

class IngestMediaJob implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

    public int $tries = 5;

    public array $backoff = [60, 180, 600];

    public function __construct(public readonly int $mediaItemId)
    {
        $this->onQueue('media');
    }

    public function handle(MediaMetrics $metrics): void
    {
        $media = MediaItem::find($this->mediaItemId);

        if (! $media) {
            Log::warning('Media item missing during ingestion job.', [
                'media_item_id' => $this->mediaItemId,
            ]);

            return;
        }

        if ($media->status === MediaItem::STATUS_PENDING) {
            $metrics->recordIngestQueued();
        }

        $media->markStatus(MediaItem::STATUS_PROCESSING);

        try {
            $this->runVirusScan($media);
        } catch (ProcessFailedException|RuntimeException $exception) {
            $metrics->recordVirusScanFailure();
            $media->markStatus(MediaItem::STATUS_FAILED, $exception->getMessage());

            throw $exception;
        }

        TranscodeJob::dispatch($media->id)->onQueue('media');
    }

    protected function runVirusScan(MediaItem $media): void
    {
        if (! config('media.virus_scanning.enabled')) {
            return;
        }

        $script = config('media.virus_scanning.script_path');

        if (! $script || ! file_exists($script)) {
            Log::warning('Virus scanning script missing; skipping scan.', [
                'script' => $script,
            ]);

            return;
        }

        $command = sprintf('%s %s', escapeshellarg($script), escapeshellarg($media->file_url));
        $process = Process::fromShellCommandline($command);
        $process->setTimeout(300);
        $process->run();

        if (! $process->isSuccessful()) {
            throw new ProcessFailedException($process);
        }
    }
}
