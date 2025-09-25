#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${ROOT_DIR}/ansible/inventories/lab.ini"

cd "${ROOT_DIR}"

# require jq
command -v jq >/dev/null || { echo "jq is required"; exit 1; }

BASTION_IP=$(terraform -chdir=terraform/root output -raw bastion_public_ip 2>/dev/null || true)
ALL_JSON=$(terraform -chdir=terraform/root output -json all_nodes_by_name)

# helpers
get_by_role() {
  local role="$1" key="$2"
  echo "${ALL_JSON}" | jq -r --arg role "${role}" --arg key "${key}" '
    to_entries
    | map(select(.value.role == $role))
    | map(.value[$key])
    | map(select(. != null and . != ""))
    | .[]
  ' 2>/dev/null || true
}

# build groups
ANSIBLE_PRIV=$(get_by_role ansible private_ip | paste -sd' ' -)
EDA_PRIV=$(get_by_role eda private_ip | paste -sd' ' -)
PAH_PRIV=$(get_by_role pah private_ip | paste -sd' ' -)
DB_PRIV=$(get_by_role "aap-db" private_ip | paste -sd' ' -)
RHEL_PRIV=$(get_by_role rhel private_ip | paste -sd' ' -)

# satellite needs public reachability
SAT_PUB=$(echo "${ALL_JSON}" | jq -r '
  to_entries | map(select(.value.role=="satellite")) |
  map("\(.key) ansible_host=\(.value.public_ip) private_ip=\(.value.private_ip)") | .[]
' 2>/dev/null || true)

mkdir -p "$(dirname "${OUT}")"
{
  echo "# Generated from terraform outputs"
  echo "[bastion]"
  [ -n "${BASTION_IP:-}" ] && echo "bastion ansible_host=${BASTION_IP} ansible_user=ec2-user" || echo "# (no bastion ip yet)"
  echo

  echo "[controller]"
  for ip in ${ANSIBLE_PRIV:-}; do echo "${ip}"; done
  echo

  echo "[eda]"
  for ip in ${EDA_PRIV:-}; do echo "${ip}"; done
  echo

  echo "[pah]"
  for ip in ${PAH_PRIV:-}; do echo "${ip}"; done
  echo

  echo "[db]"
  for ip in ${DB_PRIV:-}; do echo "${ip}"; done
  echo

  echo "[rhel]"
  for ip in ${RHEL_PRIV:-}; do echo "${ip}"; done
  echo

  echo "[satellite]"
  if [ -n "${SAT_PUB}" ]; then
    echo "${SAT_PUB}"
  fi
  echo

  echo "[lab:children]"
  echo "controller"
  echo "eda"
  echo "pah"
  echo "db"
  echo "rhel"
} > "${OUT}"

echo "Wrote ${OUT}"

