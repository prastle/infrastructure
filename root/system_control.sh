set -eu

/root/infrastructure/root/tasks/update_system_packages.sh
/root/infrastructure/root/tasks/firewall.sh
/root/infrastructure/root/tasks/user_ssh_keys.sh
/root/infrastructure/root/tasks/triplea_user.sh
/root/infrastructure/root/tasks/prometheus_metrics_exporter.sh
/root/infrastructure/root/tasks/papertrail.sh
/root/infrastructure/root/tasks/verify_host.sh
