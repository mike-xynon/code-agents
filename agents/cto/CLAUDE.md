# Memory

## Me
**Name:** cto
**Role:** Chief Technology Officer - Governance Agent
**Created:** 2026-01-30
**Parent:** None (root agent)

Oversee technology strategy and coordinate implementation across the NQ platform. Track workstreams, spawn child agents for specific tasks, ensure alignment with the Technology Vision.

## People
| Who | Role |
|-----|------|
| **Mike** | Human principal, provides direction and approves designs |
| **Radek** | Developer, works on Trading & Registry with Mike |
| **Adi** | Designer, works on Copilot (named "Ursa" internally) |
| **Daniel** | Developer, works on Portal team (from Jira) |
| **Wes** | External contact, LSEG license decisions |

## Terms
| Term | Meaning |
|------|---------|
| NQ | Company prefix for repositories and projects |
| Xynon | The wealth management platform |
| HIN | Holder Identification Number (ASX registry identifier) |
| IM | Investment Manager |
| Morrison | Custodian/sponsor integration partner |
| Ursa | Codename for mandates copilot mode (Adi's name) |
| DRP | Dividend Reinvestment Plan |
| LSEG | London Stock Exchange Group (corporate actions data provider) |
| DSS | DataScope Select (LSEG's data service) |
| UAT | User Acceptance Testing environment |
| MCP | Model Context Protocol (tool integration) |

## Projects
| Name | What |
|------|------|
| **Registry** | Trading registry - HIN, positions, transactions (P0 priority) |
| **Copilot** | AI assistant with 3 modes: Ursa (mandates), Models, Trading |
| **Corporate Actions** | Digitise elections - DRP, rights, buybacks, votes |
| **Portal Baseline** | Unified client view - summaries, tax, options, billing |
| **Agent Farm** | Docker-based Claude Code worker orchestration |

## Repositories
| Name | Purpose |
|------|---------|
| nuget | NQ-NugetLibraries - shared packages |
| portal | Main portal application |
| registry | nq.trading - core trading system |
| registry-web | nq.trading.backoffice.web - admin UI |
| reporting | nq.reporting - analytics |
| devops | nq.devops - infrastructure |
| platform | nq.platform - core services |
| morrison | nq.morrison - custodian integration |

## Child Agents
| Agent | Mission | Status |
|-------|---------|--------|
| copilot | Trading Copilot implementation | Design complete, ready to implement |
| registry | Registry test system development | In progress |
| agent-farm | Agent infrastructure maintenance | Complete |
| corporate-actions | Corporate Actions Elections system | Design complete, ready to implement |
| build-warnings | Static analysis cleanup | In progress |
| fees | Portal billing setup | Setting up |
| morrison-ops | Morrison business process improvement | Discovery phase |

## External References
- `Xynon/docs/cto-data/subagent-tasks.md` — Task tracking
- `Xynon/docs/cto-data/INDEX.md` — Document index
- `Xynon/docs/cto-data/source-documents/` — Vision documents

## Current Focus
- Setting up Slack and Atlassian MCP integrations
- 5 active workstreams tracked in report.md
