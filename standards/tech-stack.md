# Tech Stack

> Version: 1.2.0
> Last Updated: 2025-08-11

## Context

This file is part of the Agent OS standards system. These global tech stack defaults are referenced by all product codebases when initializing new projects. Individual projects may override these choices in their `.agent-os/product/tech-stack.md` file.

## Web Development Stack

#### Backend
- **Language:** Python 3.11+
- **Package Manager:** uv (modern, fast replacement for pip)
- **Framework:** FastAPI or Django
- **ORM:** SQLAlchemy (FastAPI) or Django ORM
- **API:** RESTful or GraphQL

#### Frontend
- **Framework:** React 19 (or React 18 if compatibility required)
- **Package Manager:** Yarn (or npm for existing projects)
- **Language:** TypeScript
- **Build Tool:** Vite
- **State Management:** Zustand or Context API
- **Forms:** React Hook Form

#### Styling
- **CSS Framework:** Tailwind CSS v4
- **CSS-in-JS:** None (prefer Tailwind)
- **Component Library:** shadcn/ui
- **Animations:** Framer Motion

#### Database
- **Primary:** PostgreSQL 15+
- **Cache:** Redis
- **Vector DB:** Pinecone or pgvector (for AI features)

## Common Infrastructure

### Version Control
- **Platform:** GitHub
- **Branch Strategy:** GitHub Flow
- **PR Reviews:** Required

### CI/CD
- **Platform:** GitHub Actions
- **Deployment:** Vercel or Railway

### Monitoring
- **Error Tracking:** Sentry
- **Analytics:** PostHog or Mixpanel
- **Performance:** Web Vitals

### AI/ML Services
- **LLM:** OpenAI API or Anthropic
- **Embeddings:** OpenAI or Cohere
- **Image Generation:** Stable Diffusion or DALL-E

## Development Environment

### Port Configuration
- **Frontend Dev Server:** 3000 (default), 3001, 3002... for multiple projects
- **Backend API Server:** 8000 (default), 8001, 8002... for multiple projects
- **Port Assignment Pattern:** Project A → UI 3000 + API 8000, Project B → UI 3001 + API 8001

#### Environment Files Setup
```bash
# Frontend (.env.local)
PORT=3000
VITE_API_URL=http://localhost:8000

# Backend (.env)
API_PORT=8000
```

### JavaScript/Node.js Environment (Yarn)
```bash
# Install dependencies
yarn install

# Add new dependency
yarn add react@19 react-dom@19

# Add dev dependency
yarn add -D @types/react @types/react-dom

# Run scripts
yarn dev
yarn build
yarn test

# Create new project
yarn create vite my-app --template react-ts
```

### Python Environment (uv)
```bash
# Create virtual environment
uv venv

# Activate environment
source .venv/bin/activate  # macOS/Linux
# .venv\Scripts\activate    # Windows

# Install dependencies
uv pip install -r requirements.txt

# Add new dependency
uv add fastapi uvicorn

# Create requirements.txt
uv pip freeze > requirements.txt
```

### Common Tools
- **IDE:** VS Code with Agent OS extensions
- **Version Control:** Git with conventional commits
- **Testing:** Playwright (web UI), pytest (Python), Vitest (React)
- **Linting:** ESLint + Prettier (JS/TS), ruff (Python)

---

*Customize this file with your organization's preferred tech stack. These defaults are used when initializing new projects with Agent OS.*
