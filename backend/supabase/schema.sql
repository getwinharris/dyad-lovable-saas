-- =====================================================
-- bapX Auto - Supabase Database Schema
-- =====================================================
-- Unified platform for:
-- - Chat-first interface (like Manus AI / Microsoft Copilot)
-- - Full-stack app builder
-- - Autonomous agents
-- - Database integration (Supabase Postgres)
-- - GraphRAG lifetime memory
-- =====================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector"; -- For GraphRAG embeddings
CREATE EXTENSION IF NOT EXISTS "pg_graphql"; -- For graph relationships (optional)

-- =====================================================
-- USERS & AUTH (handled by Supabase Auth)
-- =====================================================
-- Users table extends Supabase auth.users
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    
    -- Preferences
    default_model TEXT DEFAULT 'openai/gpt-4o',
    theme TEXT DEFAULT 'dark',
    language TEXT DEFAULT 'en',
    
    -- Quotas
    storage_used_bytes BIGINT DEFAULT 0,
    storage_quota_bytes BIGINT DEFAULT 1073741824, -- 1GB free tier
    agent_runs_used INTEGER DEFAULT 0,
    agent_runs_quota INTEGER DEFAULT 100, -- per month
    
    -- Subscription
    subscription_tier TEXT DEFAULT 'free', -- free, pro, enterprise
    subscription_status TEXT DEFAULT 'active',
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast lookups
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_subscription ON public.users(subscription_tier);

-- =====================================================
-- API KEYS (BYOK - Bring Your Own Key)
-- =====================================================
CREATE TABLE public.api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    provider TEXT NOT NULL, -- 'openai', 'anthropic', 'google', 'xai', 'openrouter', 'ollama'
    encrypted_key TEXT NOT NULL,
    key_metadata JSONB, -- Additional key info (expiry, rate limits, etc.)
    is_active BOOLEAN DEFAULT true,
    last_used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, provider)
);

CREATE INDEX idx_api_keys_user ON public.api_keys(user_id);
CREATE INDEX idx_api_keys_provider ON public.api_keys(provider);

-- =====================================================
-- PROJECTS (Apps being built)
-- =====================================================
CREATE TABLE public.projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    slug TEXT,
    
    -- Git integration
    github_org TEXT,
    github_repo TEXT,
    github_branch TEXT DEFAULT 'main',
    
    -- Database integration
    supabase_project_id TEXT,
    supabase_org_slug TEXT,
    neon_project_id TEXT,
    neon_branch_id TEXT,
    
    -- Deployment
    vercel_project_id TEXT,
    vercel_deployment_url TEXT,
    
    -- App configuration
    install_command TEXT DEFAULT 'npm install',
    start_command TEXT DEFAULT 'npm run dev',
    build_command TEXT DEFAULT 'npm run build',
    
    -- Chat context for GraphRAG
    chat_context JSONB DEFAULT '[]'::jsonb,
    
    -- Metadata
    is_favorite BOOLEAN DEFAULT false,
    theme_id UUID,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_projects_user ON public.projects(user_id);
CREATE INDEX idx_projects_slug ON public.projects(slug);
CREATE INDEX idx_projects_favorite ON public.projects(is_favorite);

-- =====================================================
-- CHATS / THREADS (Conversation history)
-- =====================================================
CREATE TABLE public.chats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT,
    parent_chat_id UUID REFERENCES public.chats(id), -- For branching conversations
    
    -- Context management
    initial_commit_hash TEXT,
    compacted_at TIMESTAMPTZ,
    compaction_backup_path TEXT,
    pending_compaction BOOLEAN DEFAULT false,
    
    -- Agent mode
    agent_mode TEXT DEFAULT 'build', -- 'build', 'ask', 'agent', 'plan'
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_chats_user ON public.chats(user_id);
CREATE INDEX idx_chats_project ON public.chats(project_id);
CREATE INDEX idx_chats_created ON public.chats(created_at DESC);

-- =====================================================
-- MESSAGES (Chat messages with AI)
-- =====================================================
CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_id UUID REFERENCES public.chats(id) ON DELETE CASCADE NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    
    -- Message metadata
    approval_state TEXT CHECK (approval_state IN ('approved', 'rejected', 'pending')),
    source_commit_hash TEXT,
    commit_hash TEXT,
    request_id TEXT,
    
    -- AI metadata
    max_tokens_used INTEGER,
    model TEXT,
    model_provider TEXT,
    tokens_used INTEGER,
    cost_usd DECIMAL(10, 6),
    
    -- AI SDK messages (preserves tool calls/results)
    ai_messages_json JSONB,
    
    -- Quota tracking
    using_free_agent_quota BOOLEAN,
    
    -- Compaction
    is_compaction_summary BOOLEAN DEFAULT false,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_messages_chat ON public.messages(chat_id);
CREATE INDEX idx_messages_created ON public.messages(created_at);
CREATE INDEX idx_messages_role ON public.messages(role);

-- Full-text search for message content
CREATE INDEX idx_messages_content_search ON public.messages USING GIN(to_tsvector('english', content));

-- =====================================================
-- GRAPH RAG - Knowledge Graph
-- =====================================================

-- Nodes in the knowledge graph
CREATE TABLE public.graph_nodes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
    
    node_type TEXT NOT NULL, -- 'file', 'function', 'class', 'concept', 'conversation', 'user'
    node_id TEXT NOT NULL, -- Unique identifier within type
    name TEXT NOT NULL,
    content TEXT,
    
    -- Vector embedding for semantic search
    embedding vector(1536), -- OpenAI text-embedding-3-small
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, node_type, node_id)
);

CREATE INDEX idx_graph_nodes_user ON public.graph_nodes(user_id);
CREATE INDEX idx_graph_nodes_project ON public.graph_nodes(project_id);
CREATE INDEX idx_graph_nodes_type ON public.graph_nodes(node_type);

-- Vector similarity search index
CREATE INDEX idx_graph_nodes_embedding ON public.graph_nodes 
    USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 100);

-- Edges (relationships) in the knowledge graph
CREATE TABLE public.graph_edges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    
    source_node_id UUID REFERENCES public.graph_nodes(id) ON DELETE CASCADE NOT NULL,
    target_node_id UUID REFERENCES public.graph_nodes(id) ON DELETE CASCADE NOT NULL,
    edge_type TEXT NOT NULL, -- 'defines', 'references', 'imports', 'similar_to', 'contains', 'discussed_in'
    
    -- Edge metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    weight DECIMAL(5, 4) DEFAULT 1.0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(source_node_id, target_node_id, edge_type)
);

CREATE INDEX idx_graph_edges_source ON public.graph_edges(source_node_id);
CREATE INDEX idx_graph_edges_target ON public.graph_edges(target_node_id);
CREATE INDEX idx_graph_edges_type ON public.graph_edges(edge_type);

-- =====================================================
-- AGENTS (Autonomous agent configurations)
-- =====================================================
CREATE TABLE public.agents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    
    -- Agent configuration
    system_prompt TEXT NOT NULL,
    model TEXT DEFAULT 'openai/gpt-4o',
    temperature DECIMAL(3, 2) DEFAULT 0.7,
    max_tokens INTEGER DEFAULT 4096,
    
    -- Tools and capabilities
    tools JSONB DEFAULT '[]'::jsonb,
    mcp_servers JSONB DEFAULT '[]'::jsonb,
    
    -- Agent versions
    version INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_agents_user ON public.agents(user_id);
CREATE INDEX idx_agents_active ON public.agents(is_active);

-- =====================================================
-- AGENT RUNS (Execution history)
-- =====================================================
CREATE TABLE public.agent_runs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID REFERENCES public.agents(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
    chat_id UUID REFERENCES public.chats(id) ON DELETE CASCADE,
    
    -- Execution status
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'running', 'completed', 'failed', 'cancelled'
    error_message TEXT,
    
    -- Execution details
    steps_executed JSONB DEFAULT '[]'::jsonb,
    tools_used JSONB DEFAULT '[]'::jsonb,
    duration_ms INTEGER,
    tokens_used INTEGER,
    cost_usd DECIMAL(10, 6),
    
    -- Sandbox info
    sandbox_id TEXT,
    sandbox_mode TEXT, -- 'webcontainer', 'docker', 'wasm'
    
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_agent_runs_user ON public.agent_runs(user_id);
CREATE INDEX idx_agent_runs_agent ON public.agent_runs(agent_id);
CREATE INDEX idx_agent_runs_status ON public.agent_runs(status);
CREATE INDEX idx_agent_runs_created ON public.agent_runs(created_at DESC);

-- =====================================================
-- MCP SERVERS (Model Context Protocol)
-- =====================================================
CREATE TABLE public.mcp_servers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    
    -- Transport configuration
    transport_type TEXT NOT NULL, -- 'stdio', 'http', 'websocket'
    command TEXT,
    args JSONB,
    env_json JSONB,
    url TEXT,
    headers_json JSONB,
    
    -- Server status
    is_enabled BOOLEAN DEFAULT true,
    is_connected BOOLEAN DEFAULT false,
    last_connected_at TIMESTAMPTZ,
    
    -- Tools provided by this server
    tools JSONB DEFAULT '[]'::jsonb,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_mcp_servers_user ON public.mcp_servers(user_id);
CREATE INDEX idx_mcp_servers_enabled ON public.mcp_servers(is_enabled);

-- MCP tool consent (user permissions)
CREATE TABLE public.mcp_tool_consents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    server_id UUID REFERENCES public.mcp_servers(id) ON DELETE CASCADE NOT NULL,
    tool_name TEXT NOT NULL,
    
    consent TEXT NOT NULL DEFAULT 'ask', -- 'ask', 'always', 'denied'
    last_used_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, server_id, tool_name)
);

CREATE INDEX idx_mcp_tool_consents_user ON public.mcp_tool_consents(user_id);

-- =====================================================
-- FILES (User project files with storage tracking)
-- =====================================================
CREATE TABLE public.files (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
    
    path TEXT NOT NULL,
    name TEXT NOT NULL,
    size_bytes BIGINT NOT NULL,
    content_type TEXT,
    
    -- Storage location
    storage_path TEXT, -- MinIO/S3 path
    storage_url TEXT,
    
    -- Version tracking
    version INTEGER DEFAULT 1,
    previous_version_id UUID,
    
    -- Git info
    git_sha TEXT,
    git_status TEXT, -- 'added', 'modified', 'deleted'
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, project_id, path)
);

CREATE INDEX idx_files_user ON public.files(user_id);
CREATE INDEX idx_files_project ON public.files(project_id);
CREATE INDEX idx_files_path ON public.files(path);

-- =====================================================
-- VERSIONS (Project version history)
-- =====================================================
CREATE TABLE public.versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    
    commit_hash TEXT NOT NULL,
    version_name TEXT,
    description TEXT,
    
    -- Database state
    neon_db_timestamp TIMESTAMPTZ,
    
    -- Changes summary
    changes_summary JSONB DEFAULT '[]'::jsonb,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_versions_project ON public.versions(project_id);
CREATE INDEX idx_versions_commit ON public.versions(commit_hash);
CREATE INDEX idx_versions_created ON public.versions(created_at DESC);

-- =====================================================
-- USAGE & BILLING
-- =====================================================
CREATE TABLE public.usage_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    
    -- Usage type
    usage_type TEXT NOT NULL, -- 'api_call', 'agent_run', 'storage', 'compute'
    resource_type TEXT, -- 'tokens', 'bytes', 'seconds'
    
    -- Usage amount
    amount BIGINT NOT NULL,
    cost_usd DECIMAL(10, 6) DEFAULT 0,
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_usage_logs_user ON public.usage_logs(user_id);
CREATE INDEX idx_usage_logs_type ON public.usage_logs(usage_type);
CREATE INDEX idx_usage_logs_created ON public.usage_logs(created_at);

-- Monthly usage summary (for billing)
CREATE TABLE public.monthly_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    
    -- Usage breakdown
    api_calls INTEGER DEFAULT 0,
    tokens_used BIGINT DEFAULT 0,
    agent_runs INTEGER DEFAULT 0,
    storage_bytes BIGINT DEFAULT 0,
    compute_seconds INTEGER DEFAULT 0,
    
    -- Costs
    subtotal_usd DECIMAL(10, 2) DEFAULT 0,
    tax_usd DECIMAL(10, 2) DEFAULT 0,
    total_usd DECIMAL(10, 2) DEFAULT 0,
    
    -- Payment status
    payment_status TEXT DEFAULT 'pending', -- 'pending', 'paid', 'failed'
    payment_id TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, year, month)
);

CREATE INDEX idx_monthly_usage_user ON public.monthly_usage(user_id);
CREATE INDEX idx_monthly_usage_period ON public.monthly_usage(year, month);

-- =====================================================
-- TEMPLATES (Pre-built app templates)
-- =====================================================
CREATE TABLE public.templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    
    name TEXT NOT NULL,
    description TEXT,
    slug TEXT UNIQUE,
    
    -- Template content
    files JSONB DEFAULT '[]'::jsonb,
    dependencies JSONB DEFAULT '{}'::jsonb,
    env_example TEXT,
    
    -- Metadata
    category TEXT,
    tags TEXT[] DEFAULT '{}',
    thumbnail_url TEXT,
    
    -- Usage stats
    uses_count INTEGER DEFAULT 0,
    is_featured BOOLEAN DEFAULT false,
    is_public BOOLEAN DEFAULT true,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_templates_creator ON public.templates(creator_id);
CREATE INDEX idx_templates_slug ON public.templates(slug);
CREATE INDEX idx_templates_featured ON public.templates(is_featured);
CREATE INDEX idx_templates_category ON public.templates(category);

-- =====================================================
-- FUNCTIONS & TRIGGERS
-- =====================================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON public.projects
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_chats_updated_at BEFORE UPDATE ON public.chats
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_api_keys_updated_at BEFORE UPDATE ON public.api_keys
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_agents_updated_at BEFORE UPDATE ON public.agents
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_mcp_servers_updated_at BEFORE UPDATE ON public.mcp_servers
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_files_updated_at BEFORE UPDATE ON public.files
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_versions_updated_at BEFORE UPDATE ON public.versions
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.graph_nodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.graph_edges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mcp_servers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mcp_tool_consents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.files ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usage_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monthly_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.templates ENABLE ROW LEVEL SECURITY;

-- Users can only see their own data
CREATE POLICY "Users can view own data" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own data" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Similar policies for all other tables
-- (Implementing a few key examples)

CREATE POLICY "Users can view own projects" ON public.projects
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own projects" ON public.projects
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own projects" ON public.projects
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own projects" ON public.projects
    FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own chats" ON public.chats
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own chats" ON public.chats
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own messages" ON public.messages
    FOR SELECT USING (
        chat_id IN (
            SELECT id FROM public.chats WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create messages" ON public.messages
    FOR INSERT WITH CHECK (
        chat_id IN (
            SELECT id FROM public.chats WHERE user_id = auth.uid()
        )
    );

-- =====================================================
-- INITIAL DATA
-- =====================================================

-- Insert default model providers
INSERT INTO public.model_providers (id, name, api_base_url, is_active) VALUES
    ('openai', 'OpenAI', 'https://api.openai.com/v1', true),
    ('anthropic', 'Anthropic', 'https://api.anthropic.com', true),
    ('google', 'Google AI', 'https://generativelanguage.googleapis.com', true),
    ('xai', 'xAI', 'https://api.x.ai/v1', true),
    ('openrouter', 'OpenRouter', 'https://openrouter.ai/api/v1', true),
    ('ollama', 'Ollama', 'http://localhost:11434', true)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE public.users IS 'User accounts with quotas and subscription info';
COMMENT ON TABLE public.api_keys IS 'Encrypted user API keys for BYOK (Bring Your Own Key)';
COMMENT ON TABLE public.projects IS 'Full-stack apps being built';
COMMENT ON TABLE public.chats IS 'Conversation threads with AI';
COMMENT ON TABLE public.messages IS 'Chat messages with tool calls and AI responses';
COMMENT ON TABLE public.graph_nodes IS 'Knowledge graph nodes for GraphRAG';
COMMENT ON TABLE public.graph_edges IS 'Relationships between knowledge graph nodes';
COMMENT ON TABLE public.agents IS 'Autonomous agent configurations';
COMMENT ON TABLE public.agent_runs IS 'Agent execution history';
COMMENT ON TABLE public.mcp_servers IS 'Model Context Protocol server configurations';
COMMENT ON TABLE public.files IS 'Project files with storage tracking';
COMMENT ON TABLE public.usage_logs IS 'Usage tracking for billing';
COMMENT ON TABLE public.monthly_usage IS 'Monthly usage summaries for billing';
