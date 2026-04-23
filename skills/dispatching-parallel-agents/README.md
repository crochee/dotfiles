# Dispatching Parallel Agents

Delegate independent tasks to specialized parallel agents for concurrent execution.

## When to Use

- 3+ test files failing with different root causes
- Multiple subsystems broken independently
- Each problem can be understood without context from others
- No shared state between investigations

## When NOT to Use

- Failures are related (fix one might fix others)
- Need to understand full system state
- Agents would interfere with each other

## Core Principle

Dispatch one agent per independent problem domain. Let them work concurrently. Each agent gets a focused task with clear boundaries.

## Usage

1. **Identify independent domains** - Group failures by what's broken
2. **Create focused agent tasks** - Each agent gets specific scope, clear goal, constraints
3. **Dispatch in parallel** - Let all agents work at the same time
4. **Review and integrate** - Read summaries, verify fixes, integrate changes

## Key Benefits

- **Parallelization** - Multiple investigations happen simultaneously
- **Focus** - Each agent has narrow scope, less context to track
- **Independence** - Agents don't interfere with each other
- **Speed** - 3 problems solved in time of 1
