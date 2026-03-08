# nowicra-opencode-skills

Reusable OpenCode skills and `AGENTS.md` bootstrap for new or existing repositories.

## Included skills

- `python-project-structure`
- `python-design-patterns`
- `python-unit-tests`
- `python-production-code`
- `vue-frontend-typescript`
- `terraform-aws`
- `gitlab-ci-python-aws`

## Option 1: Create a new repository from the template

Create a new repository from this GitHub template:

```bash
gh repo create my-new-project --template rafalnowicki116/nowicra-opencode-skills --private
```

Clone it:

```bash
gh repo clone rafalnowicki116/my-new-project
```

## Option 2: Copy only the OpenCode setup into an existing repository

Clone the target repository and enter it:

```bash
gh repo clone rafalnowicki116/my-existing-project
cd my-existing-project
```

Run the bootstrap script from a local clone of this template repository:

```bash
/path/to/nowicra-opencode-skills/scripts/bootstrap-opencode-skills.sh
```

Or pass the target path explicitly:

```bash
/path/to/nowicra-opencode-skills/scripts/bootstrap-opencode-skills.sh /path/to/my-existing-project
```

If you do not have this repository cloned locally yet:

```bash
gh repo clone rafalnowicki116/nowicra-opencode-skills
./nowicra-opencode-skills/scripts/bootstrap-opencode-skills.sh /path/to/my-existing-project
```

## What the bootstrap script copies

- `AGENTS.md`
- `.opencode/skills/`

## Important behavior

- The script overwrites `AGENTS.md`
- The script replaces the full `.opencode/skills/` directory
