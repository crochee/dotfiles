# SOLID Principles

> **Language-Agnostic Note:** These principles apply to any programming language. Adapt implementations to your specific language idioms while respecting the underlying concepts.

## Overview

SOLID helps structure software to be flexible, maintainable, and testable. These principles reduce coupling and increase cohesion.

## S - Single Responsibility Principle (SRP)

> "A component should have one, and only one, reason to change."

### Problem It Solves

Components that do everything - hard to test, hard to change, hard to understand.

### How to Apply

Each component handles ONE responsibility. If you find yourself saying "and" when describing what a component does, split it.

**Example:**
```
BAD: OrderProcessor handles calculation, persistence, AND invoice generation
GOOD: Separate components for calculation, persistence, and invoice generation
```

### Detection Questions

- Does this component have multiple reasons to change?
- Can I describe it without using "and"?
- Would different stakeholders request changes to different parts?

---

## O - Open/Closed Principle (OCP)

> "Software entities should be open for extension but closed for modification."

### Problem It Solves

Having to modify existing, tested code every time requirements change. Risk of breaking working features.

### How to Apply

Design abstractions that allow new behavior through new components, not edits to existing ones.

**Example:**
```
BAD: ShippingCalculator with if/else chains for each shipping type
GOOD: ShippingMethod interface with separate implementations for each type
     Adding new shipping = new class, not modifying existing code
```

### Architectural Insight

OCP at architecture level means: **design your codebase so new features are added by adding code, not changing existing code.**

---

## L - Liskov Substitution Principle (LSP)

> "Subtypes must be substitutable for their base types without altering program correctness."

### Problem It Solves

Subclasses that break expectations, requiring type-checking and special cases.

### How to Apply

Subtypes must honor the contract of the parent type. If the parent returns non-negative numbers, subtypes cannot return negatives.

**Example:**
```
BAD: DiscountPolicy returns -5 (increases cost!) when parent expects 0+
GOOD: DiscountPolicy enforces contract, throws if given invalid input
```

### Key Insight

This is why you can swap InMemoryUserRepository for PostgresUserRepository - they both honor the UserRepository interface contract.

---

## I - Interface Segregation Principle (ISP)

> "Clients should not be forced to depend on methods they do not use."

### Problem It Solves

Fat interfaces that force partial implementations, empty methods, or throws.

### How to Apply

Split large interfaces into smaller, cohesive ones. Clients depend only on what they need.

**Example:**
```
BAD: WarehouseDevice interface with printLabel, scanBarcode, packageItem
     BasicPrinter forced to implement methods it doesn't support

GOOD: Separate interfaces: LabelPrinter, BarcodeScanner, ItemPackager
     BasicPrinter only implements LabelPrinter
```

### Detection

If you see empty method bodies, throws for "Not implemented", or forced stubs, the interface is too fat.

---

## D - Dependency Inversion Principle (DIP)

> "High-level modules should not depend on low-level modules. Both should depend on abstractions."

### Problem It Solves

Tight coupling to specific implementations (databases, APIs, frameworks). Hard to test, hard to swap.

### How to Apply

Depend on interfaces, inject implementations.

**Example:**
```
BAD: OrderService directly instantiates SendGridEmailService (locked in!)
GOOD: OrderService depends on EmailService interface
     Can inject SendGridEmailService, SESEmailService, or MockEmailService
```

### The Dependency Rule

Source code dependencies should point **inward** toward high-level policies (domain logic), never toward low-level details (infrastructure).

```
Infrastructure → Application → Domain
↑              ↑            ↑
(outer)       (middle)    (inner)

Dependencies flow: outer → inner
Never: inner → outer
```

---

## Applying SOLID at Architecture Level

These principles scale beyond individual components:

| Principle | Architecture Application |
|-----------|--------------------------|
| SRP | Each bounded context has one responsibility |
| OCP | New features = new modules, not edits to existing |
| LSP | Services with same contract are substitutable |
| ISP | Thin interfaces between components/modules |
| DIP | High-level business logic doesn't know about databases/frameworks |

---

## Quick Reference

| Principle | One-Liner | Red Flag |
|-----------|-----------|----------|
| SRP | One reason to change | "This component handles X and Y and Z" |
| OCP | Add, don't modify | `if/else` chains for types |
| LSP | Subtypes are substitutable | Type-checking in calling code |
| ISP | Small, focused interfaces | Empty method implementations |
| DIP | Depend on abstractions | `new ConcreteClass()` in business logic |
