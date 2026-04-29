# 143 - Auto-start MySQL in Server Scripts

## Current Behavior

The `authserver` and `worldserver` scripts assume MySQL is already running. If MySQL isn't started, the servers fail with connection errors after launching.

## Intended Behavior

Both scripts should detect whether MySQL is running before starting the server binary. If MySQL is not running, automatically invoke `start-mysql` to start it.

## Suggested Implementation Steps

1. Add `check_mysql` function to both scripts
   - Check for PID file at `${DIR}/mysql/databases/mysqld.pid`
   - Verify process is running via `kill -0`
   - If not running, call `${DIR}/scripts/start-mysql`
   - Exit with error if start-mysql fails

2. Call `check_mysql` after `get_profile_paths` in main section

3. Test both scripts with MySQL stopped and running

## Files to Modify

- `scripts/authserver`
- `scripts/worldserver`

## Notes

The `start-mysql` script already handles the "already running" case gracefully by exiting 0, so calling it when MySQL is already running is safe.
