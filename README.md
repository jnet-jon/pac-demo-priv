# Policy as Code: Your Pipeline Says No

A 5-7 minute lightning talk demo. A Terraform PR opens SSH to the internet, the pipeline blocks it with a human-readable message, one line gets fixed, and the pipeline goes green.

No cloud account or credentials are needed. Both tools scan the Terraform source statically, so nothing is ever deployed.

## What's in here

| Path | Purpose |
|---|---|
| `terraform/main.tf` | Security group with the planted misconfiguration (SSH open to `0.0.0.0/0`) |
| `policy/network.rego` | Custom org policy in OPA/Rego: no admin ports to the internet, every SG needs an owner tag |
| `.github/workflows/policy-check.yml` | GitHub Actions running Conftest (your rules) and Checkov (industry baseline) on every PR |
| `scripts/demo.sh` | Runs the same checks locally, as a backup if Wi-Fi or GitHub misbehaves |

## Setup (do this the night before)

1. Push this folder to a new GitHub repo (public is fine, nothing sensitive in it).
2. Settings → Branches → add a protection rule on `main` that requires both status checks: **Org policy (OPA / Conftest)** and **Baseline checks (Checkov)**. This is what makes the merge button go grey and is the money shot.
3. Commit `main.tf` to `main` with the SSH rule pointing at a safe CIDR (see "The fix" below), so the repo starts clean.
4. Create a branch `feature/admin-ssh` that changes the SSH CIDR to `0.0.0.0/0`. Open the PR but **don't** let it run yet (or let it run and just show the result, which is the safer option).
5. Install locally for the backup: `pip install checkov` and Conftest from its GitHub releases page or `brew install conftest`.
6. Record a 60-second screen capture of the full flow. If anything breaks live, play it.

## Run sheet (about 6 minutes)

| Time | Beat | What you do / say |
|---|---|---|
| 0:00 | Hook | "Show of hands: who has reviewed a Terraform PR at 4:55 on a Friday?" |
| 0:30 | The challenge | Put the `aws_security_group` block on screen, large font. "You're the reviewer. You have 20 seconds. Shout it out if you see the problem." |
| 1:00 | Reveal | Someone usually spots it. If they don't, that's the point: "Humans miss things. Pipelines don't get tired." |
| 1:30 | The pipeline says no | Switch to the PR. Show both red checks and the greyed-out merge button. Open the Conftest log and read the message out loud: it names the resource, the port, and the fix. |
| 2:30 | Two layers | Briefly: Checkov is the industry baseline (hundreds of built-in checks). Conftest/OPA is *your* rules in about 30 lines of Rego. Flash `network.rego` for 10 seconds. |
| 3:30 | The fix | Edit one line in the GitHub web editor, commit to the branch. |
| 4:00 | Green | Checks re-run (about 30-60 sec). Fill the wait with: "This runs on every PR, for every team, at 3 a.m., forever." Show green and the merge button. |
| 5:00 | Takeaway | "Policy as code turns your security standard from a PDF nobody reads into a gate nobody can skip. Start with three rules, not three hundred." |
| 5:30 | Close | Show the repo link / QR code. "Fork it and break it." |

## The misconfiguration

```hcl
ingress {
  description = "SSH for admins"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"] # <-- spot the problem?
}
```

## The fix (one line)

```hcl
  cidr_blocks = ["10.0.0.0/16"]
```

Or say: "even better, delete the rule and use SSM Session Manager". That gets a nod from the cloud folks.

## Bonus beat (if you have 60 extra seconds)

Delete the `owner` tag and push. Conftest blocks it with the second rule. It shows policy as code isn't only about security; it enforces governance and accountability too.

## Talking points for Q&A

- **"Can developers just bypass it?"** Not if branch protection requires the checks and admins are included in the rule. Exceptions go through a reviewed suppression (`#checkov:skip=` with a reason), which gives you an audit trail.
- **"Static scan vs. plan scan?"** This demo scans HCL. Scanning `terraform plan -out` as JSON catches values that come from variables and modules; it's the next step in a real pipeline.
- **"What about runtime drift?"** Pair this with a cloud-side guardrail (AWS Config, Azure Policy, SCPs). Pipeline checks stop new mistakes; cloud policy catches click-ops.
- **"Azure / GCP?"** Same pattern. Checkov covers all three; the Rego rule just changes resource names (`azurerm_network_security_rule`, `google_compute_firewall`).
