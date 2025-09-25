<?php

namespace App\Jobs\Media;

use App\Models\MediaItem;
use App\Services\Media\TranscodingService;
use App\Support\Metrics\MediaMetrics;
use Exception;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class TranscodeJob implements ShouldQueue
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

    public function handle(TranscodingService $transcodingService, MediaMetrics $metrics): void
    {
        $media = MediaItem::find($this->mediaItemId);

        if (! $media) {
            Log::warning('Media item missing during transcode job.', [
                'media_item_id' => $this->mediaItemId,
            ]);

            return;
        }

        $metrics->recordTranscodeStart();

        try {
            $conversions = $transcodingService->transcode($media);
            $media->forceFill([
                'conversions' => $conversions,
                'status' => MediaItem::STATUS_READY,
                'error_message' => null,
            ])->save();

            $metrics->recordTranscodeSuccess();
        } catch (Exception $exception) {
            $media->markStatus(MediaItem::STATUS_FAILED, $exception->getMessage());
            $metrics->recordTranscodeFailure();

            Log::error('Transcoding job failed.', [
                'media_item_id' => $media->id,
                'message' => $exception->getMessage(),
                'exception' => $exception,
            ]);

            throw $exception;
        }
    }
}
