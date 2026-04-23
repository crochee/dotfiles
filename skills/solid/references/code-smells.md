# Code Smells & Anti-Patterns

> **Language-Agnostic Note:** These principles apply to any programming language. Adapt to your language's idioms while respecting the underlying concepts.

## What Are Code Smells?

Indicators that something MAY be wrong. Not bugs, but design problems that make code hard to understand, change, or test.

## The Five Categories

### 1. Bloaters

Code that has grown too large.

| Smell | Symptom | Refactoring |
|-------|---------|-------------|
| **Long Function** | > 10 lines, multiple responsibilities | Extract smaller functions |
| **Large Component** | > 50 lines, multiple responsibilities | Split by single responsibility |
| **Long Parameter List** | > 3 parameters | Group related parameters into object |
| **Data Clumps** | Same group of variables appear together | Extract dedicated type |
| **Primitive Obsession** | Primitives instead of small types | Wrap in domain objects |

### 2. Object-Orientation Abusers

Misuse of abstraction principles.

| Smell | Symptom | Refactoring |
|-------|---------|-------------|
| **Switch Statements** | Type checking, repeated if/else or switch | Replace with polymorphism/strategy |
| **Parallel Inheritance** | Adding one type requires adding another | Merge hierarchies |
| **Refused Bequest** | Type doesn't use parent capabilities | Replace inheritance with delegation |
| **Alternative Classes** | Different interfaces for same concept | Unify with common interface |

### 3. Change Preventers

Code that makes changes difficult.

| Smell | Symptom | Refactoring |
|-------|---------|-------------|
| **Divergent Change** | One type changed for many reasons | Extract class by responsibility |
| **Shotgun Surgery** | One change requires modifying many types | Move related code together |
| **Parallel Inheritance** | (see above) | Merge hierarchies |

### 4. Dispensables

Code that can be removed.

| Smell | Symptom | Refactoring |
|-------|---------|-------------|
| **Comments** | Explaining bad code | Rename, extract to clarify intent |
| **Duplicate Code** | Copy-paste repeated logic | Extract common function |
| **Dead Code** | Unreachable, unused code | Delete |
| **Speculative Generality** | "Just in case" abstractions | Delete (YAGNI) |
| **Lazy Type** | Type that does almost nothing | Inline into caller |

### 5. Couplers

Excessive coupling between types.

| Smell | Symptom | Refactoring |
|-------|---------|-------------|
| **Feature Envy** | Function uses another type's data extensively | Move function to that type |
| **Inappropriate Intimacy** | Types know too much about each other's internals | Enforce encapsulation |
| **Message Chains** | a.getB().getC().getD() | Hide delegate behind method |
| **Middle Man** | Type only delegates to another | Remove intermediate type |

---

## The Seven Most Common Code Smells

### 1. Long Function

**Symptom:** Function > 10 lines, doing multiple things.

**Refactor:** Split into smaller, single-purpose functions.

### 2. Large Component

**Symptom:** Component with many responsibilities, > 50 lines.

**Refactor:** Split by single responsibility into multiple focused types.

### 3. Feature Envy

**Symptom:** Function uses another type's data more than its own.

**Refactor:** Move the function to the type that owns the data it uses.

### 4. Primitive Obsession

**Symptom:** Using primitives for domain concepts that have meaning.

**Refactor:** Create dedicated types with validation (Email, UserId, Money, etc.).

### 5. Switch Statements

**Symptom:** Switching on type, repeated across codebase.

**Refactor:** Replace with polymorphism or strategy pattern.

### 6. Inappropriate Intimacy

**Symptom:** Types know too much about each other's internals.

**Refactor:** Tell objects what to do, don't ask for data and manipulate it.

### 7. Speculative Generality

**Symptom:** "Just in case" abstractions that aren't used.

**Refactor:** YAGNI - delete unused abstractions until actually needed.

---

## Prevention Strategies

1. **Follow Essential Practices** - Rules prevent most smells
2. **Practice TDD** - Tests reveal design problems early
3. **Review in pairs** - Fresh eyes catch smells
4. **Refactor continuously** - Don't let smells accumulate
5. **Apply SOLID** - Prevents structural smells
6. **Use static analysis** - Tools catch common issues

---

## When You Find a Smell

1. **Confirm it's a problem** - Not all smells need fixing
2. **Ensure test coverage** - Before refactoring
3. **Refactor in small steps** - Keep tests passing
4. **Commit frequently** - Easy to revert if needed
