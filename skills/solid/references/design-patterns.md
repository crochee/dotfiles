# Design Patterns

> **Language-Agnostic Note:** These are conceptual patterns applicable to any language. Adapt implementations to your language's idioms while respecting the underlying concepts.

## What Are Design Patterns?

Reusable solutions to common design problems. A shared vocabulary for discussing design.

## WARNING: Don't Force Patterns

> "Let patterns emerge from refactoring, don't force them upfront."

Patterns should solve problems you HAVE, not problems you MIGHT have.

## When to Use Patterns

1. **You recognize the problem** - You've seen it before
2. **The pattern fits** - Not forcing it
3. **It simplifies** - Doesn't add unnecessary complexity
4. **Team understands it** - Shared knowledge

---

## Creational Patterns

### Singleton

**Purpose:** Ensure only one instance exists.

**When to use:** Global configuration, connection pools, logging.

**Concept:** Single point of access to shared resource.

### Factory

**Purpose:** Create objects without specifying exact type.

**When to use:** Object creation logic is complex, or varies by type.

**Concept:** Centralize creation logic, hide complexity from callers.

### Builder

**Purpose:** Construct complex objects step by step.

**When to use:** Objects with many optional parts, fluent interfaces.

**Concept:** Separate construction from representation.

### Prototype

**Purpose:** Create new objects by cloning existing ones.

**When to use:** Object creation is expensive, or you need copies with slight variations.

**Concept:** Copy from template rather than building from scratch.

---

## Structural Patterns

### Adapter

**Purpose:** Make incompatible interfaces work together.

**When to use:** Integrating different systems, legacy code, third-party libraries.

**Concept:** Bridge between two incompatible interfaces.

### Decorator

**Purpose:** Add behavior to objects dynamically.

**When to use:** Adding features without modifying existing code, stackable behaviors.

**Concept:** Wrap and enhance, layer behaviors.

### Proxy

**Purpose:** Control access to an object.

**When to use:** Lazy loading, access control, logging, caching.

**Concept:** Stand-in for another object, controlling access to it.

### Composite

**Purpose:** Treat individual objects and compositions uniformly.

**When to use:** Tree structures, hierarchies, part-whole relationships.

**Concept:** Uniform interface for single items and collections.

---

## Behavioral Patterns

### Strategy

**Purpose:** Define a family of algorithms, make them interchangeable.

**When to use:** Multiple ways to do something, switchable at runtime.

**Concept:** Encapsulate algorithms, make them interchangeable.

### Observer

**Purpose:** Notify multiple objects about state changes.

**When to use:** Event systems, pub/sub, reactive updates.

**Concept:** Publish-subscribe communication between components.

### Template Method

**Purpose:** Define algorithm skeleton, let subtypes override steps.

**When to use:** Common algorithm with varying implementation details.

**Concept:** Fixed algorithm structure, flexible implementation details.

### Command

**Purpose:** Encapsulate a request as an object.

**When to use:** Undo/redo, queuing, logging actions, deferred execution.

**Concept:** Actions as first-class objects.

---

## Pattern Awareness

### The Four-Dimensional Lens

When analyzing code/libraries, ask:
1. **What problem does it solve?** (Creational, Structural, Behavioral)
2. **What scope?** (Component-level, System-level)
3. **When is it applied?** (Compile-time, Runtime)
4. **How coupled?** (Tight, Loose)

This helps recognize patterns even in unfamiliar code.

---

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| **God Component** | One component does everything | Split by responsibility |
| **Spaghetti Code** | Tangled, no clear structure | Organize into layers/modules |
| **Golden Hammer** | Using one pattern for everything | Match pattern to problem |
| **Premature Optimization** | Optimizing before needed | YAGNI, profile first |
| **Copy-Paste Programming** | Duplication | Extract common abstraction (Rule of Three) |

---

## Adapting Patterns Across Paradigms

### Object-Oriented Languages (Java, C++, C#, TypeScript)
- Design Patterns as described are native fit
- Use inheritance carefully, prefer composition

### Functional Languages (Haskell, Scala, F#, Elixir)
- Strategy → Functions passed as parameters
- Observer → Event streams, reactive programming
- Command → Functions as values, closures
- Adapter → Functions that transform data

### Procedural Languages (C, Go, Rust)
- Focus on module organization
- Use interfaces/protocols where available
- Patterns become organizational principles

### Scripting Languages (Python, JavaScript, Ruby)
- Duck typing enables flexible pattern application
- Higher-order functions replace some pattern needs
- Mixins and protocols provide composition
