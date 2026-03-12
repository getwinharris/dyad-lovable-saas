# bapX Auto 🚀

**End-to-end AI automation platform** - Like Manus AI, but open-source and cloud-first.

Build autonomous AI agents that execute complex workflows across Python, Node.js, C++, Rust, and TypeScript with lifetime memory and GraphRAG.

![bapX Auto](https://img.shields.io/badge/bapX-Auto-blue?style=for-the-badge)
![License](https://img.shields.io/github/license/getwinharris/dyad-lovable-saas?style=for-the-badge)
![Stars](https://img.shields.io/github/stars/getwinharris/dyad-lovable-saas?style=for-the-badge)

## 🌟 Features

### 🤖 Multi-Agent System
- **Autonomous Agents** - Create agents that work on your behalf
- **Multi-Language Support** - Python, Node.js, C++, Rust, TypeScript
- **Sandboxed Execution** - WebContainers (browser) + Docker (server)
- **Lifetime Memory** - GraphRAG with persistent knowledge graph

### 💬 Chat-First PWA
- **Mobile-Responsive** - Works on phone, tablet, desktop
- **Offline-First** - PWA with service worker caching
- **Installable** - Add to home screen on any device
- **Real-time** - WebSocket streaming for instant feedback

### 🔑 BYOK (Bring Your Own Key)
- **100+ Models** - OpenAI, Anthropic, Google, xAI, OpenRouter, Ollama
- **Pay-per-GB** - Only pay for storage ($0.02/GB/month)
- **No Vendor Lock-in** - Use your own API keys
- **Fallback Chain** - Auto-failover between providers

### 🧠 GraphRAG + Memory
- **Knowledge Graph** - Semantic relationships across all projects
- **Lifetime Memory** - Remembers context across sessions
- **Vector Search** - pgvector-powered semantic retrieval
- **Smart Context** - Auto-includes relevant files/code

### 🛡️ Enterprise-Ready
- **Multi-Tenant** - User isolation with Supabase Auth
- **Encrypted Keys** - API keys encrypted at rest
- **Rate Limiting** - Redis-based token bucket
- **Audit Logs** - Full activity tracking

## 🏗️ Architecture

```
┌─────────────────────────────────────┐
│    PWA (React + Vite + TanStack)    │
│    Mobile-Responsive + Offline      │
├─────────────────────────────────────┤
│    FastAPI Backend (Python 3.11+)   │
│    Suna Agent Framework + AI SDK    │
├─────────────────────────────────────┤
│  Supabase │ Redis │ MinIO │ GraphRAG│
├─────────────────────────────────────┤
│  WebContainers │ Docker │ WASM      │
└─────────────────────────────────────┘
```

## 🚀 Quick Start

### Local Development

```bash
# Clone the repo
git clone https://github.com/getwinharris/dyad-lovable-saas.git
cd dyad-lovable-saas

# Install dependencies
npm install

# Start development server
npm start

# For cloud backend (requires Docker)
docker-compose up -d
npm run dev:cloud
```

### Cloud Deployment

```bash
# Set up environment
cp .env.example .env
# Edit .env with your Supabase, Redis, and MinIO credentials

# Deploy backend to VPS
cd backend && docker-compose up -d

# Deploy frontend to Vercel/Netlify
cd apps/pwa && npm run build
```

## 📦 Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | React 19 + Vite + TanStack Router |
| **Backend** | FastAPI (Python 3.11+) |
| **Database** | PostgreSQL (Supabase) + pgvector |
| **Cache** | Redis (Upstash) |
| **Storage** | MinIO (S3-compatible) |
| **Auth** | Supabase Auth + JWT |
| **AI Gateway** | AI SDK + LiteLLM |
| **Sandbox** | WebContainers + Docker + WASM |
| **GraphRAG** | pg_graph + pgvector |
| **PWA** | Vite PWA Plugin |
| **UI** | Base UI + Tailwind CSS |

## 🎯 Use Cases

### 1. Full-Stack App Generation
```
"Build a SaaS app with Stripe payments, user auth, and analytics dashboard"
→ bapX Auto creates the entire app, deploys it, and sets up CI/CD
```

### 2. Data Analysis Workflows
```
"Analyze this CSV, create visualizations, and generate a report"
→ Agent runs Python (pandas, matplotlib), outputs PDF report
```

### 3. Browser Automation
```
"Scrape pricing data from these 10 competitor websites daily"
→ Agent uses Chrome in sandbox, stores data in database
```

### 4. Code Refactoring
```
"Refactor this monolith into microservices with proper API boundaries"
→ Agent analyzes codebase, creates new services, migrates incrementally
```

### 5. Customer Support Agent
```
"Handle support tickets, categorize them, and draft responses"
→ Agent reads tickets, uses knowledge base, drafts personalized responses
```

## 📊 Pricing

**Free Tier:**
- 1 GB storage
- 100 agent runs/month
- Community support

**Pro ($10/month):**
- 10 GB storage
- Unlimited agent runs
- Priority support
- Advanced models (o1, Claude Opus)

**Pay-per-GB:**
- $0.02/GB/month beyond quota
- Real-time usage tracking
- No surprises

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

### Quick Contrib

```bash
# Fork and clone
git clone https://github.com/YOUR_USERNAME/dyad-lovable-saas.git
cd dyad-lovable-saas

# Create branch
git checkout -b feature/your-feature

# Make changes, then test
npm test
npm run e2e

# Commit and push
git commit -m "feat: add your feature"
git push origin feature/your-feature

# Create PR
```

## 📄 License

- **Core Platform**: Apache 2.0 (open-source)
- **Pro Features**: FSL 1.1 (fair-source, changes to Apache 2.0 after 2 years)

See [LICENSE](./LICENSE) for details.

## 🙏 Acknowledgments

bapX Auto merges the best of:
- **Dyad** - Excellent AI code generation UI and multi-model support
- **Suna AI (Kortix)** - Autonomous agent framework and sandbox execution

Thanks to both communities for inspiring this project!

## 📞 Contact

- **GitHub**: [getwinharris/dyad-lovable-saas](https://github.com/getwinharris/dyad-lovable-saas)
- **Discord**: [Coming Soon]
- **Twitter**: [@bapx_auto](https://twitter.com/bapx_auto)

---

**Built with ❤️ by the bapX Team**

*Last updated: March 12, 2026*
