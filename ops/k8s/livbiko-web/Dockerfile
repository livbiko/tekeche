# Static mirror of livbiko.com (currently served by IIS's Default Web Site on
# BikoDC -- never previously version-controlled; this site/ directory is a
# 2026-07-18 snapshot of its live content) for the OKE/standby backup path --
# see ops/oci/dns.tf's FAILOVER steering policy. Non-root, matching this
# project's tekeche-api container convention.
FROM nginxinc/nginx-unprivileged:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --chown=nginx:nginx site/ /usr/share/nginx/html

EXPOSE 8080
