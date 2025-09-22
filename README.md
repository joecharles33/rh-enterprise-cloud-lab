# RH Enterprise Cloud Lab (Terraform + Ansible)

A variable-driven AWS lab that provisions a VPC, bastion, optional Red Hat Satellite (private by default, public toggle),
optional Ansible Automation Platform (AAP), and RHEL targets. Outputs are handed to Ansible for post-provision configuration.

## Prerequisites (from zero)
- AWS account + IAM credentials configured locally (`aws sts get-caller-identity` must work)
- Tools: Git, Terraform ≥ 1.7, Ansible ≥ 2.16, AWS CLI, jq (optional)
- An existing **EC2 key pair** name in the target region (or create one)
- (Optional) Red Hat subscriptions for RHEL/Satellite/AAP

## 0) Create/choose Terraform remote state (recommended)
You can create an S3 bucket + DynamoDB table once for all environments:
```bash
export TF_STATE_BUCKET=<your-bucket-name>
export TF_LOCK_TABLE=<your-dynamodb-lock-table>
export AWS_REGION=<aws-region>  # e.g. us-east-1

aws s3 mb s3://$TF_STATE_BUCKET --region $AWS_REGION
aws dynamodb create-table       --table-name $TF_LOCK_TABLE       --attribute-definitions AttributeName=LockID,AttributeType=S       --key-schema AttributeName=LockID,KeyType=HASH       --billing-mode PAY_PER_REQUEST       --region $AWS_REGION
```

## 1) Initialize Terraform
```bash
cd terraform/root
terraform init       -backend-config="bucket=$TF_STATE_BUCKET"       -backend-config="key=dev/terraform.tfstate"       -backend-config="region=$AWS_REGION"       -backend-config="dynamodb_table=$TF_LOCK_TABLE"
```

## 2) Configure variables
Edit `terraform/envs/dev.tfvars` (example file included) and set everything (no hardcoding elsewhere).
Key fields:
- `region`, `name_prefix`
- `vpc_cidr`, `public_subnet_cidr`, `private_subnet_cidr`, `internal_domain`
- `key_name` (EC2 key pair *name*), `admin_cidr` (your IP/cidr)
- AMI selection: set `rhel_ami_id` **or** the `rhel_ami_owners` + `rhel_ami_name_regex`
- toggles: `enable_satellite` (true), `satellite_public` (false is best practice), `enable_aap`

## 3) Plan & Apply
```bash
terraform plan  -var-file=../envs/dev.tfvars -out=tfplan
terraform apply -auto-approve tfplan
```

## 4) Export outputs for Ansible
```bash
../../scripts/export_tf_to_ansible.sh
```

## 5) Ansible setup
- Ensure AWS credentials and `AWS_REGION` env var are set (needed by the dynamic inventory plugin).
- Install required Ansible collections:
  ```bash
  ansible-galaxy collection install -r ansible/requirements.yml
  ```

## 6) SSH ProxyJump (optional but handy)
Add to `~/.ssh/config`:
```sshconfig
Host lab-bastion
    HostName <bastion_public_ip from terraform output>
    User <bastion_user from dev.tfvars>
    IdentityFile ~/.ssh/<your-key>.pem
    IdentitiesOnly yes

Host 10.*
    User <linux_user from dev.tfvars>
    ProxyJump lab-bastion
    IdentityFile ~/.ssh/<your-key>.pem
    IdentitiesOnly yes
```

## 7) Test inventory & connectivity
Dynamic inventory (AWS EC2 plugin) is configured at `ansible/inventories/aws_ec2.yml`.
Make sure you've tagged instances via Terraform (we do) and you have permission to list EC2.

```bash
export AWS_REGION=<same region as tf>
ANSIBLE_HOST_KEY_CHECKING=False ansible -i ansible/inventories/aws_ec2.yml all -m ping -vv
```

## 8) Bootstrap Satellite (if enabled)
```bash
ansible-playbook -i ansible/inventories/aws_ec2.yml ansible/playbooks/satellite_bootstrap.yml
```

## Destroy (clean up)
```bash
cd terraform/root
terraform destroy -var-file=../envs/dev.tfvars -auto-approve
```

## Notes
- Satellite is private by default (`satellite_public=false`). Public exposure increases risk; if you must, lock to your `admin_cidr` on 443.
- All parameters (CIDRs, instance types, AMIs, users, counts) are variables—no hardcoding in code.
- The Ansible dynamic inventory uses `amazon.aws.aws_ec2` (install via `ansible/requirements.yml`).
