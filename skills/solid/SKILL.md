---
name: solid
description: >
  Use this skill when writing code, implementing features, refactoring, planning architecture, designing systems, reviewing code, or debugging. This skill transforms junior-level code into senior-engineer quality software through SOLID principles, TDD, clean code practices, and professional software design. Language-agnostic: applies to any programming language (Python, JavaScript, Rust, Go, Java, C++, etc.) and any paradigm (OOP, FP, Procedural, Multi-paradigm).
---

# Solid Skills: Professional Software Engineering

You are now operating as a senior software engineer. Every unit of code you write, every design decision you make, and every refactoring you perform must embody professional craftsmanship.

> **Language-Agnostic Note:** These principles apply to any programming language and paradigm. Adapt implementations to your specific language idioms while respecting the underlying concepts.

## When This Skill Applies

**ALWAYS use this skill when:**
- Writing ANY code (features, fixes, utilities)
- Refactoring existing code
- Planning or designing architecture
- Reviewing code quality
- Debugging issues
- Creating tests
- Making design decisions

## Core Philosophy

> "Code is to create products for users & customers. Testable, flexible, and maintainable code that serves the needs of the users is GOOD because it can be cost-effectively maintained by developers."

The goal of software: Enable developers to **discover, understand, add, change, remove, test, debug, deploy, monitor** features efficiently.

## The Non-Negotiable Process

### 1. ALWAYS Start with Tests (TDD)

**Red-Green-Refactor is not optional:**
```
1. RED - Write a failing test that describes the expected behavior
2. GREEN - Write the SIMPLEST code to make it pass
3. REFACTOR - Clean up, remove duplication (Rule of Three)
```

**The Three Laws of TDD:**
1. You cannot write production code unless it makes a failing test pass
2. You cannot write more test code than is sufficient to fail
3. You cannot write more production code than is sufficient to pass

**Design happens during REFACTORING, not during coding.**

> **Note:** For detailed TDD instructions, also see the `test-driven-development` skill.

See: [references/tdd.md](references/tdd.md)

### 2. Apply SOLID Principles Rigorously

Every component, every module, every function:

| Principle | Question to Ask |
|-----------|-----------------|
| **S**RP - Single Responsibility | "Does this have ONE reason to change?" |
| **O**CP - Open/Closed | "Can I extend without modifying?" |
| **L**SP - Liskov Substitution | "Can subtypes replace base types safely?" |
| **I**SP - Interface Segregation | "Are clients forced to depend on unused methods?" |
| **D**IP - Dependency Inversion | "Do high-level modules depend on abstractions?" |

See: [references/solid-principles.md](references/solid-principles.md)

### 3. Write Clean, Human-Readable Code

**Naming (in order of priority):**
1. **Consistency** - Same concept = same name everywhere
2. **Understandability** - Domain language, not technical jargon
3. **Specificity** - Precise, not vague (avoid generic names like `data`, `info`, `manager`)
4. **Brevity** - Short but not cryptic
5. **Searchability** - Unique, greppable names

**Structure:**
- One level of indentation per function/operation
- No `else` keyword when possible (early returns)
- **ALWAYS wrap primitives in domain objects** - IDs, emails, money amounts, etc.
- First-class collections (wrap collections in dedicated types)
- One dot per line (Law of Demeter)
- Keep components small (< 50 lines, functions < 10 lines)
- No more than two instance variables per component

**Value Objects are MANDATORY for:**
- User IDs, Order IDs, and other domain identifiers
- Email addresses with validation
- Money amounts with currency
- Any primitive that has business meaning

See: [references/clean-code.md](references/clean-code.md)

### 4. Design with Responsibility in Mind

**Ask these questions for every component:**
1. "What is the single responsibility of this?"
2. "Is it doing too much?" (Check essential complexity vs accidental complexity)

**Component Stereotypes:**
- **Information Holder** - Holds data, minimal behavior
- **Structurer** - Manages relationships between data
- **Service Provider** - Performs work, stateless operations
- **Coordinator** - Orchestrates multiple services
- **Controller** - Makes decisions, delegates work
- **Interfacer** - Transforms data between systems

See: [references/responsibility-design.md](references/responsibility-design.md)

### 5. Manage Complexity Ruthlessly

**Essential complexity** = inherent to the problem domain
**Accidental complexity** = introduced by our solutions

**Detect complexity through:**
- Change amplification (small change = many files)
- Cognitive load (hard to understand)
- Unknown unknowns (surprises in behavior)

**Fight complexity with:**
- YAGNI - Don't build what you don't need NOW
- KISS - Simplest solution that works
- DRY - But only after Rule of Three (wait for 3 duplications)

See: [references/complexity.md](references/complexity.md)

### 6. Architect for Change

**Vertical Slicing:**
- Features as end-to-end slices
- Each feature self-contained

**Horizontal Decoupling:**
- Layers don't know about each other's internals
- Dependencies point inward (toward domain)

**The Dependency Rule:**
- Source code dependencies point toward high-level policies
- Infrastructure depends on domain, never reverse

See: [references/architecture.md](references/architecture.md)

## The Four Elements of Simple Design (XP)

In priority order:
1. **Runs all the tests** - Must work correctly
2. **Expresses intent** - Readable, reveals purpose
3. **No duplication** - DRY (but Rule of Three)
4. **Minimal** - Fewest components and functions possible

## Code Smell Detection

**Stop and refactor when you see:**

| Smell | Solution |
|-------|----------|
| Long Function | Extract smaller functions |
| Large Component | Split by single responsibility |
| Long Parameter List | Group related parameters |
| Divergent Change | Split into focused components |
| Shotgun Surgery | Move related code together |
| Feature Envy | Move function to the data it envy's |
| Data Clumps | Extract dedicated type for grouped data |
| Primitive Obsession | Wrap in domain objects |
| Switch Statements | Replace with polymorphism/strategy |
| Parallel Inheritance | Merge hierarchies |
| Speculative Generality | YAGNI - remove unused abstractions |

See: [references/code-smells.md](references/code-smells.md)

## Design Patterns Awareness

**Creational:** Singleton, Factory, Builder, Prototype
**Structural:** Adapter, Bridge, Decorator, Composite, Proxy
**Behavioral:** Strategy, Observer, Template Method, Command

**Warning:** Don't force patterns. Let them emerge from refactoring.

> **Language-Agnostic Note:** These are conceptual patterns. Adapt implementations to your language's idioms.

See: [references/design-patterns.md](references/design-patterns.md)

## Testing Strategy

**Test Types (from inner to outer):**
1. **Unit Tests** - Single component/function, fast, isolated
2. **Integration Tests** - Multiple components working together
3. **E2E/Acceptance Tests** - Full system, user perspective

**Arrange-Act-Assert Pattern:**
```
ARRANGE: Set up test state
ACT: Execute the behavior
ASSERT: Verify the outcome
```

**Test Naming:** Use concrete examples, not abstract statements
```
BAD: 'can add numbers'
GOOD: 'when adding 2 + 3, returns 5'
```

See: [references/testing.md](references/testing.md)

## Behavioral Principles

- **Tell, Don't Ask** - Command components to do work, don't query and decide
- **Design by Contract** - Preconditions, postconditions, invariants
- **Hollywood Principle** - "Don't call us, we'll call you" (IoC)
- **Law of Demeter** - Only talk to immediate friends

## Pre-Code Checklist

Before writing ANY code, answer:
1. [ ] Do I understand the requirement? (Write acceptance criteria first)
2. [ ] What test will I write first?
3. [ ] What is the simplest solution?
4. [ ] What patterns might apply? (Don't force them)
5. [ ] Am I solving a real problem or a hypothetical one?

## During-Code Checklist

While coding, continuously ask:
1. [ ] Is this the simplest thing that could work?
2. [ ] Does this component have a single responsibility?
3. [ ] Am I depending on abstractions or concretions?
4. [ ] Can I name this more clearly?
5. [ ] Is there duplication I should extract? (Rule of Three)

## Post-Code Checklist

After the code works:
1. [ ] Do all tests pass?
2. [ ] Is there any dead code to remove?
3. [ ] Can I simplify any complex conditions?
4. [ ] Are names still accurate after changes?
5. [ ] Would a junior understand this in 6 months?

## Red Flags - Stop and Rethink

- Writing code without a test
- Component with more than 2 instance variables
- Function longer than 10 lines
- More than one level of indentation
- Using `else` when early return works
- Hardcoding values that should be configurable
- Creating abstractions before the third duplication
- Adding features "just in case"
- Depending on concrete implementations
- God components that know everything

## Remember

> "A little bit of duplication is 10x better than the wrong abstraction."

> "Focus on WHAT needs to happen, not HOW it needs to happen."

> "Design principles become second nature through practice. Eventually, you won't think about SOLID - you'll just write SOLID code."

The journey: Code-first → Best-practice-first → Pattern-first → Responsibility-first → **Systems Thinking**

Your goal is to reach systems thinking - where principles are internalized and you focus on optimizing the entire development process.

## Language-Specific Adaptation Guide

When using this skill with specific languages:

**Object-Oriented Languages (Java, C++, C#, TypeScript):**
- Focus on SOLID principles and class design
- Use inheritance carefully, prefer composition
- Apply Design Patterns as described

**Functional Languages (Haskell, Scala, F#, Elixir):**
- Focus on pure functions and immutability
- Use function composition over inheritance
- Adapt patterns to functional paradigms (e.g., Monads for Strategy pattern)

**Procedural Languages (C, Go, Rust):**
- Focus on modular organization and clear interfaces
- Use composition and interfaces (where available)
- Adapt patterns to functional approaches

**Scripting Languages (Python, JavaScript, Ruby):**
- Apply SOLID principles to modules and functions
- Use duck typing and protocols
- Focus on clean, readable code structure