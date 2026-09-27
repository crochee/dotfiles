# React Patterns Reference

**Load this reference when:** building React components, optimizing performance, implementing accessibility.

## Compound Components

```typescript
const TabsContext = createContext<TabsContextValue | undefined>(undefined)

export function Tabs({ children, defaultTab }) {
  const [activeTab, setActiveTab] = useState(defaultTab)
  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab }}>
      {children}
    </TabsContext.Provider>
  )
}

export function Tab({ value, children }) {
  const ctx = useContext(TabsContext)
  return (
    <button
      onClick={() => ctx.setActiveTab(value)}
      aria-selected={ctx.activeTab === value}
    >
      {children}
    </button>
  )
}
```

## Custom Hooks

```typescript
// useToggle
function useToggle(initialValue = false): [boolean, () => void] {
  const [value, setValue] = useState(initialValue)
  const toggle = useCallback(() => setValue(v => !v), [])
  return [value, toggle]
}

// useLocalStorage
function useLocalStorage<T>(key: string, initialValue: T): [T, (value: T) => void] {
  const [storedValue, setStoredValue] = useState<T>(() => {
    if (typeof window === 'undefined') return initialValue
    try {
      const item = window.localStorage.getItem(key)
      return item ? JSON.parse(item) : initialValue
    } catch { return initialValue }
  })

  const setValue = (value: T) => {
    setStoredValue(value)
    window.localStorage.setItem(key, JSON.stringify(value))
  }

  return [storedValue, setValue]
}
```

## Performance Optimization

### Memoization

```typescript
// useMemo for expensive computations
const sortedList = useMemo(() => 
  items.slice().sort((a, b) => a.name.localeCompare(b.name)),
  [items]
)

// useCallback for functions passed to children
const handleClick = useCallback((id: string) => {
  setSelectedId(id)
}, [])

// React.memo for pure components
const ExpensiveList = React.memo(function ExpensiveList({ items }) {
  return items.map(item => <ListItem key={item.id} item={item} />)
})
```

### Code Splitting

```typescript
const HeavyChart = lazy(() => import('./HeavyChart'))

function Dashboard() {
  return (
    <Suspense fallback={<ChartSkeleton />}>
      <HeavyChart data={data} />
    </Suspense>
  )
}
```

### Virtualization

For long lists, use `@tanstack/react-virtual` or similar to render only visible items.

## Accessibility Patterns

```typescript
// Keyboard navigation
function Modal({ isOpen, onClose, children }) {
  const ref = useRef<HTMLDivElement>(null)
  
  useEffect(() => {
    if (!isOpen) return
    ref.current?.focus()
    
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, [isOpen, onClose])

  return (
    <dialog open={isOpen} ref={ref} aria-modal="true">
      {children}
    </dialog>
  )
}

// ARIA attributes
<button aria-label="Close dialog" onClick={onClose}>
  <span aria-hidden="true">&times;</span>
</button>
```

## Form Patterns

```typescript
function useForm<T>(initialValues: T) {
  const [values, setValues] = useState<T>(initialValues)
  const [errors, setErrors] = useState<Partial<Record<keyof T, string>>>({})

  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target
    setValues(v => ({ ...v, [name]: value }))
  }

  const validate = (validator: (values: T) => Partial<Record<keyof T, string>>) => {
    const newErrors = validator(values)
    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  return { values, errors, handleChange, validate, setValues }
}
```