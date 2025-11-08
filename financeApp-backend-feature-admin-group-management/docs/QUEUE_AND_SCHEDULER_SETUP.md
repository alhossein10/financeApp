# Queue Workers and Scheduled Tasks Setup

This document provides instructions for setting up queue workers and scheduled tasks for the Finance Backend API.

## Queue Configuration

The application uses Laravel's queue system for background job processing. The default queue driver is configured to use the database.

### Queue Connections

- **Database Queue** (default): Uses the `jobs` table in the database
- **Redis Queue**: Available for high-performance scenarios (requires Redis)
- **Sync Queue**: For development/testing (processes jobs immediately)

### Environment Variables

```env
QUEUE_CONNECTION=database
DB_QUEUE_CONNECTION=mysql
DB_QUEUE_TABLE=jobs
DB_QUEUE=default
DB_QUEUE_RETRY_AFTER=90
```

## Running Queue Workers

### Development

For local development, run the queue worker using:

```bash
php artisan queue:work
```

Or with specific options:

```bash
php artisan queue:work database --sleep=3 --tries=3 --timeout=60
```

### Production

For production environments, use Supervisor to manage queue workers.

#### Installing Supervisor (Ubuntu/Debian)

```bash
sudo apt-get install supervisor
```

#### Configuring Supervisor

1. Copy the supervisor configuration:

```bash
sudo cp config/supervisor-queue-worker.conf /etc/supervisor/conf.d/finance-backend-worker.conf
```

2. Update the paths in the configuration file:

```bash
sudo nano /etc/supervisor/conf.d/finance-backend-worker.conf
```

Replace `/path/to/finance_backend` with your actual application path.

3. Update Supervisor and start the workers:

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start finance-backend-worker:*
```

#### Managing Queue Workers

```bash
# Check status
sudo supervisorctl status finance-backend-worker:*

# Start workers
sudo supervisorctl start finance-backend-worker:*

# Stop workers
sudo supervisorctl stop finance-backend-worker:*

# Restart workers
sudo supervisorctl restart finance-backend-worker:*

# View logs
tail -f storage/logs/worker.log
```

### Queue Worker Options

- `--sleep=3`: Sleep for 3 seconds when no jobs are available
- `--tries=3`: Attempt each job up to 3 times before failing
- `--max-time=3600`: Process jobs for a maximum of 1 hour before restarting
- `--timeout=60`: Maximum execution time for a single job (60 seconds)
- `--queue=high,default`: Process jobs from the "high" queue first, then "default"

## Scheduled Tasks

The application uses Laravel's task scheduler for automated maintenance tasks.

### Available Scheduled Tasks

| Task | Schedule | Description |
|------|----------|-------------|
| `exports:cleanup` | Daily at 2:00 AM | Clean up export files older than 24 hours |
| `files:cleanup-temp` | Daily at 2:15 AM | Clean up temporary files older than 24 hours |
| `audit:cleanup` | Daily at 3:00 AM | Clean up audit logs older than 90 days |
| `fundbox:recalculate` | Weekly (Sundays at 4:00 AM) | Recalculate fund box balance |
| `queue:prune-batches` | Daily | Prune stale queue batch entries |
| `queue:prune-failed` | Daily | Prune stale failed job entries |
| `cache:prune-stale-tags` | Hourly | Prune stale cache tags |

### Setting Up the Scheduler

#### Development

For local development, you can manually run scheduled tasks:

```bash
# Run all scheduled tasks that are due
php artisan schedule:run

# Run a specific command
php artisan exports:cleanup
```

#### Production

Add a single cron entry to run the Laravel scheduler:

```bash
# Edit crontab
crontab -e

# Add this line (replace /path/to/finance_backend with your actual path)
* * * * * cd /path/to/finance_backend && php artisan schedule:run >> /dev/null 2>&1
```

This cron entry will call the Laravel scheduler every minute, and Laravel will determine which tasks need to run.

### Verifying Scheduler Setup

```bash
# List all scheduled tasks
php artisan schedule:list

# Test the scheduler (runs tasks due in the next minute)
php artisan schedule:test
```

## Available Console Commands

### Cleanup Commands

```bash
# Clean up old export files
php artisan exports:cleanup

# Clean up temporary files
php artisan files:cleanup-temp

# Clean up old audit logs (default: 90 days)
php artisan audit:cleanup

# Clean up audit logs with custom retention period
php artisan audit:cleanup --days=30
```

### Maintenance Commands

```bash
# Recalculate fund box balance
php artisan fundbox:recalculate

# Generate OpenAPI documentation
php artisan openapi:generate
```

### Queue Management Commands

```bash
# Start queue worker
php artisan queue:work

# List failed jobs
php artisan queue:failed

# Retry a failed job
php artisan queue:retry {id}

# Retry all failed jobs
php artisan queue:retry all

# Flush all failed jobs
php artisan queue:flush

# Monitor queue in real-time
php artisan queue:monitor database:default,database:high --max=100
```

## Monitoring and Logging

### Queue Monitoring

Monitor queue performance and failed jobs:

```bash
# View queue statistics
php artisan queue:monitor

# Check failed jobs
php artisan queue:failed

# View worker logs
tail -f storage/logs/worker.log
```

### Scheduler Monitoring

Check scheduler execution:

```bash
# View scheduled tasks
php artisan schedule:list

# View scheduler logs
tail -f storage/logs/laravel.log | grep "schedule"
```

## Troubleshooting

### Queue Workers Not Processing Jobs

1. Check if workers are running:
   ```bash
   sudo supervisorctl status finance-backend-worker:*
   ```

2. Check worker logs:
   ```bash
   tail -f storage/logs/worker.log
   ```

3. Verify database connection:
   ```bash
   php artisan queue:work --once
   ```

### Scheduled Tasks Not Running

1. Verify cron is set up correctly:
   ```bash
   crontab -l
   ```

2. Check Laravel logs:
   ```bash
   tail -f storage/logs/laravel.log
   ```

3. Manually test a scheduled command:
   ```bash
   php artisan exports:cleanup
   ```

### High Memory Usage

If queue workers consume too much memory:

1. Add memory limit to supervisor config:
   ```ini
   command=php /path/to/artisan queue:work --memory=512
   ```

2. Restart workers more frequently:
   ```ini
   command=php /path/to/artisan queue:work --max-time=1800
   ```

## Best Practices

1. **Always use Supervisor in production** - Don't rely on manual queue worker management
2. **Monitor failed jobs** - Set up alerts for failed job accumulation
3. **Set appropriate timeouts** - Ensure job timeouts are less than worker timeouts
4. **Use job batching** - For processing multiple related jobs
5. **Implement job middleware** - For rate limiting and throttling
6. **Log important events** - Use Laravel's logging for debugging
7. **Test scheduled tasks** - Verify tasks run correctly before deploying
8. **Set up monitoring** - Use tools like Laravel Horizon (for Redis) or custom monitoring

## Production Checklist

- [ ] Queue connection configured in `.env`
- [ ] Database migrations run (jobs, failed_jobs tables)
- [ ] Supervisor installed and configured
- [ ] Queue workers started via Supervisor
- [ ] Cron entry added for scheduler
- [ ] Worker logs directory writable
- [ ] Failed job notifications configured
- [ ] Queue monitoring set up
- [ ] Backup strategy for queue data
- [ ] Load testing completed

## Additional Resources

- [Laravel Queue Documentation](https://laravel.com/docs/11.x/queues)
- [Laravel Task Scheduling Documentation](https://laravel.com/docs/11.x/scheduling)
- [Supervisor Documentation](http://supervisord.org/)
