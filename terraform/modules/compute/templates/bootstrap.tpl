#cloud-config
hostname: ${hostname}
fqdn: ${hostname}.internal
package_update: true
package_upgrade: false
packages:
  - git
  - jq
  - curl
  - unzip
  - python3
  - podman
  - tmux
  - tree
  - bind-utils
write_files:
  - path: /etc/motd
    permissions: '0644'
    content: |
      Welcome to ${hostname} (${role}) - ${project}-${env}
runcmd:
  - yum -y install insights-client || true
  - echo "ROLE=${role}" > /etc/lab-role
  - echo "PROJECT=${project}" > /etc/lab-project
  - echo "ENV=${env}" > /etc/lab-env
