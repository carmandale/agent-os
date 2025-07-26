# Code Style Guide

> Version: 2.0.0
> Last Updated: 2025-01-22

## Context

This file is part of the Agent OS standards system. These global code style rules are referenced by all product codebases and provide default formatting guidelines. Individual projects may extend or override these rules in their `.agent-os/product/code-style.md` file.

## General Formatting

### Indentation
- Use tabs for indentation (not spaces)
- Configure editors to display tabs as 4 spaces visually
- Maintain consistent indentation throughout files

## Python Style

### Naming Conventions
- **Functions and Variables**: snake_case (e.g., `user_profile`, `calculate_total`)
- **Classes**: PascalCase (e.g., `UserProfile`, `PaymentProcessor`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_RETRY_COUNT`)
- **Private methods**: Leading underscore (e.g., `_internal_helper`)

### Type Hints
```python
def process_user(user_id: int, settings: dict[str, Any]) -> Optional[User]:
	"""Process user with given settings."""
	return user
```

### String Formatting
- Use f-strings for formatting: `f"Hello {name}"`
- Use double quotes consistently: `"Hello World"`
- Triple quotes for docstrings and multi-line strings

### Modern Python Patterns
- Use pathlib over os.path: `Path("data") / "file.txt"`
- Context managers for resources: `with open("file.txt") as f:`
- List/dict comprehensions when readable
- Type hints for function signatures
- Dataclasses or Pydantic for data models

## JavaScript/TypeScript Style

### Naming Conventions
- **Functions and Variables**: camelCase (e.g., `userProfile`, `calculateTotal`)
- **Classes and Types**: PascalCase (e.g., `UserProfile`, `ApiResponse`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_RETRY_COUNT`)
- **React Components**: PascalCase (e.g., `UserDashboard`)

### Modern ES6+ Patterns
```javascript
// Arrow functions
const processUser = (userId) => {
	// function body
}

// Destructuring
const { name, email } = user
const [first, ...rest] = items

// Optional chaining and nullish coalescing
const city = user?.address?.city ?? 'Unknown'

// Async/await over promises
const fetchData = async () => {
	const response = await api.get('/users')
	return response.data
}
```

## React Best Practices

### Component Structure
```typescript
// Functional components with TypeScript
interface UserCardProps {
	user: User
	onSelect?: (id: string) => void
}

export const UserCard: React.FC<UserCardProps> = ({ user, onSelect }) => {
	const [isExpanded, setIsExpanded] = useState(false)
	
	return (
		<div className="rounded-lg bg-white p-4 shadow-sm">
			{/* Component content */}
		</div>
	)
}
```

### Hooks Patterns
- Custom hooks start with "use": `useAuth`, `useDebounce`
- Keep hooks at the top of components
- Extract complex logic to custom hooks
- Prefer `useReducer` for complex state

## CSS/Tailwind Conventions

### Tailwind CSS v4
- Use the new `@import 'tailwindcss'` syntax
- Define custom properties in CSS for theming
- Use semantic color names: `slate`, `emerald`, `red`
- Prefer utility classes over custom CSS

### Class Organization
```jsx
// Keep classes concise and readable
<div className="rounded-lg bg-slate-900/50 p-6 backdrop-blur-sm">
	<h2 className="mb-4 text-lg font-medium text-slate-300">
		Title
	</h2>
</div>

// Group related utilities
<button className="rounded-md bg-primary px-4 py-2 text-white hover:bg-primary/90 active:scale-95">
	Click me
</button>
```

### Dark Mode
- Use class-based dark mode: `dark:bg-slate-800`
- Define CSS custom properties for light/dark themes
- Keep color contrasts accessible

### Common Patterns
- Spacing: `space-y-4`, `gap-4`, `p-4`
- Borders: `border border-slate-700/50`
- Backgrounds: `bg-slate-900/50 backdrop-blur-sm`
- Animations: `transition-colors`, `hover:`, `active:`
- Responsive: `lg:grid-cols-4`, `md:flex-row`

### CSS Custom Properties
```css
:root {
	--background: oklch(0.985 0 0);
	--foreground: oklch(0.145 0 0);
	--primary: oklch(0.488 0.243 264.376);
}

.dark {
	--background: oklch(0.145 0 0);
	--foreground: oklch(0.985 0 0);
	--primary: oklch(0.646 0.222 41.116);
}
```

## Code Comments

### When to Comment
- Add brief comments above non-obvious business logic
- Document complex algorithms or calculations
- Explain the "why" behind implementation choices

### Comment Maintenance
- Never remove existing comments unless removing the associated code
- Update comments when modifying code to maintain accuracy
- Keep comments concise and relevant

### Comment Format
```ruby
# Calculate compound interest with monthly contributions
# Uses the formula: A = P(1 + r/n)^(nt) + PMT × (((1 + r/n)^(nt) - 1) / (r/n))
def calculate_compound_interest(principal, rate, time, monthly_payment)
  # Implementation here
end
```

---

*Customize this file with your team's specific style preferences. These formatting rules apply to all code written by humans and AI agents.*
