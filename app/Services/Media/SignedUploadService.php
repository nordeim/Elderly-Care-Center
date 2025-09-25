<?php

namespace App\Services\Media;

use Carbon\CarbonInterface;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use InvalidArgumentException;

class SignedUploadService
{
    public function __construct(private readonly string $disk = '')
    {
    }

    public function createUploadSignature(string $originalFilename, string $mimeType, int $sizeBytes): array
    {
        $disk = $this->disk ?: config('media.disk');
        $maxSize = (int) config('media.signed_url.max_upload_size');

        if ($sizeBytes <= 0 || $sizeBytes > $maxSize) {
            throw new InvalidArgumentException('Upload size exceeds allowed limits.');
        }

        $prefix = trim(config('media.prefix'), '/');
        $key = $prefix.'/'.Str::uuid().'/'.ltrim($originalFilename, '/');

        $expiresAt = now()->addSeconds((int) config('media.signed_url.expiry_seconds'));

        $uploadUrl = Storage::disk($disk)->temporaryUrl($key, $expiresAt, [
            'ResponseContentType' => $mimeType,
        ]);

        return [
            'disk' => $disk,
            'key' => $key,
            'upload_url' => $uploadUrl,
            'expires_at' => $expiresAt->toIso8601String(),
        ];
    }

    public function getTemporaryDownloadUrl(string $path, ?CarbonInterface $expiresAt = null): string
    {
        $disk = $this->disk ?: config('media.disk');
        $expiry = $expiresAt ?? now()->addDay();

        return Storage::disk($disk)->temporaryUrl($path, $expiry);
    }
}
