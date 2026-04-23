# Clean Code Practices

> **Language-Agnostic Note:** These principles apply to any programming language. Adapt to your language's idioms while respecting the underlying concepts.

## What is Clean Code?

Code that is:
- **Easy to understand** - reveals intent clearly
- **Easy to change** - modifications are localized
- **Easy to test** - dependencies are injectable
- **Simple** - no unnecessary complexity

## The Human-Centered Approach

Code has THREE consumers:
1. **Users** - get their needs met
2. **Customers** - make or save money
3. **Developers** - must maintain it

Design for all three, but remember: **developers read code 10x more than they write it.**

## Naming Principles

### 1. Consistency & Uniqueness (HIGHEST PRIORITY)

Same concept = same name everywhere. One name per concept.

```
BAD: getUserById, fetchCustomerById, retrieveClientById
GOOD: getUser, getOrder, getProduct
```

### 2. Understandability

Use domain language, not technical jargon.

```
BAD: const arr = users.filter(u => u.isActive);
GOOD: const activeCustomers = users.filter(user => user.isActive);
```

### 3. Specificity

Avoid vague names: `data`, `info`, `manager`, `handler`, `processor`, `utils`

```
BAD: DataManager, processInfo
GOOD: OrderRepository, validatePayment
```

### 4. Brevity (but not at cost of clarity)

Short names are good only if meaning is preserved.

```
BAD: usrLst (too cryptic)
BAD: listOfAllActiveUsersInTheSystem (too long)
GOOD: activeUsers (brief but clear)
```

### 5. Searchability

Names should be unique enough to grep/search.

```
BAD: data (common word, hard to search)
GOOD: orderSummary (unique, searchable)
```

### 6. Pronounceability

You should be able to say it in conversation.

```
BAD: genymdhms (generateYearMonthDayHourMinuteSecond)
GOOD: timestamp
```

### 7. Austerity

Avoid unnecessary filler words.

```
BAD: userData, UserClass
GOOD: user, User
```

---

## Essential Practices (9 Rules)

Exercises to improve design. Follow strictly during practice, relax slightly in production.

### 1. One Level of Indentation per Function

Each function should do one thing at one level of abstraction.

```
BAD: Multiple levels of nesting
function process(orders) {
  for (order in orders) {
    if (order.isValid()) {
      for (item in order.items) {
        if (item.inStock) {
          // process...
        }
      }
    }
  }
}

GOOD: Extract to multiple functions, one level each
function processOrders(orders) {
  orders.filter(isValid).forEach(processOrder);
}
```

### 2. Don't Use the ELSE Keyword

Use early returns, guard clauses, or polymorphism.

```
BAD: if/else branches
function getDiscount(user) {
  if (user.isPremium) {
    return 20;
  } else {
    return 0;
  }
}

GOOD: Early return
function getDiscount(user) {
  if (user.isPremium) return 20;
  return 0;
}
```

### 3. Wrap All Primitives and Strings

Primitives should be wrapped in domain objects when they have meaning.

```
BAD: createUser(email: string, age: number)

GOOD: Value objects
- Email with validation
- Age with range checking
- UserId, OrderId, etc.
```

### 4. First-Class Collections

Any collection should be wrapped in its own dedicated type with related operations.

```
BAD: items: Item[] mixed with other state in Order

GOOD: OrderItems type with add(), remove(), total(), isEmpty()
```

### 5. One Dot per Line (Law of Demeter)

Don't chain through object graphs.

```
BAD: order.customer.address.city

GOOD: order.getShippingCity()
```

### 6. Don't Abbreviate

If a name is too long, the function/component is probably doing too much.

```
BAD: custRepo, ord
GOOD: customerRepository, order
```

### 7. Keep All Components Small

- Components: < 50 lines
- Functions: < 10 lines
- Files: < 100 lines

If larger, it's probably doing too much. Split it.

### 8. No Component with More Than Two Instance Variables

Forces small, focused components.

```
BAD: Order with id, customerId, items, total, status

GOOD: Order composed of smaller focused types
- OrderDetails with customer + lineItems
- OrderItems collection type
```

### 9. No Getters/Setters/Properties Without Behavior

Components should have behavior, not just data. Tell objects what to do.

```
BAD: Data bag with getters
if (account.getBalance() >= amount) {
  account.setBalance(account.getBalance() - amount);
}

GOOD: Behavior-rich
const result = account.withdraw(amount);
```

---

## Comments

### When to Write Comments

**Only write comments to explain WHY, not WHAT or HOW.**

Code explains what and how. Comments explain business reasons, non-obvious decisions, or warnings.

```
BAD: Explains what (redundant)
// Add 1 to counter
counter++;

GOOD: Explains why
// Compensate for 0-based indexing in legacy API
counter++;
```

### Prefer Self-Documenting Code

Instead of commenting, rename to make intent clear.

```
BAD: Comment needed to explain
// Check if user can access premium features
if (user.subscriptionLevel >= 2 && !user.isBanned) {}

GOOD: Self-documenting
if (user.canAccessPremiumFeatures()) {}
```

---

## Formatting

### Vertical Spacing

- Related code together
- Blank lines between concepts
- Most important/public at top

### Horizontal Spacing

- Consistent indentation
- Space around operators
- Max line length ~80-120 characters

### Storytelling

Code should read top-to-bottom like a story. High-level at top, details below.

```
GOOD:
process() → validate() → calculateTotals() → save()

Private helpers below, in order of appearance
```
