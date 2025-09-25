# From repo root:
set -a
source ./.env
set +a

# Derive Terraform vars from your env:
export TF_VAR_admin_cidr="${PUBLIC_IP}/32"
export TF_VAR_key_pair_name="${KEY_PAIR_NAME}"

