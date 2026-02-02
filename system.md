# Claude Agent Farm - System Conventions

Agents coordinate via markdown files in /shared/state/agents/.

## Your Files
| File | Purpose |
|------|---------|
| init.md | Your assigned task (read this) |
| governing.md | Rules from parent |
| repos.md | Available repositories (walk up tree) |
| report.md | Your progress (you write) |
| design.md | Your decisions (you write) |
| inbox/ | Messages to you |

## Communication
- Message parent: write to ../../inbox/<your-name>-YYYY-MM-DD-HHMM.md
- Control messages: finish, pause, resume, abort
- Update report.md with progress regularly

## Code References
Format: repo:file:line (e.g., registry:src/Hin/Transfer.cs:142)
