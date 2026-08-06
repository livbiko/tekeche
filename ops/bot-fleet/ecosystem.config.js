// PM2 config for the 20-day bot QA fleet scheduler. Fully independent of
// tekeche-api's own ecosystem.config.js — this only ever spawns/kills its
// own child bot processes (driver-bot.js / passenger-bot.js), never touches
// the real API process.
module.exports = {
  apps: [
    {
      name: 'tekeche-bot-fleet',
      script: 'scheduler.js',
      cwd: __dirname,
      instances: 1,
      exec_mode: 'fork', // stateful singleton (owns the child-process map + fleet-state.json) — cluster mode is for load-balanced stateless servers, not this
      autorestart: true,
      watch: false,
      max_memory_restart: '256M',
      // On-prem logs to the shared C:\logs\ dir alongside tekeche-api; other
      // platforms (the OCI standby mirror) fall back to PM2's own default
      // per-app log location since there's no equivalent shared dir there.
      ...(process.platform === 'win32' ? {
        error_file: 'C:\\logs\\tekeche-bot-fleet-error.log',
        out_file:   'C:\\logs\\tekeche-bot-fleet-out.log',
      } : {
        // Confirmed 2026-08-05: tekeche-api's real deploy path on the OCI
        // standby (10.0.2.10). lib.js/provision.js/scheduler.js default to
        // the BikoDC path otherwise, so this must be set for any non-win32
        // host running the mirror.
        env: { BOT_FLEET_API_DIR: '/opt/tekeche-api' },
      }),
      log_date_format: 'YYYY-MM-DD HH:mm:ss',
    },
  ],
};
