# --------------------------------------------
# Terraform Makefile (with lock helpers)
# --------------------------------------------
.PHONY: help init plan apply destroy validate fmt render-vars show-vars unlock locks backend-check

# ----- Config -----
ENV          ?= dev
TF_DIR       ?= terraform/root
ENV_DIR      := terraform/envs/$(ENV)
VAR_TPL      := $(ENV_DIR)/$(ENV).tpl.tfvars
VAR_FILE     := $(ENV_DIR)/$(ENV).tfvars
VAR_FILE_ABS := $(abspath $(VAR_FILE))

# Backend vars expected from shell for `init`
#   TF_STATE_BUCKET, TF_LOCK_TABLE, AWS_REGION
_require_env = @[ -n "$($1)" ] || (echo "ERROR: $1 is required"; exit 1)

# Lock behavior (tweakable at call time)
LOCK          ?= true
LOCK_TIMEOUT  ?= 5m

help:
	@echo "Targets:"
	@echo "  init           - terraform init with S3 backend"
	@echo "  render-vars    - render $(VAR_FILE) from $(VAR_TPL)"
	@echo "  plan           - terraform plan (abs var-file, lock timeout)"
	@echo "  apply          - terraform apply (abs var-file, lock timeout)"
	@echo "  destroy        - terraform destroy (abs var-file, lock timeout)"
	@echo "  unlock         - terraform force-unlock (LOCK_ID=...)"
	@echo "  locks          - list current DynamoDB locks (needs aws cli)"
	@echo "  backend-check  - sanity check S3/Dynamo backend"
	@echo "  validate, fmt, show-vars"

show-vars:
	@echo "ENV=$(ENV)"
	@echo "TF_DIR=$(TF_DIR)"
	@echo "ENV_DIR=$(ENV_DIR)"
	@echo "VAR_TPL=$(VAR_TPL)"
	@echo "VAR_FILE=$(VAR_FILE)"
	@echo "VAR_FILE_ABS=$(VAR_FILE_ABS)"
	@echo "LOCK=$(LOCK)"
	@echo "LOCK_TIMEOUT=$(LOCK_TIMEOUT)"

# ----- Init (remote state) -----
init:
	$(_require_env TF_STATE_BUCKET)
	$(_require_env TF_LOCK_TABLE)
	$(_require_env AWS_REGION)
	@echo "Initializing backend in $(TF_DIR) ..."
	terraform -chdir=$(TF_DIR) init -upgrade -reconfigure \
	  -backend-config="bucket=$(TF_STATE_BUCKET)" \
	  -backend-config="key=$(ENV)/terraform.tfstate" \
	  -backend-config="region=$(AWS_REGION)" \
	  -backend-config="dynamodb_table=$(TF_LOCK_TABLE)"

# ----- Render tfvars from template -----
render-vars:
	@mkdir -p "$(ENV_DIR)"
	@if [ -f "$(VAR_TPL)" ]; then \
		echo "Rendering $(VAR_FILE) from $(VAR_TPL) ..."; \
		if command -v envsubst >/dev/null 2>&1; then \
			envsubst < "$(VAR_TPL)" > "$(VAR_FILE)"; \
		else \
			cp "$(VAR_TPL)" "$(VAR_FILE)"; \
			echo "WARN: envsubst not found; copied template as-is."; \
		fi; \
		echo "Wrote $(VAR_FILE)"; \
	elif [ -f "$(VAR_FILE)" ]; then \
		echo "Using existing $(VAR_FILE)"; \
	else \
		echo "ERROR: Neither $(VAR_TPL) nor $(VAR_FILE) exists."; exit 1; \
	fi

# ----- Core Terraform flows -----
plan: render-vars
	@echo "Planning with -var-file=$(VAR_FILE_ABS)"
	terraform -chdir=$(TF_DIR) plan \
	  -var-file="$(VAR_FILE_ABS)" \
	  -var="env=$(ENV)" \
	  -lock=$(LOCK) \
	  -lock-timeout=$(LOCK_TIMEOUT)

apply: render-vars
	@echo "Applying with -var-file=$(VAR_FILE_ABS)"
	terraform -chdir=$(TF_DIR) apply -auto-approve \
	  -var-file="$(VAR_FILE_ABS)" \
	  -var="env=$(ENV)" \
	  -lock=$(LOCK) \
	  -lock-timeout=$(LOCK_TIMEOUT)

destroy: render-vars
	@echo "Destroying with -var-file=$(VAR_FILE_ABS)"
	terraform -chdir=$(TF_DIR) destroy -auto-approve \
	  -var-file="$(VAR_FILE_ABS)" \
	  -var="env=$(ENV)" \
	  -lock=$(LOCK) \
	  -lock-timeout=$(LOCK_TIMEOUT)

validate:
	terraform -chdir=$(TF_DIR) validate

fmt:
	terraform -chdir=$(TF_DIR) fmt -recursive

# ----- Lock helpers -----
# Use: gmake unlock ENV=dev LOCK_ID=<id-from-error>
unlock:
	@[ -n "$(LOCK_ID)" ] || (echo "ERROR: LOCK_ID is required (see 'Lock Info: ID' in the error)"; exit 1)
	@echo "Force-unlocking state with LOCK_ID=$(LOCK_ID) ..."
	terraform -chdir=$(TF_DIR) force-unlock -force $(LOCK_ID)

# Use: gmake locks ENV=dev AWS_REGION=... TF_LOCK_TABLE=...
locks:
	$(_require_env TF_LOCK_TABLE)
	$(_require_env AWS_REGION)
	@echo "Scanning DynamoDB table $(TF_LOCK_TABLE) in $(AWS_REGION) ..."
	@if command -v jq >/dev/null 2>&1; then \
	  aws dynamodb scan --table-name "$(TF_LOCK_TABLE)" --region "$(AWS_REGION)" | \
	    jq -r '.Items[] | .LockID.S + "  " + ( .Info?.S // "-" )'; \
	else \
	  aws dynamodb scan --table-name "$(TF_LOCK_TABLE)" --region "$(AWS_REGION)"; \
	fi

# Quick sanity checks for backend resources
backend-check:
	$(_require_env TF_STATE_BUCKET)
	$(_require_env TF_LOCK_TABLE)
	$(_require_env AWS_REGION)
	@echo "Checking S3 bucket and DynamoDB table ..."
	@aws s3api head-bucket --bucket "$(TF_STATE_BUCKET)" >/dev/null 2>&1 && echo "S3 OK: $(TF_STATE_BUCKET)" || (echo "S3 MISSING: $(TF_STATE_BUCKET)"; exit 1)
	@aws dynamodb describe-table --table-name "$(TF_LOCK_TABLE)" --region "$(AWS_REGION)" >/dev/null 2>&1 && echo "DynamoDB OK: $(TF_LOCK_TABLE)" || (echo "DynamoDB MISSING: $(TF_LOCK_TABLE)"; exit 1)

