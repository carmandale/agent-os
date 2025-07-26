# Tech Stack

> Version: 1.1.0
> Last Updated: 2025-07-26

## Context

This file is part of the Agent OS standards system. These global tech stack defaults are referenced by all product codebases when initializing new projects. Individual projects may override these choices in their `.agent-os/product/tech-stack.md` file.

## Web Development Stack

#### Backend
- **Language:** Python 3.11+
- **Framework:** FastAPI or Django
- **ORM:** SQLAlchemy (FastAPI) or Django ORM
- **API:** RESTful or GraphQL

#### Frontend
- **Framework:** React 18+
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

---

*Customize this file with your organization's preferred tech stack. These defaults are used when initializing new projects with Agent OS.*
