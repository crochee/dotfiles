**Load this reference when:** writing or reviewing React components — compound components, custom hooks, forms, dialogs, memoisation, or the accessibility of an interactive widget.

## Contents

- [Accessible compound components](#accessible-compound-components)
- [Custom hooks](#custom-hooks)
- [Dialogs: the native `dialog` element](#dialogs-the-native-dialog-element)
- [Forms](#forms)
- [Memoisation](#memoisation)
- [Code splitting and long lists](#code-splitting-and-long-lists)

The snippets target **React 18+** (they use `useId`, added in React 18) and
compile under `strict` TypeScript with `noImplicitAny`. Types are written
explicitly; nothing here relies on inference that `strict` would reject.

## Accessible compound components

A compound component needs three things to be correct: a context that cannot
be read outside its provider, the **WAI-ARIA tabs pattern** (`tablist` /
`tab` / `tabpanel`, roving `tabindex`, arrow-key navigation), and ids that
link a tab to its panel.

The context is typed `| null` and read through a guard hook, so a missing
provider is a loud error instead of a runtime `TypeError` on `undefined`.

```tsx
// React 18+ — accessible tabs (WAI-ARIA APG "Tabs" pattern).
import {
  createContext,
  useContext,
  useId,
  useMemo,
  useState,
  type KeyboardEvent,
  type ReactNode,
} from 'react';

interface TabsContextValue {
  activeTab: string;
  setActiveTab: (id: string) => void;
  baseId: string;
}

const TabsContext = createContext<TabsContextValue | null>(null);

function useTabsContext(component: string): TabsContextValue {
  const context = useContext(TabsContext);
  if (context === null) {
    throw new Error(`<${component}> must be rendered inside <Tabs>.`);
  }
  return context;
}

/** The tab buttons of the tablist this button belongs to, in DOM order. */
function tabButtonsOf(button: HTMLButtonElement): HTMLButtonElement[] {
  const list = button.closest('[role="tablist"]');
  if (list === null) return [];
  return Array.from(list.querySelectorAll<HTMLButtonElement>('[role="tab"]'));
}

export interface TabsProps {
  children: ReactNode;
  defaultTab: string;
  label: string;
}

export function Tabs({ children, defaultTab, label }: TabsProps) {
  const [activeTab, setActiveTab] = useState(defaultTab);
  const baseId = useId();

  const value = useMemo<TabsContextValue>(
    () => ({ activeTab, setActiveTab, baseId }),
    [activeTab, baseId],
  );

  return (
    <TabsContext.Provider value={value}>
      <div className="tabs">
        <div role="tablist" aria-label={label}>
          {children}
        </div>
      </div>
    </TabsContext.Provider>
  );
}

export interface TabProps {
  /** Stable value; must be a valid HTML id fragment (no spaces). */
  id: string;
  children: ReactNode;
}

export function Tab({ id, children }: TabProps) {
  const context = useTabsContext('Tab');
  const selected = context.activeTab === id;

  const handleKeyDown = (event: KeyboardEvent<HTMLButtonElement>) => {
    const buttons = tabButtonsOf(event.currentTarget);
    const index = buttons.indexOf(event.currentTarget);
    if (index === -1 || buttons.length === 0) return;

    let nextIndex: number;
    switch (event.key) {
      case 'ArrowRight':
        nextIndex = (index + 1) % buttons.length;
        break;
      case 'ArrowLeft':
        nextIndex = (index - 1 + buttons.length) % buttons.length;
        break;
      case 'Home':
        nextIndex = 0;
        break;
      case 'End':
        nextIndex = buttons.length - 1;
        break;
      default:
        return;
    }
    event.preventDefault();
    const next = buttons[nextIndex];
    if (next === undefined) return;
    context.setActiveTab(next.getAttribute('data-tab-id') ?? '');
    next.focus();
  };

  return (
    <button
      type="button"
      role="tab"
      id={`${context.baseId}-tab-${id}`}
      data-tab-id={id}
      aria-selected={selected}
      aria-controls={`${context.baseId}-panel-${id}`}
      tabIndex={selected ? 0 : -1}
      onClick={() => context.setActiveTab(id)}
      onKeyDown={handleKeyDown}
    >
      {children}
    </button>
  );
}

export interface TabPanelProps {
  id: string;
  children: ReactNode;
}

export function TabPanel({ id, children }: TabPanelProps) {
  const context = useTabsContext('TabPanel');
  const selected = context.activeTab === id;

  return (
    <div
      role="tabpanel"
      id={`${context.baseId}-panel-${id}`}
      aria-labelledby={`${context.baseId}-tab-${id}`}
      hidden={!selected}
      tabIndex={0}
    >
      {children}
    </div>
  );
}

export function DocsTabs() {
  return (
    <Tabs defaultTab="usage" label="Getting started">
      <Tab id="usage">Usage</Tab>
      <Tab id="api">API</Tab>
      <TabPanel id="usage">Install the package, then import it.</TabPanel>
      <TabPanel id="api">Every export is documented.</TabPanel>
    </Tabs>
  );
}
```

Notes:

- `aria-selected` belongs on an element with `role="tab"`; a plain `<button>`
  carrying `aria-selected` is invalid and announces as a button.
- Only the active tab is in the tab order (`tabIndex={0}`); the rest are
  `-1`. Arrow keys move focus **and** selection, per the APG "automatic
  activation" pattern.
- The panel is `tabIndex={0}` so keyboard users can scroll a long panel.

## Custom hooks

```tsx
// React 18+ — a boolean with a stable toggle.
import { useCallback, useState } from 'react';

export function useToggle(initialValue = false): [boolean, () => void] {
  const [value, setValue] = useState(initialValue);
  const toggle = useCallback(() => setValue((previous) => !previous), []);
  return [value, toggle];
}
```

```tsx
// React 18+ — SSR-safe localStorage with a functional setter.
import { useCallback, useState, type Dispatch, type SetStateAction } from 'react';

export function useLocalStorage<T>(
  key: string,
  initialValue: T,
): [T, Dispatch<SetStateAction<T>>] {
  const [storedValue, setStoredValue] = useState<T>(() => {
    // No `window` during server rendering: fall back to the initial value.
    if (typeof window === 'undefined') return initialValue;
    try {
      const item = window.localStorage.getItem(key);
      return item === null ? initialValue : (JSON.parse(item) as T);
    } catch {
      // Private mode, disabled storage, or malformed JSON.
      return initialValue;
    }
  });

  const setValue = useCallback<Dispatch<SetStateAction<T>>>(
    (next) => {
      setStoredValue((previous) => {
        const resolved =
          typeof next === 'function'
            ? (next as unknown as (previousValue: T) => T)(previous)
            : next;
        if (typeof window === 'undefined') return resolved;
        try {
          window.localStorage.setItem(key, JSON.stringify(resolved));
        } catch (error) {
          // QuotaExceededError, or storage denied: keep the in-memory value
          // instead of throwing into the caller.
          console.warn(`useLocalStorage: could not persist "${key}"`, error);
        }
        return resolved;
      });
    },
    [key],
  );

  return [storedValue, setValue];
}
```

The three things the naive version gets wrong:

1. **The write path must be guarded too.** `localStorage.setItem` throws
   `QuotaExceededError` when the quota is full and throws in some private
   browsing modes; an unguarded write crashes the caller.
2. **No `window` access outside the browser.** The read path is guarded at
   initialisation; the write path needs the same guard, or the hook throws
   during server rendering.
3. **The setter must accept a functional update.** Typing it as
   `(value: T) => void` forbids `setValue((previous) => …)`, which is the
   update `useState` supports and the reason the hook exists.

## Dialogs: the native `dialog` element

`<dialog open>` only puts the element in the DOM — it does **not** put it in
the top layer, so there is no focus containment, no `::backdrop`, no inert
background and no focus trap. `showModal()` is what provides those. Escape is
handled by the native `cancel` event, and the dialog is closed with `close()`.

```tsx
// React 18+ — modal dialog on the native <dialog> element.
import {
  useCallback,
  useEffect,
  useId,
  useRef,
  type KeyboardEvent as ReactKeyboardEvent,
  type ReactNode,
} from 'react';

const FOCUSABLE = [
  'a[href]',
  'button:not([disabled])',
  'input:not([disabled])',
  'select:not([disabled])',
  'textarea:not([disabled])',
  '[tabindex]:not([tabindex="-1"])',
].join(',');

export interface DialogProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: ReactNode;
}

export function Dialog({ isOpen, onClose, title, children }: DialogProps) {
  const dialogRef = useRef<HTMLDialogElement | null>(null);
  const openerRef = useRef<HTMLElement | null>(null);
  const headingId = useId();

  // Open: showModal() puts the dialog in the top layer and makes the rest of
  // the page inert; then focus moves to the first focusable child.
  useEffect(() => {
    const dialog = dialogRef.current;
    if (dialog === null) return;
    if (isOpen && !dialog.open) {
      openerRef.current = document.activeElement instanceof HTMLElement ? document.activeElement : null;
      dialog.showModal();
      const first = dialog.querySelector<HTMLElement>(FOCUSABLE);
      (first ?? dialog).focus();
    }
  }, [isOpen]);

  // Close: the native close() fires the "close" event and restores focus.
  useEffect(() => {
    const dialog = dialogRef.current;
    if (dialog === null) return;
    if (!isOpen && dialog.open) {
      dialog.close();
    }
  }, [isOpen]);

  useEffect(() => {
    const dialog = dialogRef.current;
    if (dialog === null) return;
    const handleCancel = (event: Event) => {
      // Keep React state authoritative: close through onClose, then the
      // effect above calls dialog.close().
      event.preventDefault();
      onClose();
    };
    const handleClose = () => {
      openerRef.current?.focus();
      openerRef.current = null;
    };
    dialog.addEventListener('cancel', handleCancel);
    dialog.addEventListener('close', handleClose);
    return () => {
      dialog.removeEventListener('cancel', handleCancel);
      dialog.removeEventListener('close', handleClose);
    };
  }, [onClose]);

  // Keep Tab inside the dialog.
  const handleKeyDown = useCallback((event: ReactKeyboardEvent<HTMLDialogElement>) => {
    if (event.key !== 'Tab') return;
    const dialog = dialogRef.current;
    if (dialog === null) return;
    const focusable = Array.from(dialog.querySelectorAll<HTMLElement>(FOCUSABLE)).filter(
      (element) => element.offsetParent !== null,
    );
    if (focusable.length === 0) {
      event.preventDefault();
      return;
    }
    const first = focusable[0];
    const last = focusable[focusable.length - 1];
    if (first === undefined || last === undefined) return;
    const active = document.activeElement;
    if (event.shiftKey && (active === first || active === dialog)) {
      event.preventDefault();
      last.focus();
    } else if (!event.shiftKey && active === last) {
      event.preventDefault();
      first.focus();
    }
  }, []);

  return (
    <dialog
      ref={dialogRef}
      className="dialog"
      aria-labelledby={headingId}
      onKeyDown={handleKeyDown}
    >
      <h2 id={headingId}>{title}</h2>
      {children}
      <button type="button" onClick={onClose}>
        Close
      </button>
    </dialog>
  );
}
```

What this fixes relative to the naive version:

- `showModal()` instead of `open` — the dialog is in the top layer, the
  background is inert, `::backdrop` works.
- The native `cancel` event instead of a hand-rolled `keydown` listener for
  Escape.
- Focus goes to the **first focusable child**, not to the `<dialog>` element,
  and is restored to the opener when the dialog closes.
- Tab is trapped inside the dialog.
- `onClose` is always paired with an actual `dialog.close()` — the state and
  the DOM never disagree.

## Forms

The validator belongs to the hook, not to the call site: a per-call validator
means the rules can differ between renders, and the errors are never cleared
as the user fixes them.

```tsx
// React 18+ — form state with validation, touched tracking and submit.
import {
  useCallback,
  useMemo,
  useState,
  type ChangeEvent,
  type FocusEvent,
  type FormEvent,
} from 'react';

export type FormValues = Record<string, unknown>;
export type Validator<T> = (values: T) => Partial<Record<keyof T, string>>;

export interface UseFormResult<T> {
  values: T;
  errors: Partial<Record<keyof T, string>>;
  touched: Partial<Record<keyof T, boolean>>;
  isSubmitting: boolean;
  handleChange: (
    event: ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>,
  ) => void;
  handleBlur: (event: FocusEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => void;
  handleSubmit: (event: FormEvent<HTMLFormElement>) => void;
}

export function useForm<T extends FormValues>(
  initialValues: T,
  validate: Validator<T>,
): UseFormResult<T> {
  const [values, setValues] = useState<T>(initialValues);
  const [errors, setErrors] = useState<Partial<Record<keyof T, string>>>({});
  const [touched, setTouched] = useState<Partial<Record<keyof T, boolean>>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleChange = useCallback(
    (event: ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
      const { name, value } = event.target;
      setValues((previous) => ({ ...previous, [name]: value }) as T);
      // Clear this field's error as soon as the user edits it.
      setErrors((previous) => {
        if (!(name in previous)) return previous;
        const next = { ...previous };
        delete next[name as keyof T];
        return next;
      });
    },
    [],
  );

  const handleBlur = useCallback(
    (event: FocusEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
      const { name } = event.target;
      setTouched((previous) => ({ ...previous, [name]: true }));
    },
    [],
  );

  const handleSubmit = useCallback(
    (event: FormEvent<HTMLFormElement>) => {
      event.preventDefault();
      const nextErrors = validate(values);
      setErrors(nextErrors);
      setTouched(
        Object.keys(values).reduce<Partial<Record<keyof T, boolean>>>(
          (accumulator, key) => ({ ...accumulator, [key]: true }),
          {},
        ),
      );
      if (Object.keys(nextErrors).length > 0) return;
      setIsSubmitting(true);
      // Submit here: await onSubmit(values).
    },
    [validate, values],
  );

  return useMemo(
    () => ({ values, errors, touched, isSubmitting, handleChange, handleBlur, handleSubmit }),
    [values, errors, touched, isSubmitting, handleChange, handleBlur, handleSubmit],
  );
}
```

- The validator is supplied once, at hook creation.
- `touched` records which fields the user has actually visited, so errors are
  not shown on a pristine form.
- Editing a field clears that field's error.
- `handleSubmit` prevents the default navigation, validates, marks every field
  touched, and only then proceeds.

## Memoisation

**Memoise only after a measured re-render.** Use the React DevTools Profiler,
or a render counter, to find the component that actually re-renders often and
the computation that actually costs time. `useMemo` and `useCallback` are not
free: they add dependency-array bookkeeping and a new closure identity to
compare, and a memo that is never invalidated buys nothing.

```tsx
// React 18+ — memoisation, after a measured re-render.
import { memo, useCallback, useMemo } from 'react';

interface RowProps {
  id: string;
  name: string;
  onSelect: (id: string) => void;
}

// Only worth memoising once the Profiler shows this row re-rendering
// expensively. `onSelect` must be stable for the memo to hold.
const Row = memo(
  function Row({ id, name, onSelect }: RowProps) {
    return (
      <li>
        <button type="button" onClick={() => onSelect(id)}>
          {name}
        </button>
      </li>
    );
  },
  (previous, next) => previous.id === next.id && previous.onSelect === next.onSelect,
);

export function List({ items, onSelect }: { items: RowProps[]; onSelect: (id: string) => void }) {
  // Measured as expensive in the Profiler: sorting 10k items on every render.
  const sorted = useMemo(
    () => [...items].sort((a, b) => a.name.localeCompare(b.name)),
    [items],
  );

  const handleSelect = useCallback((id: string) => onSelect(id), [onSelect]);

  return (
    <ul>
      {sorted.map((item) => (
        <Row key={item.id} id={item.id} name={item.name} onSelect={handleSelect} />
      ))}
    </ul>
  );
}
```

Rules that follow from the measurement:

- `useMemo` for a computation whose inputs are unchanged but whose cost is
  real (sorting, filtering, formatting a large list).
- `useCallback` when the identity of the function is part of a child's
  props — usually only worth it once the child is memoised.
- `memo()` for a component that re-renders with identical props. If it takes
  an object, array or function prop, that prop must be referentially stable
  or the memo never holds — pass a `comparison` function or normalise the
  prop at the call site.
- Never memoise a value that is cheap to compute and used once.

## Code splitting and long lists

```tsx
// React 18+ — code splitting with a lazily loaded component.
import { lazy, Suspense, type ComponentType } from 'react';

// In a real project the module is a sibling file:
//   const HeavyChart = lazy(() => import('./HeavyChart'));
// Here it is created in place so the snippet stands alone.
const HeavyChart: ComponentType<{ title: string }> = lazy(async () => ({
  default: ({ title }: { title: string }) => <h2>{title}</h2>,
}));

function ChartSkeleton() {
  return <p aria-live="polite">Loading chart…</p>;
}

export function Dashboard() {
  return (
    <Suspense fallback={<ChartSkeleton />}>
      <HeavyChart title="Revenue" />
    </Suspense>
  );
}
```

For lists beyond a few hundred rows, virtualise with `@tanstack/react-virtual`
so only the visible rows are mounted. Virtualisation and focus management
interact: a virtualised list must keep the focused row mounted, or keyboard
navigation breaks.
