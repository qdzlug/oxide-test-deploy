
## Deployment Test

This Terraform setup provisions:
- A VPC and subnet using required `ipv4_block`
- A configurable number of instances

## 🛠 Prerequisites
- Access to an Oxide rack and credentials
- A project
- The UUID of an ubuntu image in the project
 

## ⚙️ Usage

```bash
export OXIDE_HOST="https://api.oxide.computer"
export OXIDE_API_KEY="your-api-key"

cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars # Add in your values...

tofu init
tofu plan -var-file="terraform.tfvars"
tofu apply -var-file="terraform.tfvars"
```
