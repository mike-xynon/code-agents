# Available Repositories

Clone these into your private home directory (`~/repos/`).

**Do NOT use `/shared/repos/`** — that volume is reserved for future use.

## Clone Command

```bash
mkdir -p ~/repos && cd ~/repos
git clone git@bitbucket.org:xynon/<bitbucket-repo>.git <local-name>
```

## Repository List

| Local Name | Bitbucket Repo | Description |
|------------|----------------|-------------|
| nuget | `xynon/nq-nugetlibraries` | Shared NuGet packages (NQ.Copilot, etc.) |
| portal | `xynon/portal` | Main portal application (UI + API) |
| registry | `xynon/nq.trading` | Trading registry (HIN, positions, transactions) |
| registry-web | `xynon/nq.trading.backoffice.web` | Registry admin interface |
| platform | `xynon/nq.platform` | Core platform services |
| reporting | `xynon/nq.reporting` | Reporting services |
| devops | `xynon/nq.devops` | DevOps infrastructure |
| morrison | `xynon/nq.morrison` | Morrison integration |

## Examples

```bash
# Clone the registry repo
git clone git@bitbucket.org:xynon/nq.trading.git ~/repos/registry

# Clone multiple repos
cd ~/repos
git clone git@bitbucket.org:xynon/nq-nugetlibraries.git nuget
git clone git@bitbucket.org:xynon/portal.git portal
```

## SSH Key

SSH key for Bitbucket should already be configured in your container at `~/.ssh/`.
