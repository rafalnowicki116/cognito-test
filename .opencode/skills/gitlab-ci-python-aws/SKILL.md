---
name: gitlab-ci-python-aws
description: Build GitLab CI for Python and Terraform on AWS with clear stage boundaries and safe deployment flow.
compatibility: opencode
---

## When to use
Use when editing `.gitlab-ci.yml`, CI templates, or pipeline structure for this stack.

## Pipeline mental model
- `prechecks` fail fast on formatting, linting, and static validation.
- `tests` verify Python behavior before packaging or infrastructure promotion.
- `build` creates the application artifact only after code quality gates pass.
- `plan` validates infrastructure changes and shows what Terraform would change.
- `apply` is the controlled deployment step and must depend on successful earlier stages.

## Recommended stages
- Use this order: `prechecks -> tests -> build -> plan -> apply`.
- Keep `prechecks` fast and deterministic so developers get feedback early.
- Keep `tests` focused on unit and integration checks that should block promotion.
- Keep `build` separate from tests so artifact creation is explicit and reproducible.
- Keep `plan` separate from `apply` so infrastructure intent is reviewed before execution.
- Keep `apply` manual or protected for shared environments unless there is a strong reason to automate it.

## Stage responsibilities

### prechecks
- Run Python linting and any fast static checks here.
- Run Terraform formatting and validation checks here when infrastructure changes are present.
- Do not put slow test suites in `prechecks`.

### tests
- Run `pytest` here.
- Publish JUnit reports and coverage artifacts if available.
- Keep test jobs blocking for later stages.

### build
- Build the Python package or deployable artifact here.
- Publish build artifacts so later jobs use the exact same output.
- Do not rebuild the same artifact again in deploy stages.

### plan
- Run Terraform `plan` only after prechecks and tests have passed.
- Keep `plan` scoped to infrastructure changes with `rules:changes` when possible.
- Publish the plan output as an artifact if the team reviews it in GitLab.

### apply
- Run Terraform `apply` only after a successful `plan`.
- Restrict `apply` to protected branches, protected environments, or manual approval.
- Keep deployment credentials and environment selection explicit.

## Rules
- Install Python dependencies from `pyproject.toml` using `uv`.
- Use `needs:` to make job dependencies explicit instead of relying only on stage order.
- Use `rules:changes` to avoid running Terraform jobs when no infrastructure files changed.
- Keep artifacts and reports explicit so later jobs and reviewers can inspect results.
- Use the same Terraform root consistently, for example `infrastructure/`.

## Minimal pipeline template

```yaml
stages:
  - prechecks
  - tests
  - build
  - plan
  - apply

default:
  image: python:3.12
  before_script:
    - pip install uv
    - uv sync --dev
  cache:
    key:
      files:
        - uv.lock
        - pyproject.toml
    paths:
      - .venv/
      - .cache/uv/

ruff_check:
  stage: prechecks
  script:
    - uv run ruff check .

terraform_validate:
  stage: prechecks
  image: hashicorp/terraform:1.9.8
  script:
    - terraform -chdir=infrastructure fmt -check -recursive
    - terraform -chdir=infrastructure init -backend=false
    - terraform -chdir=infrastructure validate
  rules:
    - changes:
        - infrastructure/**/*.tf
        - .gitlab-ci.yml

unit_tests:
  stage: tests
  needs:
    - ruff_check
  script:
    - uv run pytest -q --junitxml=report.xml
  artifacts:
    when: always
    reports:
      junit: report.xml

build_package:
  stage: build
  needs:
    - unit_tests
  script:
    - uv build
  artifacts:
    paths:
      - dist/

terraform_plan:
  stage: plan
  image: hashicorp/terraform:1.9.8
  needs:
    - terraform_validate
    - unit_tests
  script:
    - terraform -chdir=infrastructure init
    - terraform -chdir=infrastructure plan -out=tfplan
  artifacts:
    paths:
      - infrastructure/tfplan
  rules:
    - changes:
        - infrastructure/**/*.tf
        - .gitlab-ci.yml

terraform_apply:
  stage: apply
  image: hashicorp/terraform:1.9.8
  needs:
    - terraform_plan
  script:
    - terraform -chdir=infrastructure apply -auto-approve tfplan
  when: manual
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
```

## Template notes
- Keep `ruff_check` and `terraform_validate` in `prechecks` because they are fast and should fail early.
- Keep `unit_tests` in `tests` because behavior validation should happen before packaging.
- Keep `build_package` after tests so the produced artifact comes from validated code.
- Keep `terraform_plan` after validation and tests so infrastructure review happens only on a healthy codebase.
- Keep `terraform_apply` manual on the default branch unless your deployment model requires stronger automation.

## Local GitLab validation
- If GitLab is self-hosted locally in Docker, validate pipeline changes there before sending them to the main remote repository.
- A practical setup is: local GitLab container + local GitLab Runner with Docker executor + a test project that mirrors the repository.
- Push feature branches to the local GitLab project first, confirm the pipeline passes, and only then push or open PRs on the main platform.
- If you want local review flow, create Merge Requests in the local GitLab web UI against the local project branch structure.
- Treat the local GitLab instance as a safe CI rehearsal environment, not as the source of truth for production collaboration unless the team explicitly uses it that way.

### Reusable local GitLab stack

```yaml
version: "3.9"

services:
  gitlab:
    image: gitlab/gitlab-ce:17.5.1-ce.0
    container_name: local-gitlab
    hostname: gitlab.local
    restart: unless-stopped
    ports:
      - "8929:8929"
      - "2224:22"
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://localhost:8929'
        gitlab_rails['gitlab_shell_ssh_port'] = 2224
    volumes:
      - gitlab_config:/etc/gitlab
      - gitlab_logs:/var/log/gitlab
      - gitlab_data:/var/opt/gitlab
    shm_size: "256m"

  gitlab-runner:
    image: gitlab/gitlab-runner:alpine
    container_name: local-gitlab-runner
    restart: unless-stopped
    depends_on:
      - gitlab
    volumes:
      - gitlab_runner_config:/etc/gitlab-runner
      - /var/run/docker.sock:/var/run/docker.sock

volumes:
  gitlab_config:
  gitlab_logs:
  gitlab_data:
  gitlab_runner_config:
```

- Start it with `docker compose up -d`.
- Open `http://localhost:8929`, finish the initial GitLab setup, create a local project, and register the runner.
- Add a dedicated remote such as `local-gitlab` and push branches there for CI rehearsal and local Merge Requests.

## Anti-patterns - DON'T DO IT!!!
- Mix linting, tests, packaging, Terraform plan, and deployment in one giant job.
- Run `apply` before `plan` or without a protected/manual gate.
- Rebuild the package in deploy jobs instead of reusing build artifacts.
- Hide important job dependencies and hope stage order alone explains the flow.
- Run Terraform jobs on every commit when nothing under `infrastructure/` changed.
- Make `apply` available from every branch for shared environments.

## Validation
- Run a pipeline on a feature branch and confirm `prechecks`, `tests`, and `build` pass.
- For infrastructure changes, confirm `terraform_validate` and `terraform_plan` run in the expected order.
- Confirm `terraform_apply` is gated correctly for the target branch/environment.
- If a local GitLab instance exists, validate the branch and MR flow there before sending changes to the primary hosted repository.
