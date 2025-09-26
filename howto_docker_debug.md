Jeremiah, this is a fantastic trace — and you’ve uncovered a subtle but critical MySQL limitation that’s crashing your Laravel container during migrations.

---

### 🔍 Root cause

The error:

```
SQLSTATE[42000]: Syntax error or access violation: 1059 Identifier name 'booking_notifications_booking_id_caregiver_profile_id_channel_unique' is too long
```

means your migration is trying to create a **unique index** with a name that exceeds MySQL’s identifier length limit — which is **64 characters**.

Your index name is:

```
booking_notifications_booking_id_caregiver_profile_id_channel_unique
```

That’s **74 characters** — too long for MySQL to handle.

---

### 🔥 Why this crashes the container

Your entrypoint script runs `php artisan migrate` during startup. When the migration fails, Laravel throws an exception, the script exits with a non-zero code, and Docker marks the container as failed. That’s why `elderly-app` disappears after a few seconds.

---

### ✅ Fix: shorten the index name

In your migration file (`2025_04_01_000000_add_caregiver_account_tables.php`), locate the line that creates the unique index:

```php
$table->unique(['booking_id', 'caregiver_profile_id', 'channel'], 'booking_notifications_booking_id_caregiver_profile_id_channel_unique');
```

Replace it with a shorter name:

```php
$table->unique(['booking_id', 'caregiver_profile_id', 'channel'], 'booking_notify_booking_caregiver_channel_unique');
```

Or even:

```php
$table->unique(['booking_id', 'caregiver_profile_id', 'channel'], 'booking_notify_unique');
```

As long as the name is **≤ 64 characters**, MySQL will accept it.

---

### 🧪 Validate fix

1. Edit the migration file and shorten the index name.
2. Reset the database (optional for clean state):
   ```bash
   docker exec -it elderly-mysql mysql -uelderly -pelderly_secret -e "DROP DATABASE elderly_daycare; CREATE DATABASE elderly_daycare;"
   ```
3. Restart the app container:
   ```bash
   docker compose up --build -d
   ```
4. Watch logs:
   ```bash
   docker logs -f elderly-app
   ```

You should see the migration complete successfully and the container stay up.

---

### 🩺 Pro tip: prevent future crashes

In your `entrypoint.sh`, wrap migrations in a soft failure block:

```bash
if ! php artisan migrate --force; then
  echo "[entrypoint] Migration failed, continuing without crash"
fi
```

This way, Laravel logs the error but the container doesn’t exit. You can still debug interactively.

---

👉 So: shorten the index name to ≤ 64 characters, rebuild, and your app container will stabilize. Want me to help you refactor all long index names across your migrations to future-proof this?

https://copilot.microsoft.com/shares/N7SvfbZuwRMAMYMVHgQNv
