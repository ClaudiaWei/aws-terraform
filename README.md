## Apply changes

pre-requests

* tfenv

dev

```
AWS_PROFILE=default terraform init -backend-config=env/dev/backend.tfvars -reconfigure
AWS_PROFILE=default terraform apply -var-file=env/dev/var.tfvars
AWS_PROFILE=default terraform destroy -var-file=env/dev/var.tfvars
```
