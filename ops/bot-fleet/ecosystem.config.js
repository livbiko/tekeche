// PM2 config for the 20-day bot QA fleet scheduler. Fully independent of
// tekeche-api's own ecosystem.config.js — this only ever spawns/kills its
// own child bot processes (driver-bot.js / passenger-bot.js), never touches
// the real API process.
module.exports = {
  apps: [
    {
      name: 'tekeche-bot-fleet',
      script: 'scheduler.js',
      cwd: 'C:\\inetpub\\wwwroot\\tekeche\\ops\\bot-fleet',
      instances: 1,
      exec_mode: 'fork', // stateful singleton (owns the child-process map + fleet-state.json) — cluster mode is for load-balanced stateless servers, not this
      autorestart: true,
      watch: false,
      max_memory_restart: '256M',
      error_file: 'C:\\logs\\tekeche-bot-fleet-error.log',
      out_file:   'C:\\logs\\tekeche-bot-fleet-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss',
    },
  ],
};
