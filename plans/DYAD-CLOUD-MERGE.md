# Dyad Cloud: Merged Architecture Plan

## Executive Summary

This document outlines the architecture for merging **Dyad** (local AI app builder) with **Suna AI** (autonomous agent platform) to create a cloud-first, mobile-responsive PWA with end-to-end automation capabilities.

### Vision
> **"Manus AI for end-to-end automation"** - A chat-first agent platform that builds full-stack apps AND autonomously executes complex workflows across multiple languages (Python, Node.js, C++, Rust, TypeScript) with lifetime memory and GraphRAG.

---

## 📊 Current State Analysis

### Dyad (This Codebase)
| Component | Technology | Status |
|-----------|-----------|--------|
| Runtime | Electron Desktop App | ❌ Replace |
| Frontend | React 19 + TanStack Router | ✅ Keep |
| Backend | Node.js (Electron main) | ❌ Replace |
| Database | SQLite (local) | ❌ Replace |
| AI Layer | AI SDK (Vercel) | ✅ Keep |
| Execution | Local preview | ❌ Replace |
| Auth | None (local-only) | ❌ Add |
| Multi-tenant | No | ❌ Add |

### Suna AI (Kortix)
| Component | Technology | Status |
|-----------|-----------|--------|
| Backend | Python FastAPI | ✅ Keep |
| Frontend | Next.js 14 | ❌ Replace with Dyad UI |
| Mobile | React Native + Expo | ❌ Replace with PWA |
| Database | Supabase (PostgreSQL) | ✅ Keep |
| Cache | Redis (Upstash) | ✅ Keep |
| Sandbox | Docker + Chrome + VNC | ✅ Keep + Extend |
| Agent Framework | Custom pipeline | ✅ Keep |
| Auth | Supabase Auth + JWT | ✅ Keep |
| Billing | Stripe | ✅ Keep |

---

## 🏗️ Target Architecture: Dyad Cloud

### High-Level Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                             │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   PWA (Web)     │  │  Mobile (PWA)   │  │  Desktop (PWA)  │ │
│  │  React + Vite   │  │  Responsive UI  │  │  Installable    │ │
│  │  TanStack Router│  │  Touch-friendly │  │  Offline-first  │ │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘ │
│           │                    │                    │           │
│           └────────────────────┼────────────────────┘           │
│                                │                                 │
└────────────────────────────────┼─────────────────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   CDN (Cloudflare)      │
                    │   - Static Assets       │
                    │   - Edge Functions      │
                    │   - DDoS Protection     │
                    └────────────┬────────────┘
                                 │
┌────────────────────────────────┼─────────────────────────────────┐
│                         API LAYER                                 │
├────────────────────────────────┼─────────────────────────────────┤
│                    ┌───────────▼───────────┐                     │
│                    │   FastAPI Backend     │                     │
│                    │   (Python 3.11+)      │                     │
│                    │   - REST API          │                     │
│                    │   - WebSocket         │                     │
│                    │   - Streaming         │                     │
│                    └───────────┬───────────┘                     │
│                                │                                 │
│         ┌──────────────────────┼──────────────────────┐          │
│         │                      │                      │          │
│  ┌──────▼──────┐      ┌───────▼───────┐     ┌───────▼──────┐    │
│  │   Auth      │      │   Agent       │     │   Sandbox    │    │
│  │   Service   │      │   Orchestrator│     │   Manager    │    │
│  │  (JWT)      │      │   (Suna)      │     │   (Docker)   │    │
│  └─────────────┘      └───────┬───────┘     └──────────────┘    │
│                               │                                  │
│  ┌────────────────────────────┼──────────────────────────────┐  │
│  │                    AI Gateway Layer                       │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐ │  │
│  │  │  BYOK    │ │  Dyad    │ │  Open    │ │  Self-hosted │ │  │
│  │  │  Manager │ │  Pro     │ │  Router  │ │  (Ollama)    │ │  │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────────┘ │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                 │
┌────────────────────────────────┼─────────────────────────────────┐
│                      DATA LAYER                                   │
├────────────────────────────────┼─────────────────────────────────┤
│         ┌──────────────────────┼──────────────────────┐          │
│         │                      │                      │          │
│  ┌──────▼──────┐      ┌───────▼───────┐     ┌───────▼──────┐    │
│  │ PostgreSQL  │      │    Redis      │     │   MinIO/S3   │    │
│  │ (Supabase)  │      │   (Upstash)   │     │  (Storage)   │    │
│  │             │      │               │     │              │    │
│  │ - Users     │      │ - Sessions    │     │ - Files      │    │
│  │ - Agents    │      │ - Cache       │     │ - Sandboxes  │    │
│  │ - Threads   │      │ - Rate Limit  │     │ - Assets     │    │
│  │ - Versions  │      │ - Pub/Sub     │     │ - Backups    │    │
│  │ - GraphRAG  │      │ - Queues      │     │              │    │
│  │ (pgvector)  │      │               │     │              │    │
│  └─────────────┘      └───────────────┘     └──────────────┘    │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              GraphRAG + Lifetime Memory                  │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │   │
│  │  │  Knowledge   │  │   Vector     │  │   Graph      │  │   │
│  │  │  Graph       │  │   Store      │  │   Database   │  │   │
│  │  │  (Neo4j/     │  │   (pgvector) │  │   (pg_graph) │  │   │
│  │  │   pg_graph)  │  │              │  │              │  │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                                 │
┌────────────────────────────────┼─────────────────────────────────┐
│                   SANDBOX LAYER                                   │
├────────────────────────────────┼─────────────────────────────────┤
│         ┌──────────────────────┼──────────────────────┐          │
│         │                      │                      │          │
│  ┌──────▼──────┐      ┌───────▼───────┐     ┌───────▼──────┐    │
│  │ WebContainers│     │   Docker      │     │   WASM       │    │
│  │ (Browser)   │      │   (Server)    │     │   (Edge)     │    │
│  │             │      │               │     │              │    │
│  │ - Node.js   │      │ - Python      │     │ - Python     │    │
│  │ - TypeScript│      │ - Node.js     │     │   (Pyodide) │    │
│  │ - Preview   │      │ - Rust        │     │ - Rust       │    │
│  │             │      │ - C++         │     │   (wasmtime) │    │
│  │             │      │ - Full sudo   │     │ - C++        │    │
│  │             │      │ - Chrome      │     │   (emscripten)│   │
│  │             │      │ - VNC         │     │              │    │
│  └─────────────┘      └───────────────┘     └──────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📁 Repository Structure (Post-Merge)

```
dyad-cloud/
├── apps/
│   ├── pwa/                    # Merged from Dyad frontend + new PWA
│   │   ├── src/
│   │   │   ├── components/     # Keep Dyad's excellent UI components
│   │   │   ├── routes/         # TanStack Router
│   │   │   ├── hooks/          # TanStack Query + custom
│   │   │   ├── lib/            # Utilities
│   │   │   └── atoms/          # Jotai state
│   │   ├── public/
│   │   ├── worker/             # Service worker (PWA)
│   │   └── vite.config.ts
│   │
│   └── mobile/                 # Future: React Native (optional)
│       └── (placeholder)
│
├── backend/                    # Merged from Suna backend
│   ├── api.py                  # FastAPI entry point
│   ├── core/
│   │   ├── agents/             # Suna's agent framework ✅ KEEP
│   │   ├── sandbox/            # Docker sandbox ✅ KEEP + Extend
│   │   ├── threads/            # Thread management ✅ KEEP
│   │   ├── versioning/         # Version control ✅ KEEP
│   │   ├── ai_gateway/         # NEW: Unified AI provider layer
│   │   ├── graphrag/           # NEW: GraphRAG + memory
│   │   ├── storage/            # NEW: Storage quota + billing
│   │   └── auth/               # Supabase Auth ✅ KEEP
│   ├── supabase/               # Database schema + migrations
│   └── pyproject.toml
│
├── packages/
│   ├── shared/                 # Shared types + utilities
│   │   ├── types/              # TypeScript types
│   │   ├── schemas/            # Zod schemas
│   │   └── constants/          # Shared constants
│   │
│   └── sdk/                    # TypeScript SDK for API
│       └── (auto-generated from OpenAPI)
│
├── infra/                      # From Suna
│   ├── pulumi/                 # Infrastructure as Code
│   ├── docker/                 # Docker configurations
│   └── k8s/                    # Kubernetes manifests (optional)
│
├── docs/
│   ├── architecture.md
│   ├── api.md
│   └── deployment.md
│
├── scripts/
│   ├── merge/                  # Merge migration scripts
│   └── deploy/                 # Deployment scripts
│
├── package.json                # Root package.json
├── pnpm-workspace.yaml         # pnpm workspaces
├── docker-compose.yaml         # Local development
└── README.md
```

---

## 🔧 Key Integration Points

### 1. Authentication System

**Current State:**
- Dyad: No auth (local-only)
- Suna: Supabase Auth + JWT

**Target:**
```typescript
// apps/pwa/src/lib/auth.ts
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
)

// JWT tokens stored in httpOnly cookies
// User ID extracted from JWT in all API requests
```

**Migration:**
- Add Supabase client to Dyad frontend
- Replace local settings with user settings in database
- Migrate existing local data to cloud (optional for users)

---

### 2. AI Gateway (BYOK System)

**Current State:**
- Dyad: AI SDK with multi-provider (excellent)
- Suna: LiteLLM

**Target: Merge both approaches**
```python
# backend/core/ai_gateway/providers.py
from litellm import completion
from ai_sdk import stream_text  # Dyad's streaming

class AIGateway:
    def __init__(self, user_id: str):
        self.user_id = user_id
        self.provider_manager = ProviderManager(user_id)
    
    async def stream_completion(self, messages, model, **kwargs):
        # Get user's API key for provider
        api_key = await self.provider_manager.get_api_key(model)
        
        # Use AI SDK for streaming (better UX)
        async for chunk in stream_text(messages, model, api_key):
            yield chunk
    
    async def execute_with_fallback(self, messages, models):
        # Try primary model, fallback to alternatives
        for model in models:
            try:
                return await self.stream_completion(messages, model)
            except RateLimitError:
                continue
        raise AllProvidersExhaustedError()
```

**Supported Providers:**
- OpenAI (GPT-4, GPT-4o, o1, o3, o4-mini)
- Anthropic (Claude 3.5/3.7 Sonnet, Opus)
- Google (Gemini 2.0/2.5)
- xAI (Grok-2, Grok-3)
- Amazon Bedrock
- OpenRouter (100+ models)
- Self-hosted (Ollama, vLLM)
- Azure OpenAI
- Vertex AI

---

### 3. Sandbox Execution

**Current State:**
- Dyad: Local preview (Vite dev server)
- Suna: Docker sandbox with Chrome + VNC

**Target: Hybrid approach**
```python
# backend/core/sandbox/manager.py

class SandboxManager:
    async def create_sandbox(self, user_id: str, languages: list[str]):
        """
        Create sandbox based on required languages:
        - Node.js/TS → WebContainers (browser, fast)
        - Python → Pyodide (WASM) or Docker
        - Rust → wasmtime or Docker
        - C++ → emscripten or Docker
        """
        if all(lang in ['nodejs', 'typescript'] for lang in languages):
            return await self.create_webcontainer(user_id)
        elif any(lang in ['python', 'rust', 'cpp'] for lang in languages):
            return await self.create_docker_sandbox(user_id, languages)
        else:
            return await self.create_wasm_sandbox(user_id, languages)
```

**WebContainers (Browser-based):**
- ✅ Fast startup (<1s)
- ✅ No server costs
- ✅ Secure (browser sandbox)
- ❌ Only Node.js/TypeScript

**Docker (Server-based):**
- ✅ Full language support
- ✅ Full system access (sudo)
- ✅ Chrome for browser automation
- ❌ Slower startup (5-10s)
- ❌ Server costs

**WASM (Edge):**
- ✅ Very fast
- ✅ Secure
- ✅ Low cost
- ❌ Limited language support

---

### 4. GraphRAG + Lifetime Memory

**New Feature (not in either project)**

```python
# backend/core/graphrag/graph.py

class GraphRAG:
    """
    Knowledge graph with lifetime memory across all user sessions.
    
    Nodes:
    - User
    - Project
    - File
    - Function/Class
    - Concept
    - Conversation
    
    Edges:
    - owns (User → Project)
    - contains (Project → File)
    - defines (File → Function)
    - references (Function → Function)
    - similar_to (Concept → Concept)
    - discussed_in (Concept → Conversation)
    """
    
    async def build_graph(self, user_id: str, project_files: list[File]):
        for file in project_files:
            # Extract AST
            ast = await self.parse_file(file)
            
            # Create nodes for functions/classes
            for node in ast.nodes:
                await self.graph.create_node(
                    type=node.type,
                    name=node.name,
                    embedding=await self.embed(node.code),
                    metadata={
                        'file': file.path,
                        'line': node.line,
                        'user_id': user_id
                    }
                )
    
    async def semantic_search(self, query: str, user_id: str, limit: int = 10):
        # Vector search
        query_embedding = await self.embed(query)
        
        # Graph traversal + vector similarity
        results = await self.graph.hybrid_search(
            query_embedding=query_embedding,
            filters={'user_id': user_id},
            limit=limit
        )
        
        return results
    
    async def get_context(self, current_file: str, user_id: str):
        """
        Get relevant context for current task using graph traversal.
        Returns related files, functions, and concepts.
        """
        node = await self.graph.get_node('file', current_file, user_id)
        
        # Traverse graph: file → functions → related concepts → other files
        context = await self.graph.traverse(
            start_node=node,
            max_depth=3,
            max_nodes=50
        )
        
        return context
```

**Database Schema:**
```sql
-- Vector store for embeddings
CREATE TABLE embeddings (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    node_type TEXT NOT NULL, -- 'file', 'function', 'class', 'concept'
    node_id TEXT NOT NULL,
    content TEXT NOT NULL,
    embedding vector(1536), -- OpenAI text-embedding-3-small
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Graph relationships (using pg_graph or separate Neo4j)
CREATE TABLE graph_edges (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    source_type TEXT NOT NULL,
    source_id TEXT NOT NULL,
    target_type TEXT NOT NULL,
    target_id TEXT NOT NULL,
    edge_type TEXT NOT NULL, -- 'defines', 'references', 'similar_to'
    metadata JSONB,
    
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX idx_embeddings_vector ON embeddings 
    USING ivfflat (embedding vector_cosine_ops);
```

---

### 5. Storage Quota + Pay-per-GB

**New Feature**

```python
# backend/core/storage/quota.py

class StorageQuota:
    async def get_usage(self, user_id: str) -> StorageUsage:
        usage = await db.fetch_one("""
            SELECT SUM(size_bytes) as total
            FROM user_files
            WHERE user_id = $1
        """, user_id)
        
        return StorageUsage(
            used_bytes=usage['total'] or 0,
            quota_bytes=await self.get_quota(user_id),
            cost_per_gb=0.02  # $0.02/GB
        )
    
    async def check_quota(self, user_id: str, file_size: int):
        usage = await self.get_usage(user_id)
        
        if usage.used_bytes + file_size > usage.quota_bytes:
            # Offer to upgrade
            raise QuotaExceededError(
                used=usage.used_bytes,
                quota=usage.quota_bytes,
                upgrade_url="/settings/billing"
            )
    
    async def track_usage(self, user_id: str, file: File):
        await db.execute("""
            INSERT INTO user_files (user_id, path, size_bytes, created_at)
            VALUES ($1, $2, $3, NOW())
        """, user_id, file.path, file.size)
        
        # Update billing record
        await self.billing.record_storage(
            user_id=user_id,
            bytes=file.size,
            timestamp=datetime.now()
        )
```

**Pricing Model:**
```
Free Tier:
- 1 GB storage
- 100 agent runs/month
- Community support

Pro ($10/month):
- 10 GB storage
- Unlimited agent runs
- Priority support
- Advanced models (o1, Claude Opus)

Pay-per-GB ($0.02/GB/month):
- Beyond quota
- Billed monthly
- No surprises (real-time tracking)
```

---

## 🚀 Implementation Phases

### Phase 1: Foundation (Weeks 1-3)
- [ ] Set up monorepo structure
- [ ] Migrate Dyad frontend to Vite PWA
- [ ] Deploy Suna backend to VPS
- [ ] Set up Supabase + Redis + MinIO
- [ ] Implement Supabase Auth
- [ ] Create basic API gateway

### Phase 2: Core Features (Weeks 4-6)
- [ ] Merge AI SDK with LiteLLM
- [ ] Implement BYOK system
- [ ] Port Dyad chat UI to PWA
- [ ] Integrate thread system from Suna
- [ ] Add versioning system
- [ ] Set up Docker sandbox

### Phase 3: Advanced Features (Weeks 7-9)
- [ ] Implement GraphRAG
- [ ] Build lifetime memory system
- [ ] Add WebContainers support
- [ ] Implement WASM sandboxes (Pyodide, wasmtime)
- [ ] Build storage quota system
- [ ] Integrate Stripe billing

### Phase 4: Polish + Launch (Weeks 10-12)
- [ ] Mobile-responsive UI polish
- [ ] PWA offline support
- [ ] Performance optimization
- [ ] Security audit
- [ ] Load testing
- [ ] Documentation
- [ ] Beta launch

---

## 📦 Technology Decisions

| Component | Choice | Rationale |
|-----------|--------|-----------|
| **Backend Framework** | FastAPI (Python) | Suna's proven, production-ready |
| **Frontend Framework** | React + Vite | Dyad's excellent UI + PWA support |
| **Router** | TanStack Router | Better than Next.js for PWA |
| **State Management** | Jotai + TanStack Query | Dyad's existing setup |
| **Database** | PostgreSQL (Supabase) | Suna's choice + pgvector |
| **Cache** | Redis (Upstash) | Suna's choice |
| **Storage** | MinIO (self-hosted) | S3-compatible, cost control |
| **Auth** | Supabase Auth | Suna's choice, easy integration |
| **AI Layer** | AI SDK + LiteLLM | Best of both worlds |
| **Sandbox** | WebContainers + Docker | Hybrid for performance + features |
| **Graph DB** | pg_graph (PostgreSQL) | No extra DB, native integration |
| **Vector DB** | pgvector | PostgreSQL extension |
| **PWA** | Vite PWA Plugin | Zero-config service worker |
| **UI Components** | Base UI | Dyad's existing, accessible |
| **Styling** | Tailwind CSS | Both projects use it |
| **Deployment** | Docker + VPS | Cost-effective, full control |
| **CI/CD** | GitHub Actions | Both projects use it |
| **Monitoring** | Prometheus + Grafana | Industry standard |
| **Logging** | Structlog (Python) | Suna's choice |

---

## 🔐 Security Considerations

### Multi-tenant Isolation
```python
# All database queries must include user_id
async def get_files(user_id: str):
    return await db.fetch_all("""
        SELECT * FROM files
        WHERE user_id = $1  -- CRITICAL: user isolation
    """, user_id)

# JWT verification on all protected routes
@router.get("/files")
async def list_files(user: User = Depends(verify_jwt)):
    files = await get_files(user.id)
    return files
```

### API Key Encryption
```python
from cryptography.fernet import Fernet

class KeyManager:
    def __init__(self):
        self.key = os.environ['ENCRYPTION_KEY']
        self.cipher = Fernet(self.key)
    
    def encrypt(self, api_key: str) -> str:
        return self.cipher.encrypt(api_key.encode()).decode()
    
    def decrypt(self, encrypted_key: str) -> str:
        return self.cipher.decrypt(encrypted_key.encode()).decode()
```

### Rate Limiting
```python
from fastapi_limiter import FastAPILimiter
from fastapi_limiter.depends import RateLimiter

@app.get("/api/chat", dependencies=[Depends(RateLimiter(times=10, seconds=60))])
async def chat_endpoint():
    ...
```

### Sandbox Security
```python
# Docker sandbox with resource limits
docker run \
  --memory=512m \
  --cpus=1.0 \
  --pids-limit=50 \
  --network=sandbox \
  --cap-drop=ALL \
  --cap-add=NET_BIND_SERVICE \
  --read-only \
  --tmpfs /tmp \
  sandbox-image
```

---

## 📊 Database Schema (Merged)

```sql
-- Users (from Supabase auth)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User settings (migrated from Dyad local settings)
CREATE TABLE user_settings (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    selected_model JSONB NOT NULL,
    provider_settings JSONB NOT NULL, -- Encrypted API keys
    theme_id TEXT,
    language TEXT DEFAULT 'en',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- API keys (BYOK system)
CREATE TABLE user_api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    provider TEXT NOT NULL, -- 'openai', 'anthropic', etc.
    encrypted_key TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, provider)
);

-- Projects (from Dyad apps + Suna projects)
CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    name TEXT NOT NULL,
    path TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Threads (from Suna)
CREATE TABLE threads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES projects(id),
    user_id UUID REFERENCES users(id),
    title TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Messages (merged from Dyad + Suna)
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID REFERENCES threads(id),
    role TEXT NOT NULL, -- 'user', 'assistant'
    content TEXT NOT NULL,
    ai_messages_json JSONB, -- AI SDK v6 format
    commit_hash TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Agent versions (from Suna)
CREATE TABLE agent_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID,
    user_id UUID REFERENCES users(id),
    version_number INTEGER NOT NULL,
    system_prompt TEXT NOT NULL,
    model TEXT,
    tools JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Files (for storage quota)
CREATE TABLE user_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    path TEXT NOT NULL,
    size_bytes BIGINT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, path)
);

-- Storage usage tracking
CREATE TABLE storage_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    bytes_used BIGINT NOT NULL DEFAULT 0,
    last_calculated TIMESTAMPTZ DEFAULT NOW()
);

-- GraphRAG embeddings
CREATE TABLE embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    node_type TEXT NOT NULL,
    node_id TEXT NOT NULL,
    content TEXT NOT NULL,
    embedding vector(1536),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Graph edges
CREATE TABLE graph_edges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    source_type TEXT NOT NULL,
    source_id TEXT NOT NULL,
    target_type TEXT NOT NULL,
    target_id TEXT NOT NULL,
    edge_type TEXT NOT NULL,
    metadata JSONB
);
```

---

## 🎯 Success Metrics

### Technical
- [ ] API response time < 200ms (p95)
- [ ] Sandbox startup < 5s (Docker), < 1s (WebContainers)
- [ ] PWA Lighthouse score > 90
- [ ] 99.9% uptime
- [ ] Zero data loss

### Business
- [ ] $0.02/GB storage cost profitable
- [ ] Free tier: 1GB, 100 runs/month sustainable
- [ ] Pro conversion rate > 5%
- [ ] Churn rate < 5%/month

### User Experience
- [ ] Mobile usability score > 4.5/5
- [ ] Time to first app < 2 minutes
- [ ] Agent success rate > 90%
- [ ] NPS > 50

---

## 📝 Next Steps

1. **Create monorepo structure** - Merge both codebases
2. **Deploy backend** - Set up VPS + Supabase + Redis
3. **Port frontend** - Convert Dyad to PWA
4. **Implement auth** - Supabase Auth integration
5. **Build AI gateway** - Merge AI SDK + LiteLLM
6. **Add GraphRAG** - Implement knowledge graph
7. **Launch beta** - Invite-only testing

---

## 📚 References

- [Suna AI Repository](https://github.com/kortix-ai/suna)
- [Dyad Repository](https://github.com/dyad-sh/dyad)
- [Supabase Documentation](https://supabase.com/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com)
- [AI SDK Documentation](https://sdk.vercel.ai)
- [WebContainers Documentation](https://webcontainers.io)
- [pgvector Documentation](https://github.com/pgvector/pgvector)

---

*Last updated: March 12, 2026*
