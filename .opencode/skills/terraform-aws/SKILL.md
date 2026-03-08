---
name: terraform-aws
description: Build reusable AWS Terraform modules with secure defaults, composition, and validation.
compatibility: opencode
---

## When to use
Use for Terraform changes on AWS.

## Terraform mental model for AWS engineers
- A `resource` is one managed object, such as a VPC, subnet, security group, IAM role, or RDS instance.
- A `module` is a reusable building block made of one or more resources.
- A `root module` is the directory where you run `terraform plan` and `terraform apply`; it composes reusable modules for one environment or deployment target.
- `variables` are module inputs, `outputs` are module outputs, and `locals` are internal computed values.
- `state` is Terraform's record of what it manages; treat it as critical deployment metadata.
- Think of Terraform as desired state for AWS infrastructure, not as an imperative provisioning script.

## Module library pattern
- Prefer reusable modules over copy-pasted resource blocks.
- Use a standard module layout: `terraform.tf`/`versions.tf`, `providers.tf`, `main.tf`, `variables.tf`, `outputs.tf`, `locals.tf`, `README.md`, `examples/complete`.
- Keep module interfaces explicit and stable.

## Terraform style guide
- Use two-space indentation and run `terraform fmt` before review.
- Keep variables and outputs ordered alphabetically.
- Use lowercase snake_case names for resources, variables, locals, and outputs.
- Use descriptive singular resource names; use `main` only when one obvious instance exists.
- Keep meta-arguments first, regular arguments next, nested blocks after, and `lifecycle` last.

## Rules
- Keep Terraform in a dedicated top-level area such as `infrastructure/` unless the repository already uses a different, well-established convention.
- Split reusable modules into their own directories, each with at least `main.tf`, `variables.tf`, and `outputs.tf`.
- Pin Terraform and provider versions.
- Use semantic versioning for shared modules.
- Every variable must include `type` and `description`.
- Add validation blocks for constrained values.
- Output key attributes needed for module composition.
- Every output must include `description`; mark sensitive outputs with `sensitive = true`.
- Avoid hardcoded secrets and environment-specific values.
- Use locals for computed values and defaults.
- Prefer `for_each` when instances need stable keys or distinct values; use `count` only for simple on/off creation or very uniform repetition.
- Tag all resources consistently (for example `Environment`, `ManagedBy`, `Owner`).
- Keep plans deterministic and review drift carefully.

## Recommended repository layout

```text
infrastructure/
  modules/
    vpc/
      main.tf
      variables.tf
      outputs.tf
      versions.tf
      README.md
      examples/complete/
    app/
      main.tf
      variables.tf
      outputs.tf
      versions.tf
      README.md
      examples/complete/
  envs/
    dev/
      main.tf
      providers.tf
      versions.tf
      variables.tf
      terraform.tfvars
    prod/
      main.tf
      providers.tf
      versions.tf
      variables.tf
      terraform.tfvars
```

- Keep reusable building blocks in `infrastructure/modules/`.
- Keep deployable root stacks in `infrastructure/envs/` or `infrastructure/live/`.
- Keep environment-specific values in the root stack, not inside reusable modules.
- Do not mix reusable module code and environment-specific deployment code in the same directory.

## Composition rules
- Compose higher-level stacks from small focused modules (for example `vpc`, `security`, `database`, `compute`).
- Keep cross-module wiring explicit via outputs and inputs.
- Keep examples runnable and aligned with real module interfaces.
- Prefer a root stack per environment or deployment target that composes reusable modules rather than duplicating resources.

## Mini example

### Root stack

```hcl
module "vpc" {
  source = "../../modules/vpc"

  name       = "example-dev"
  cidr_block = "10.0.0.0/16"
}

module "app" {
  source = "../../modules/app"

  name               = "example-dev"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
}
```

### What this means
- The root stack decides which modules are used for `dev` or `prod`.
- The `vpc` module owns VPC details and exposes outputs.
- The `app` module consumes those outputs instead of rediscovering or hardcoding infrastructure values.

## Security and state hygiene
- Enable encryption at rest where supported.
- Prefer private networking defaults and least-privilege access rules.
- Enable service logging/monitoring where relevant.
- Never commit Terraform state, plans, or `.terraform/` directories.
- Commit `.terraform.lock.hcl` for provider lock reproducibility.

## Testing
- Validate module behavior with `terraform test` or Terratest.
- Keep at least one `examples/complete` scenario per reusable module.

## Recommended workflow
- Start with or update a reusable module.
- Add or update `examples/complete` so the module can be exercised in a realistic way.
- Run `terraform fmt`, `terraform init`, and `terraform validate`.
- Review the plan from the root stack that uses the module.
- Apply only after the plan is deterministic and understandable.

## Validation
- `terraform fmt -check -recursive`
- `terraform init -backend=false`
- `terraform validate`
- `tflint` (if configured)
- `tfsec` or `checkov` (if configured)
- In GitLab CI, run Terraform validation directly before `plan` and `apply` stages.

## Anti-patterns - DON'T DO IT!!!
- Put all AWS resources for every concern into one giant `main.tf`.
- Copy-paste the same resource blocks across `dev`, `stage`, and `prod` instead of composing modules.
- Hardcode ARNs, subnet IDs, account-specific values, secrets, or region-specific identifiers that should come from variables or data flow.
- Mix reusable module code and environment-specific root stack code in one directory.
- Commit `terraform.tfstate`, `.terraform/`, or saved plan files to the repository.
- Use `count` when stable instance identity matters and `for_each` would model the resources more safely.
- Hide important cross-module dependencies instead of wiring them through explicit outputs and inputs.

## Definition of done
- Module inputs/outputs are documented and validated.
- Example usage works without local ad-hoc edits.
- Plan is deterministic and free of avoidable drift.
- Style guide conventions are followed consistently across files.
