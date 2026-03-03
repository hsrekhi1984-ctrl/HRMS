# HRMS Terraform (Azure)

This Terraform project provisions:
- Resource Group (optional create)
- Log Analytics Workspace
- Azure Container Registry (ACR)
- Azure Kubernetes Service (AKS)

## Why this repo now avoids state drift problems

If a resource already exists in Azure but is not in Terraform state, `terraform apply` can fail with errors such as "resource already exists".

This repo includes:
- `create_resource_group` toggle to use an existing RG instead of forcing creation.
- An `azurerm` remote backend scaffold (`backend.tf` + `backend.hcl.example`) so state can be kept centrally and safely.

## 1) Configure remote state (recommended)

1. Copy and edit backend config:

```bash
cp backend.hcl.example backend.hcl
```

2. Initialize backend:

```bash
terraform init -backend-config=backend.hcl
```

3. Reconfigure backend in future changes if needed:

```bash
terraform init -reconfigure -backend-config=backend.hcl
```

## 2) Reuse an existing resource group

In your tfvars:

```hcl
create_resource_group = false
resource_group_name   = "rg-hrms-dev"
```

## 3) Import existing resources into state (if already created manually)

Example for resource group:

```bash
terraform import azurerm_resource_group.this[0] /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-hrms-dev
```

> Only use this command when `create_resource_group = true` (because `azurerm_resource_group.this` uses `count`).

If you run in existing-RG mode (`create_resource_group = false`), Terraform uses `data.azurerm_resource_group.existing[0]` and no RG import is needed.

## 4) Daily safe workflow

```bash
terraform plan -out tfplan
terraform apply tfplan
```

## 5) Useful state operations

Inspect state:

```bash
terraform state list
```

Show one resource in state:

```bash
terraform state show azurerm_kubernetes_cluster.this
```

If an incorrect binding exists:

```bash
terraform state rm <resource_address>
```

Then import the correct Azure resource ID.
