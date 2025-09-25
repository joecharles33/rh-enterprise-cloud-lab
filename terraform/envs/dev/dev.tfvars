aws_region    = "us-east-1"
project       = "rh-enterprise-cloud-lab"
env           = "dev"

# These come from your environment:
admin_cidr    = "47.204.49.233/32"
key_pair_name = "a3-redhat-lab-key"

bastion_instance_type = "t3.micro"

# Non-prod HA footprint
node_groups = {
  # Controllers (HA)
  ansible   = { count = 2, instance_type = "t3.large",     role = "ansible",   subnet_type = "private" }

  # EDA (HA)
  eda       = { count = 2, instance_type = "t3.large",     role = "eda",       subnet_type = "private" }

  # AAP DB (lab: single EC2 Postgres) – for true HA switch to RDS later
  aap-db    = { count = 1, instance_type = "t3.medium",    role = "aap-db",    subnet_type = "private" }

  # Private Automation Hub
  pah       = { count = 1, instance_type = "t3.large",     role = "pah",       subnet_type = "private" }

  # Targets / execution nodes
  rhel      = { count = 4, instance_type = "t3.large",     role = "rhel",      subnet_type = "private" }

  # Satellite (public) – single is fine for lab
  satellite = { count = 1, instance_type = "m6i.2xlarge",  role = "satellite", subnet_type = "public"  }
}
