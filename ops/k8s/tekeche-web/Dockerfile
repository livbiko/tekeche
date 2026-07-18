# Static mirror of tekeche.com (currently served by IIS from this same repo's
# root on BikoDC) for the OKE/standby backup path -- see ops/oci/dns.tf's
# 2026-07-18 FAILOVER steering policy. Non-root, matching this project's
# tekeche-api container convention.
FROM nginxinc/nginx-unprivileged:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --chown=nginx:nginx site/ /usr/share/nginx/html

EXPOSE 8080
