# ADR-006: Ansible Playbook vs Role Decision Criteria

## Status

**Accepted**

## Context

### Problem Statement

The Ansible automation codebase in `ansible/` currently mixes different types of automation artifacts without clear criteria for when to create a playbook versus a role. This leads to inconsistency: some procedures are written as playbooks while others are over-engineered as roles with unnecessary complexity (defaults, templates, handlers). Clear guidelines are needed to make this decision straightforward for future contributions.

### Constraints and Assumptions

#### Constraints

- Must integrate with the existing inventory structure (`inventory/hosts.yml`)
- Must follow the existing playbook layout (`playbooks/*.yml`)
- Must be compatible with standard Ansible tooling (`ansible-playbook`)

#### Assumptions

- Most automation in this homelab is one-shot or procedural (upgrades, migrations, bootstraps)
- Reuse across multiple hosts is rare — most playbooks target specific VMs
- The team prefers simplicity over extensibility for internal tooling
- No plans to publish roles to Ansible Galaxy

### Requirements That Influenced the Decision

1. **Operational Clarity**: It should be immediately obvious whether a given task belongs in a playbook or a role by examining its structure
2. **Low Ceremony**: Creating new automation should not require creating multiple files and directories
3. **Maintainability**: Simple, linear tasks should not carry the overhead of role scaffolding
4. **Consistency**: The decision criteria must be objective enough to avoid subjective debates

## Decision

**Use playbooks for linear, one-shot procedures. Use roles only when the full role feature set is needed.**

### Criteria

Use a **playbook** when the task sequence is:

| Criterion    | Question                                                                                     | If Yes → Playbook |
| ------------ | -------------------------------------------------------------------------------------------- | ----------------- |
| Linearity    | Is the task sequence fixed with no branching logic?                                          | ✅                 |
| Reuse        | Will this be called by multiple playbooks or target multiple hosts with different variables? | ❌ (role)          |
| Templates    | Does the task require Jinja2 templates for config files?                                     | ❌ (role)          |
| Handlers     | Does the task need notify/flush_handlers for state changes?                                  | ❌ (role)          |
| Variables    | Does the task need `defaults/main.yml` or `vars/main.yml`?                                   | ❌ (role)          |
| Distribution | Will this be shared outside the homelab (Galaxy, Fork)?                                      | ❌ (role)          |

If **any** of the right-column conditions are true → use a **role**.

## Playbook Indicators

✅ **One-shot procedures** — migrations, upgrades, bootstraps  
✅ **Single target** — one host or a fixed group of hosts with no variable-driven behavior  
✅ **Linear task sequence** — upgrade → verify → reboot (no branching, no loops over data)  
✅ **No config file generation** — no `.j2` templates needed  
✅ **No state-driven notifications** — no handlers needed  

**Examples in this homelab:**

- `proxmox-backup-upgrade.yml` — linear upgrade procedure, one target
- `hermes.yml` — delegates to a role, but the playbook itself is thin

## Role Indicators

✅ **Reuse across contexts** — called by multiple parent playbooks with different `hosts:` values  
✅ **Variable-driven behavior** — host/group vars control what gets installed or configured  
✅ **Template generation** — renders config files from Jinja2 templates  
✅ **Handler notifications** — service restarts on config changes  
✅ **Published unit** — intended to be distributable via Galaxy or a fork  

**Examples outside this homelab:**

- `ansible-role-nginx` — templated config, handlers, variable defaults
- `ansible-role-postgresql` — version selection via variables, service handlers

## Consequences

### Positive

1. **Clear Threshold**: The criteria table above gives an objective, answer-the-questions decision process — no judgment calls needed
2. **Low Friction for New Automation**: Adding a new one-shot procedure means creating one `.yml` file, not a directory tree
3. **Reduced Overhead**: No empty `defaults/`, `vars/`, `templates/`, `handlers/` directories for simple playbooks
4. **Obvious Intent**: When reading `playbooks/`, you know every file there is a linear, single-target procedure

### Negative

1. **Limited Extensibility**: If a playbook grows to need variables or templates later, it must be refactored into a role — more work than designing it as a role upfront
2. **No Shared Variables**: Playbooks cannot import `vars_files` from a role-like structure — variables must be defined inline or in `group_vars`
3. **Duplication Risk**: If two playbooks need the same 3 tasks, those tasks must be copied rather than shared via a role

### Risks and Mitigation

#### Risk 1: Playbook Creep
**Risk**: Playbooks accumulate tasks over time and become unwieldy, making the linear assumption false  
**Probability**: Medium  
**Impact**: A playbook that should have been a role becomes hard to maintain  
**Mitigation**:
- Apply the criteria table before adding any new task to an existing playbook
- If branching logic, new variables, or templates are needed → refactor to a role immediately

#### Risk 2: Inconsistent Application
**Risk**: Without enforcement, contributors may default to roles for everything "just in case"  
**Probability**: Low  
**Impact**: The codebase accumulates empty role scaffolding, defeating the purpose of the guideline  
**Mitigation**:
- Document this ADR and reference it in pull request reviews
- During code review, challenge any role that has no `defaults/`, `vars/`, `templates/`, or `handlers/` usage

## Alternatives Considered

### Alternative 1: Always Use Roles

**Pros:**
- Maximum flexibility for future changes
- Consistent structure across the codebase
- Aligns with Ansible Galaxy conventions

**Cons:**
- Overhead for one-shot procedures (5+ files for a 4-task sequence)
- Discourages writing small, focused automation
- Violates YAGNI — building for reuse that never comes

**Why Rejected**: This homelab has no Galaxy publishing intent and very few reuse cases. The ceremony does not justify the benefit.

### Alternative 2: No Formal Guidelines

**Pros:**
- Maximum freedom for contributors
- No documentation to maintain

**Cons:**
- Inconsistent structure — some things are roles, some are playbooks, with no clear reasoning
- New contributors have no guidance on which to choose
-容易导致 over-engineering (roles for everything) or under-engineering (everything in `site.yml`)

**Why Rejected**: Without guidelines, the codebase will drift toward inconsistency over time. A 5-minute decision criteria table prevents hours of debate later.

## Comparison Matrix

| Criterion                         | Playbook | Always Roles | No Guidelines |
| --------------------------------- | -------- | ------------ | ------------- |
| **Low ceremony for one-shots**    | ✅        | ❌            | ✅             |
| **Supports complex reuse**        | ❌        | ✅            | ✅             |
| **Consistent structure**          | ✅        | ✅            | ❌             |
| **Low overhead (files per unit)** | ✅ (1)    | ❌ (5-8)      | ✅ (1)         |
| **Clear intent to reader**        | ✅        | ✅            | ❌             |
| **Flexible for growth**           | ❌        | ✅            | ✅             |
| **Effort to maintain**            | Low      | Medium       | Low           |

## References

### Ansible Documentation
- [Playbook Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html)
- [Handlers](https://docs.ansible.com/ansible/latest/user_guide/playbooks_handlers.html)

### Related ADRs

---

## Decision Metadata

**Decision Date**: June 2026  
**Last Updated**: June 6, 2026  
**Status**: Accepted  
**Decision Owner**: Eduard  
**Related ADRs**: ADR-001 (OpenTofu vs Terraform)