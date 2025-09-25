<?php

namespace App\Services\Media;

use App\Models\MediaItem;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use RuntimeException;
use Symfony\Component\Process\Exception\ProcessFailedException;
use Symfony\Component\Process\Process;

class TranscodingService
{
    private array $tempFiles = [];

    public function __construct(private readonly string $disk = '')
    {
    }

    public function transcode(MediaItem $media): array
    {
        $disk = $this->disk ?: config('media.disk');
        $profiles = config('media.transcoding.profiles.default');

        $sourcePath = $media->file_url;

        if (! $this->fileExists($disk, $sourcePath)) {
            throw new RuntimeException('Source media file cannot be located.');
        }

        $conversions = [];

        foreach ($profiles['video'] ?? [] as $profile) {
            $outputKey = $this->buildOutputKey($sourcePath, $profile['resolution'] ?? 'unknown');
            $this->runFfmpeg($disk, $sourcePath, $outputKey, $profile);
            $conversions['video'][] = [
                'resolution' => $profile['resolution'] ?? null,
                'bitrate' => $profile['bitrate'] ?? null,
                'url' => $outputKey,
            ];
        }

        foreach ($profiles['audio'] ?? [] as $profile) {
            $outputKey = $this->buildOutputKey($sourcePath, 'audio');
            $this->runFfmpeg($disk, $sourcePath, $outputKey, $profile, true);
            $conversions['audio'][] = [
                'bitrate' => $profile['bitrate'] ?? null,
                'url' => $outputKey,
            ];
        }

        $thumbnailConfig = config('media.transcoding.thumbnail');
        if ($thumbnailConfig) {
            $thumbKey = $this->buildOutputKey($sourcePath, 'thumbnail.jpg');
            $this->runThumbnailExtract($disk, $sourcePath, $thumbKey, $thumbnailConfig);
            $conversions['thumbnail'] = [
                'url' => $thumbKey,
                'width' => $thumbnailConfig['width'] ?? null,
                'height' => $thumbnailConfig['height'] ?? null,
            ];
        }

        return $conversions;
    }

    protected function runFfmpeg(string $disk, string $inputPath, string $outputPath, array $profile, bool $audioOnly = false): void
    {
        $localInput = Storage::disk($disk)->path($inputPath);
        $localOutput = Storage::disk($disk)->path($outputPath);

        $command = ['ffmpeg', '-y', '-i', $localInput];

        if ($audioOnly) {
            $command[] = '-vn';
            if (isset($profile['bitrate'])) {
                $command[] = '-b:a';
                $command[] = $profile['bitrate'];
            }
        } else {
            if (isset($profile['resolution'])) {
                $command[] = '-vf';
                $command[] = 'scale=-2:'.str_replace('p', '', $profile['resolution']);
            }
            if (isset($profile['bitrate'])) {
                $command[] = '-b:v';
                $command[] = $profile['bitrate'];
            }
        }

        $command[] = $localOutput;

        $process = new Process($command);
        $process->setTimeout(900);
        $process->run();

        if (! $process->isSuccessful()) {
            Log::error('Transcoding failure', [
                'command' => $process->getCommandLine(),
                'output' => $process->getErrorOutput(),
            ]);

            throw new ProcessFailedException($process);
        }

        $this->uploadOutput($disk, $outputPath, $localOutput);
    }

    protected function runThumbnailExtract(string $disk, string $inputPath, string $outputPath, array $config): void
    {
        $localInput = $this->resolveInputPath($disk, $inputPath);
        $localOutput = $this->createTempFile($outputPath);

        $seconds = $config['seconds_offset'] ?? 1;

        $command = [
            'ffmpeg',
            '-y',
            '-ss', (string) $seconds,
            '-i', $localInput,
            '-vframes', '1',
            '-vf', sprintf('scale=%d:%d', $config['width'] ?? 640, $config['height'] ?? 360),
            $localOutput,
        ];

        $process = new Process($command);
        $process->setTimeout(120);
        $process->run();

        if (! $process->isSuccessful()) {
            Log::warning('Thumbnail generation failed', [
                'command' => $process->getCommandLine(),
                'output' => $process->getErrorOutput(),
            ]);
            return;
        }

        $this->uploadOutput($disk, $outputPath, $localOutput);
    }

    protected function buildOutputKey(string $sourcePath, string $suffix): string
    {
        $dir = rtrim(dirname($sourcePath), '/');
        $filename = pathinfo($sourcePath, PATHINFO_FILENAME);

        $extension = pathinfo($sourcePath, PATHINFO_EXTENSION) ?: 'mp4';
        $sanitizedSuffix = Str::slug($suffix, '_');

        return sprintf('%s/%s_%s.%s', $dir, $filename, $sanitizedSuffix, $extension);
    }

    protected function fileExists(string $disk, string $path): bool
    {
        return Storage::disk($disk)->exists($path);
    }

    public function __destruct()
    {
        foreach ($this->tempFiles as $file) {
            if (file_exists($file)) {
                @unlink($file);
            }
        }
    }

    protected function resolveInputPath(string $disk, string $path): string
    {
        $storage = Storage::disk($disk);

        if (method_exists($storage, 'path')) {
            try {
                return $storage->path($path);
            } catch (RuntimeException) {
                // fallback to streaming below
            }
        }

        $stream = $storage->readStream($path);

        if (! $stream) {
            throw new RuntimeException('Unable to read media from storage.');
        }

        $tempFile = $this->createTempFile('input');
        $destination = fopen($tempFile, 'w+b');

        stream_copy_to_stream($stream, $destination);

        fclose($destination);
        fclose($stream);

        return $tempFile;
    }

    protected function uploadOutput(string $disk, string $path, string $localFile): void
    {
        $storage = Storage::disk($disk);
        $handle = fopen($localFile, 'r');

        $storage->put($path, $handle);

        if (is_resource($handle)) {
            fclose($handle);
        }
    }

    protected function createTempFile(string $prefix): string
    {
        $tempFile = tempnam(sys_get_temp_dir(), 'media_'.Str::slug($prefix, '_'));
        $this->tempFiles[] = $tempFile;

        return $tempFile;
    }
}
