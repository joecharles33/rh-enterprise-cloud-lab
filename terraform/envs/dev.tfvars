region              = "us-east-1"
name_prefix         = "rh-lab-dev"

vpc_cidr            = "10.60.0.0/16"
public_subnet_cidr  = "10.60.1.0/24"
private_subnet_cidr = "10.60.2.0/24"
internal_domain     = "corp.example.internal"

key_name            = "REPLACE_ME_KEYPAIR_NAME"
admin_cidr          = "REPLACE.ME.IP/32"
linux_user          = "ec2-user"
bastion_user        = "ec2-user"

# Provide either a specific AMI ID or owner+name filter for your region
rhel_ami_id         = ""
rhel_ami_owners     = []
rhel_ami_name_regex = ""

count_rhel_targets  = 2
enable_aap          = false

enable_satellite    = true
satellite_public    = false

tags = {
  Project = "RH-Enterprise-Cloud-Lab"
  Owner   = "YourName"
}
