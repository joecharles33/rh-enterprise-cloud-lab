    TFDIR=terraform/root

    init:
	cd $(TFDIR) && terraform init 	  -backend-config="bucket=$(BUCKET)" 	  -backend-config="key=$(KEY)" 	  -backend-config="region=$(REGION)" 	  -backend-config="dynamodb_table=$(LOCK)"

    plan:
	cd $(TFDIR) && terraform plan -var-file=../envs/dev.tfvars -out=tfplan

    apply:
	cd $(TFDIR) && terraform apply -auto-approve tfplan && ../../scripts/export_tf_to_ansible.sh

    destroy:
	cd $(TFDIR) && terraform destroy -var-file=../envs/dev.tfvars -auto-approve
