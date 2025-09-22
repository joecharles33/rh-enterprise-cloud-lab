#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT_DIR}/terraform/root"
ANSIBLE_DIR="${ROOT_DIR}/ansible"
OUT_JSON="${ANSIBLE_DIR}/terraform_outputs.json"

terraform -chdir="${TF_DIR}" output -json > "${OUT_JSON}"
echo "Wrote ${OUT_JSON}"

GV="${ANSIBLE_DIR}/group_vars/all.yml"
cat > "${GV}" <<'YAML'
# Auto-generated vars pulling from terraform_outputs.json
ssh_key_name: "{{ (lookup('file', 'ansible/terraform_outputs.json') | from_json).bastion_key_name.value }}"
ansible_ssh_private_key_file: "{{ lookup('env','HOME') }}/.ssh/{{ ssh_key_name }}.pem"

bastion_user: "{{ (lookup('file', 'ansible/terraform_outputs.json') | from_json).bastion_user.value }}"
linux_user:   "{{ (lookup('file', 'ansible/terraform_outputs.json') | from_json).linux_user.value }}"

# Use ProxyJump to reach private instances via the bastion public IP
ansible_ssh_common_args: >-
  -o ProxyJump={{ bastion_user }}@{{ (lookup('file', 'ansible/terraform_outputs.json') | from_json).bastion_public_ip.value }}
YAML

echo "Wrote ${GV}"
