# Agent Farm Vision

## What This Is

Following up on the CTO agent structure I mentioned—I've now containerized it. Each agent runs in its own Docker instance with SSH access to Bitbucket, contributes code via PRs from isolated repos, and coordinates through a separate markdown repository tracked in git. The orchestration is just file-based message passing that I can inspect and version control. When an agent drifts or hits a gap, I iterate with it directly and then get it to update its own internal rules.

## Landscape

Cognition (Devin), Factory, and a few open-source projects are working on similar multi-agent coding setups, mostly with heavier coordination frameworks. Mine is intentionally minimal. The constraint remains that I'm still the relay between agents—they can't initiate sessions or talk directly. But the containerization means I can run parallel workstreams without the previous annoying breakdowns, and the git-tracked coordination is so far working pretty well.

## How This Differs

**Cognition** is ticket-based—you tag Devin in Slack, it does a task. Great for discrete work items, but it's operating at the task level.

**Factory** has specialized agents for specific job types (review, test, migrate), but they're still task-executors, not concept-holders.

**Ours** keeps agents holding context at the concept level—a CTO agent that understands the vision and coordinates, child agents that can research, design, and iterate on big problems over multiple sessions. The agents aren't closing tickets; they're maintaining domain understanding and refining it through conversation. The potential scale factor is larger because the unit of work isn't a task—it's the workstream from the highest level.
