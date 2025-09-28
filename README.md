# rh-enterprise-cloud-lab

A reproducible AWS lab environment for Red Hat work. It stands up a VPC with public/private subnets, an Internet Gateway, a NAT Gateway, a bastion host, and private lab nodes. Ansible uses the AWS dynamic inventory and connects to private nodes via the bastion.

---

## ✨ What you get

* **Terraform** to provision: VPC, subnets, route tables, IGW, NAT + EIP, security groups, bastion, and private EC2 nodes
* **Ansible** dynamic inventory (`aws_ec2`) wired for bastion **ProxyJump**
* **Idempotent**: destroy and re-create the same lab from versioned code

---

## ⚡ TL;DR (Quickstart)

```bash
# auth to AWS (env vars or SSO/profile)
export AWS_PROFILE=your-profile

# 1) Initialize Terraform in the root module
terraform -chdir=terraform/root init

# 2) Provide variables (see sample below) then validate & plan
terraform -chdir=terraform/root validate
terraform -chdir=terraform/root plan -out tf.plan

# 3) Apply
terraform -chdir=terraform/root apply tf.plan

# 4) Grab bastion IP (works even if output is a list)
BASTION_IP=$(terraform -chdir=terraform/root output -json bastion_public_ip | jq -r '.[0]')

# 5) Ansible inventory ping
ansible -i ansible/inventories/aws_ec2.yml all -m ping -vvv
```

---

## ✅ Prerequisites

* AWS account with permissions for **EC2, VPC, EIP, NAT**
* **AWS CLI v2** configured (`aws configure` or SSO) and a default or named **profile**
* **Terraform ≥ 1.3**
* **Ansible ≥ 2.14** plus Python packages: `boto3`, `botocore`
* **jq**, **ssh**, **git**
* An SSH private key on your machine and the corresponding **public key** referenced by Terraform (key pair in AWS or cloud-init)

> **Tip:** If you use profiles, export `AWS_PROFILE=your-profile` before running commands below.

---

## 📁 Repo layout (key paths)

```
terraform/
  root/                 # entrypoint for terraform init/plan/apply/destroy
  modules/
    network/            # vpc, subnets, routes, igw, nat, eip, sg
    compute/            # bastion + private nodes
ansible/
  inventories/
    aws_ec2.yml         # dynamic inventory plugin config
  group_vars/
    all.yml             # ansible_user, proxyjump, key path, etc.
```

> Exact filenames may vary slightly. If in doubt, open `terraform/root` and `ansible/inventories/aws_ec2.yml`.

---

## 🔧 Configure

1. **AWS Region & profile**

   * Decide your region (e.g., `us-east-1`).
   * Optionally set a profile: `export AWS_PROFILE=your-profile`.

2. **Your admin IP (CIDR)**

   * Controls who can SSH to **bastion**.
   * Quick set (mac/linux):

     ```bash
     export ADMIN_CIDR="$(curl -s https://checkip.amazonaws.com)/32"
     ```

3. **Terraform variables**

   * Open `terraform/root/variables.tf` to see required inputs. Use a `terraform.tfvars` file so commands stay clean.

### 📄 Sample `terraform.tfvars`

```hcl
# adjust names to match your actual variables
project_name   = "rh-enterprise-cloud-lab"
region         = "us-east-1"
vpc_cidr       = "10.60.0.0/16"
public_cidrs   = ["10.60.0.0/24"]
private_cidrs  = ["10.60.1.0/24", "10.60.2.0/24"]
admin_cidr     = "${ADMIN_CIDR}"
key_name       = "your-aws-keypair-name"
instance_type  = "t3.large"
node_count     = 3
ami_owner      = "137112412989" # Amazon Linux 2 (example)
tags = {
  Project = "rh-enterprise-cloud-lab"
  Owner   = "you"
  Env     = "lab"
}
```

4. **(Optional) Remote state (S3 + DynamoDB)**

   * Recommended for teams and state locking.
   * Example `terraform/root/backend.tf` then run `terraform init -migrate-state`.

5. **AWS Region & profile**

   * Decide your region (e.g., `us-east-1`).
   * Optionally set a profile: `export AWS_PROFILE=your-profile`.

6. **Your admin IP (CIDR)**

   * This controls who can SSH to the **bastion**.
   * Put it in Terraform variables (preferred) or export temporarily:

     ```bash
     # Optional helper (mac/linux):
     export ADMIN_CIDR="$(curl -s https://checkip.amazonaws.com)/32"
     ```

7. **Terraform variables**

   * Open `terraform/root/variables.tf` to see required inputs (names may vary). Common examples:

     ```hcl
     # examples only — match actual variable names in variables.tf
     admin_cidr   = "YOUR.PUBLIC.IP/32"   # who can SSH to bastion
     vpc_cidr     = "10.60.0.0/16"
     public_cidrs = ["10.60.0.0/24"]
     private_cidrs= ["10.60.1.0/24", "10.60.2.0/24"]
     key_name     = "your-aws-keypair-name" # or use user_data to inject an SSH pubkey
     node_count   = 3
     instance_type= "t3.large"
     tags = { Project = "rh-enterprise-cloud-lab" }
     ```
   * If a `terraform.tfvars.example` exists, copy to `terraform.tfvars` and fill in.

8. **(Optional) Remote state (S3 + DynamoDB)**

   * Recommended for teams and safety locks.
   * Example `terraform/root/backend.tf`:

     ```hcl
     terraform {
       backend "s3" {
         bucket         = "your-tf-state-bucket"
         key            = "rh-enterprise-cloud-lab/root/terraform.tfstate"
         region         = "us-east-1"
         dynamodb_table = "your-tf-locks"
         encrypt        = true
       }
     }
     ```
   * Create the bucket/table once, then `terraform init -migrate-state`.

---

## 🚀 Deploy

From the repo root (or anywhere) run Terraform from the **root** directory:

```bash
terraform -chdir=terraform/root init
terraform -chdir=terraform/root fmt -check
terraform -chdir=terraform/root validate
terraform -chdir=terraform/root plan -out tf.plan
terraform -chdir=terraform/root apply tf.plan
```

**Expected outputs**

```bash
terraform -chdir=terraform/root output
# For list/tuple outputs:
terraform -chdir=terraform/root output -json bastion_public_ip | jq -r '.[0]'
```

**ASCII Architecture**

```
Internet
   |
[Admin IP /32]
   |
[IGW]───[Public Subnet]───[Bastion]
                  \
                   \
                [NAT]
                   |
            [Private Subnets]
             /       |      \
          node1   node2   nodeN
```

> SGs: SSH (22) only from `admin_cidr` to Bastion; SSH from Bastion SG to private nodes. ICMP optional.

From the repo root (or anywhere) run Terraform from the **root** directory:

```bash
terraform -chdir=terraform/root init
terraform -chdir=terraform/root validate
terraform -chdir=terraform/root plan -out tf.plan
terraform -chdir=terraform/root apply tf.plan
```

Useful outputs:

```bash
terraform -chdir=terraform/root output
# If an output is a list/tuple, use -json and jq, e.g.:
terraform -chdir=terraform/root output -json bastion_public_ip | jq -r '.[0]'
```

> Provisioning creates the VPC, networking, bastion, and private nodes with SG rules that allow SSH from your `admin_cidr` to the bastion, and SSH from the bastion SG to the private nodes.

---

## 🔐 SSH (via bastion)

Add a helpful SSH config (\~/.ssh/config):

```sshconfig
Host bastion
  HostName <BASTION_PUBLIC_IP>
  User ec2-user
  IdentityFile ~/.ssh/your-private-key.pem

Host 10.*
  User ec2-user
  IdentityFile ~/.ssh/your-private-key.pem
  ProxyJump bastion
```

Test:

```bash
ssh bastion
# or jump directly to a private node
ssh 10.60.1.23
```

> Replace `ec2-user` if your AMI uses a different default user.

---

## 🤖 Ansible dynamic inventory

**Install requirements**

```bash
python3 -m pip install --upgrade boto3 botocore ansible
```

**Inventory plugin** (`ansible/inventories/aws_ec2.yml`):

```yaml
plugin: aws_ec2
regions: [ "us-east-1" ]
filters:
  tag:Project: rh-enterprise-cloud-lab
hostnames: [ "private-ip-address" ]
compose:
  ansible_host: private_ip_address
keyed_groups:
  - key: tags.Role
```

**Group vars** (`ansible/group_vars/all.yml`):

```yaml
ansible_user: ec2-user
ansible_ssh_private_key_file: "~/.ssh/your-private-key.pem"
ansible_ssh_common_args: "-o ProxyJump=ec2-user@<BASTION_PUBLIC_IP>"
```

**Example base playbook** (`ansible/site.yml`):

```yaml
- hosts: all
  gather_facts: true
  become: true
  tasks:
    - name: Ensure packages are up to date
      package:
        name: [git, vim, curl]
        state: present
```

**Run**

```bash
ansible -i ansible/inventories/aws_ec2.yml all -m ping -vvv
ansible-playbook -i ansible/inventories/aws_ec2.yml ansible/site.yml
```

---

## 🧹 Destroy

When you’re done:

```bash
terraform -chdir=terraform/root destroy
```

**If destroy fails (dependency errors), manual order**

1. Delete **NAT Gateways**
2. Release/disassociate **EIPs**
3. Remove **RT associations** that reference NAT/IGW
4. Delete **private subnets**, then **public subnets**
5. Detach & delete **IGW**
6. Delete **VPC**

---

## 🩺 Troubleshooting

**SSH: Permission denied (publickey)**

* Wrong user for AMI, bad key path/permissions, or key not in agent.

**SSH: "Connection timed out during banner exchange" or weird port 65535**

* Routing/SG issue or broken ProxyJump. Verify `ssh bastion` first.

**Ansible: UNREACHABLE / auth method basic requires a password**

* Set `ansible_user`, `ansible_ssh_private_key_file`, and confirm discovery via `aws_ec2` filters/tags.

**Terraform destroy: IGW detach `DependencyViolation`**

* Public addresses still mapped (usually **NAT/EIP**). See manual order above.

**NAT create failed – EIP already associated**

* Allocation ID in use elsewhere; pick a new EIP or disassociate.

**`terraform output -raw` fails (tuple)**

* Use `-json` + `jq`, e.g.: `| jq -r '.[0]'`.

**Cost tips**

* NAT Gateway is the pricey bit. Keep labs short-lived; prefer 1 AZ for cheapest runs.

---

**SSH: Permission denied (publickey)**

* Wrong user for the AMI, key path incorrect, or key not loaded into your agent.

**SSH: "Connection timed out during banner exchange" or weird port 65535 in errors**

* Usually a routing/SG issue or a broken ProxyJump chain. Verify you can `ssh bastion` first, then try the private node.

**Ansible: UNREACHABLE / auth method basic requires a password**

* Ensure `ansible_user` and `ansible_ssh_private_key_file` are set, and the dynamic inventory discovers the nodes (correct tags/region).

**Terraform destroy: IGW detach fails with `DependencyViolation`**

* Some public addresses (usually **NAT/EIP**) are still mapped.
* Fix order: delete NAT Gateways → release/disassociate EIPs → remove route associations → delete subnets → detach/delete IGW → delete VPC.

**Terraform apply: NAT create failed – EIP already associated**

* The allocation ID is in-use elsewhere. Use a new EIP or disassociate the existing one.

**`terraform output -raw` fails (tuple)**

* Use `-json` and `jq`, e.g.: `... | jq -r '.[0]'`.

**General tip**

* Avoid manual console changes to resources managed by Terraform. If you must, **import** them or adjust state with care.

---

## 🔒 Security notes

* Keep `admin_cidr` tight (your IP only).
* Prefer private nodes reachable only via bastion; avoid exposing SSH directly.
* Consider **AWS SSM Session Manager** as an alternative to SSH (no inbound 22 needed):

  * Install SSM agent/iam instance profile, then: `aws ssm start-session --target <instance-id>`.

---

## 🏷️ Versioning & Conventions

* Tag known-good baselines:

```bash
git tag -a v0.1 -m "Known-good baseline"
git push origin v0.1
```

* **Naming**: Prefix resources with `${var.project_name}` for easy cleanup.

---

## 🧭 CI & Quality (optional)

* Add a **Makefile** for repeatable commands:

```makefile
.PHONY: init plan apply destroy
init:; terraform -chdir=terraform/root init
fmt:;  terraform -chdir=terraform/root fmt -recursive
validate:; terraform -chdir=terraform/root validate
plan:; terraform -chdir=terraform/root plan -out tf.plan
apply:; terraform -chdir=terraform/root apply tf.plan
destroy:; terraform -chdir=terraform/root destroy
```

* Pre-commit hooks: `terraform fmt`, `terraform validate`, `tflint`, `ansible-lint`.
* GitHub Actions: run format/validate on PRs.

---

## 📌 Roadmap (optional)

* Remote state (S3 + DynamoDB) with state locking
* Toggleable modules for OpenShift or Red Hat Satellite
* CI checks: `terraform fmt`, `terraform validate`, `ansible-lint`
* SSM-only access (close port 22 entirely)

---

**Happy automating!**
