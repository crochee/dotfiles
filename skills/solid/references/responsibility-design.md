# Responsibility-Driven Design

> **Language-Agnostic Note:** These principles apply to any programming language and paradigm. Adapt to your language's idioms while respecting the underlying concepts.

## The Core Insight

**Components are defined by their responsibilities, not their data.**

This is the fundamental shift: instead of asking "what data does this component hold?", ask "what is this component responsible for?"

---

## Finding Responsibilities

### Start with Language of the Domain

1. **Nouns** in requirements → candidate components
2. **Verbs** → candidate responsibilities/methods
3. **Domain concepts** → value types

### Ask Three Questions

Each component should answer:
- **What does this component know?** (its responsibilities/data)
- **What does this component do?** (its behavior)
- **What does this component decide?** (its business rules)

---

## Component Stereotypes

Every component fits one (or two) stereotypes. Knowing the stereotype helps design correctly.

| Stereotype | Purpose | Examples |
|------------|---------|----------|
| **Information Holder** | Knows things, stores data | User, Product, Configuration |
| **Structurer** | Maintains relationships between data | OrderItems, UserGroup |
| **Service Provider** | Performs work, stateless | PaymentProcessor, EmailSender |
| **Coordinator** | Orchestrates other components | OrderFulfillmentService |
| **Controller** | Makes decisions, delegates work | CheckoutController, OrderController |
| **Interfacer** | Transforms data between systems | UserAPIAdapter, DataMapper |

### The Two Questions

For every component, ask:
1. **"What stereotype is this?"** - Which pattern applies?
2. **"Is it doing too much?"** - Check against Single Responsibility

If you can't answer clearly, the component needs refactoring.

---

## Tell, Don't Ask

**Command components to do work. Don't interrogate them and compute yourself.**

```
BAD: Asking, then doing
if (account.getBalance() >= amount) {
  newBalance = account.getBalance() - amount;
  account.setBalance(newBalance);
  // More logic here...
}

GOOD: Telling
const result = account.withdraw(amount);
```

The component that has the data should have the behavior.

---

## Composition Over Inheritance

**Prefer composing behavior over inheriting it.**

### Why Inheritance is Problematic

- Tight coupling between parent and child
- Fragile base class problem
- Forces "is-a" relationship that may not fit
- Difficult to change parent without breaking children

### When to Use Inheritance

- True "is-a" relationship (rare in well-designed systems)
- Framework requirements
- Template Method pattern (intentional)

### Prefer Composition

```
BAD: Inheritance
PremiumUser extends User { getDiscount() → 20 }

GOOD: Composition
User has a DiscountPolicy
user.discountPolicy.calculate() → 20

Now discount behavior is pluggable:
- PremiumDiscount
- StandardDiscount
- NoDiscount
```

---

## The Law of Demeter (Principle of Least Knowledge)

**Only talk to your immediate friends.**

A function/component should only interact with:
1. Itself
2. Parameters passed to it
3. Objects it creates
4. Its direct components

```
BAD: Reaching through objects
order.getCustomer().getAddress().getCity()

GOOD: Ask the immediate friend
order.getShippingCity()
```

This reduces coupling - changes to Address don't ripple through all callers.

---

## Encapsulation

**Hide internal details, expose behavior.**

### Levels of Encapsulation

1. **Data** - Private fields, no direct access
2. **Implementation** - How things work internally
3. **Type** - Concrete type hidden behind interface
4. **Design** - Architectural decisions hidden from clients

```
BAD: Exposed internals
order.items.push(item);        // Client can corrupt state
order.total = -999;           // Oops!

GOOD: Encapsulated
order.addItem(item);           // Validation happens
order.getTotal();              // Returns immutable value
```

---

## Polymorphism

**Replace conditional logic with type-based behavior.**

```
BAD: Type checking
function calculateShipping(method: string, value: number): number {
  if (method === 'standard') return value < 50 ? 5 : 0;
  if (method === 'express') return 15;
  if (method === 'overnight') return 25;
  throw new Error('Unknown method');
}

GOOD: Polymorphism
interface ShippingStrategy {
  calculateCost(orderValue: number): number;
}

class StandardShipping implements ShippingStrategy { ... }
class ExpressShipping implements ShippingStrategy { ... }

// Usage - no conditionals
function calculateShipping(strategy: ShippingStrategy, value: number): number {
  return strategy.calculateCost(value);
}
```

---

## Value Types vs Entity Types

### Value Types

- Defined by their attributes (no identity)
- Immutable after creation
- Comparable by value
- Examples: Money, Email, Address, DateRange

```
Characteristics:
- No identity (two Money(10, "USD") are equal)
- Immutable (create new instances on change)
- Used to model descriptive concepts
```

### Entity Types

- Have identity (survives attribute changes)
- Usually mutable (via methods)
- Comparable by identity
- Examples: User, Order, Product

```
Characteristics:
- Has unique identity (same attributes ≠ same entity)
- Mutable state (but encapsulated)
- Used to model things that have lifecycle
```

---

## Aggregates

A cluster of related components treated as a single unit for data changes.

### Key Rules

1. **One aggregate root** - The main component that controls access
2. **External code only references the root** - Never hold references to internal components
3. **Root enforces invariants** - Validates changes for the entire cluster

```
Example: Order Aggregate
- Order is the aggregate root
- External code: order.addItem(), order.removeItem()
- NOT: order.items.push() (bypasses validation!)
- Root enforces: total doesn't exceed limit, items are valid, etc.
```

### Why Aggregates Matter

- **Consistency boundary** - Changes are atomic
- **Invariant enforcement** - Business rules protected
- **Reduced coupling** - External code doesn't know internal structure

---

## Responsibilities Across Paradigms

### Object-Oriented (Java, C++, C#, TypeScript)
- Components bundle data + behavior
- Use inheritance sparingly, prefer composition
- Encapsulation is key

### Functional (Haskell, Scala, F#, Elixir)
- Functions as first-class citizens
- Data immutable, behavior through functions
- Components emerge from function composition

### Procedural (C, Go, Rust)
- Modules organize related functions + data
- Interfaces define contracts
- Composition through modules and functions

### Scripting (Python, JavaScript, Ruby)
- Duck typing enables flexible design
- Higher-order functions for behavior
- Mixins and protocols for reuse
