import { useState, useEffect, useRef } from 'react'
import { 
  Send, Bot, User, Menu, Plus, Settings, Database, Terminal, 
  Sparkles, Code, FileText, Folder, Play, StopCircle, 
  ChevronLeft, ChevronRight, MoreVertical, Copy, Check,
  Maximize2, Minimize2, Download, Upload, GitBranch
} from 'lucide-react'
import { motion, AnimatePresence } from 'framer-motion'

interface Message {
  id: number
  role: 'user' | 'assistant' | 'system'
  content: string
  timestamp?: Date
  attachments?: Array<{ type: string; url: string; name: string }>
  metadata?: {
    model?: string
    tokens?: number
    duration?: number
    tools?: string[]
  }
}

interface ChatSession {
  id: number
  title: string
  preview: string
  updatedAt: Date
  isFavorite?: boolean
}

export default function App() {
  const [sidebarOpen, setSidebarOpen] = useState(true)
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false)
  const [messages, setMessages] = useState<Message[]>([
    {
      id: 1,
      role: 'assistant',
      content: `👋 **Hi! I'm bapX Auto**, your AI automation assistant.

I can help you:
- 🏗️ **Build full-stack apps** with Supabase database
- 🤖 **Run autonomous agents** for complex workflows
- 💻 **Execute code** in Python, Node.js, Rust, C++, TypeScript
- 🧠 **Search your lifetime memory** with GraphRAG
- 🗄️ **Manage databases** with Supabase integration

**What would you like to build today?**

Try asking:
- *"Build a SaaS app with Stripe payments and user auth"*
- *"Create a data analysis dashboard with PostgreSQL"*
- *"Set up an autonomous agent that scrapes websites daily"*`,
      timestamp: new Date(),
      metadata: { model: 'bapx-auto-v1' }
    }
  ])
  const [input, setInput] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [activeChat, setActiveChat] = useState<number | null>(null)
  const [showPreview, setShowPreview] = useState(true)
  const [copiedId, setCopiedId] = useState<number | null>(null)
  
  const messagesEndRef = useRef<HTMLDivElement>(null)
  const textareaRef = useRef<HTMLTextAreaElement>(null)

  const recentChats: ChatSession[] = [
    { id: 1, title: 'SaaS App with Stripe', preview: 'Building payment integration...', updatedAt: new Date(), isFavorite: true },
    { id: 2, title: 'Data Analysis Dashboard', preview: 'Connecting to PostgreSQL...', updatedAt: new Date() },
    { id: 3, title: 'Web Scraper Agent', preview: 'Setting up daily automation...', updatedAt: new Date() },
  ]

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }

  useEffect(() => {
    scrollToBottom()
  }, [messages])

  const sendMessage = async () => {
    if (!input.trim() || isLoading) return

    const userMessage: Message = {
      id: messages.length + 1,
      role: 'user',
      content: input,
      timestamp: new Date()
    }

    setMessages(prev => [...prev, userMessage])
    setInput('')
    setIsLoading(true)

    // Simulate API call - Replace with actual backend call
    setTimeout(() => {
      const assistantMessage: Message = {
        id: messages.length + 2,
        role: 'assistant',
        content: `I'll help you build that! Let me set up the environment...

**Step 1: Creating project structure**
\`\`\`bash
Creating Supabase project...
Setting up database schema...
Configuring authentication...
\`\`\`

**Step 2: Installing dependencies**
\`\`\`json
{
  "dependencies": {
    "@supabase/supabase-js": "^2.0.0",
    "stripe": "^11.0.0",
    "react": "^19.0.0"
  }
}
\`\`\`

What's the next step you'd like me to take?`,
        timestamp: new Date(),
        metadata: { 
          model: 'openai/gpt-4o',
          tokens: 245,
          duration: 1200,
          tools: ['supabase-create', 'npm-install', 'file-write']
        }
      }
      setMessages(prev => [...prev, assistantMessage])
      setIsLoading(false)
    }, 1500)
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      sendMessage()
    }
  }

  const copyToClipboard = async (text: string, id: number) => {
    await navigator.clipboard.writeText(text)
    setCopiedId(id)
    setTimeout(() => setCopiedId(null), 2000)
  }

  const autoResizeTextarea = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setInput(e.target.value)
    e.target.style.height = 'auto'
    e.target.style.height = Math.min(e.target.scrollHeight, 200) + 'px'
  }

  return (
    <div className="flex h-screen bg-black text-white overflow-hidden">
      {/* Sidebar - Collapsible like VS Code / Copilot */}
      <AnimatePresence>
        {sidebarOpen && (
          <motion.aside
            initial={{ width: sidebarCollapsed ? 60 : 280, opacity: 0 }}
            animate={{ width: sidebarCollapsed ? 60 : 280, opacity: 1 }}
            exit={{ width: 0, opacity: 0 }}
            className="flex flex-col border-r border-gray-800 bg-gray-900/50 backdrop-blur-xl"
          >
            {/* Header */}
            <div className="flex items-center justify-between p-4 border-b border-gray-800">
              {!sidebarCollapsed && (
                <motion.h1 
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  className="text-lg font-bold bg-gradient-to-r from-blue-400 via-purple-500 to-pink-500 bg-clip-text text-transparent"
                >
                  bapX Auto
                </motion.h1>
              )}
              <button
                onClick={() => setSidebarCollapsed(!sidebarCollapsed)}
                className="p-2 hover:bg-gray-800 rounded-lg transition"
              >
                {sidebarCollapsed ? <ChevronRight size={18} /> : <ChevronLeft size={18} />}
              </button>
            </div>

            {/* Navigation */}
            {!sidebarCollapsed && (
              <>
                <nav className="flex-1 p-3 space-y-2 overflow-y-auto">
                  {/* New Chat Button */}
                  <button 
                    onClick={() => setActiveChat(null)}
                    className="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg bg-blue-600 hover:bg-blue-700 transition font-medium"
                  >
                    <Plus size={18} />
                    <span>New Chat</span>
                  </button>

                  {/* Recent Chats */}
                  <div className="pt-4">
                    <h3 className="text-xs text-gray-400 uppercase mb-2 px-2">Recent Chats</h3>
                    <div className="space-y-1">
                      {recentChats.map((chat) => (
                        <button
                          key={chat.id}
                          onClick={() => setActiveChat(chat.id)}
                          className={`w-full flex items-start gap-3 px-3 py-2 rounded-lg transition text-left group ${
                            activeChat === chat.id ? 'bg-gray-800' : 'hover:bg-gray-800/50'
                          }`}
                        >
                          <Database size={16} className="text-gray-400 mt-0.5" />
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2">
                              <span className="text-sm font-medium truncate">{chat.title}</span>
                              {chat.isFavorite && <Sparkles size={12} className="text-yellow-400" />}
                            </div>
                            <p className="text-xs text-gray-500 truncate">{chat.preview}</p>
                          </div>
                        </button>
                      ))}
                    </div>
                  </div>

                  {/* Projects */}
                  <div className="pt-4">
                    <h3 className="text-xs text-gray-400 uppercase mb-2 px-2">Projects</h3>
                    <div className="space-y-1">
                      <button className="w-full flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-800/50 transition text-left">
                        <Folder size={16} className="text-gray-400" />
                        <span className="text-sm">SaaS Platform</span>
                      </button>
                      <button className="w-full flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-800/50 transition text-left">
                        <Folder size={16} className="text-gray-400" />
                        <span className="text-sm">Analytics Dashboard</span>
                      </button>
                    </div>
                  </div>

                  {/* Agents */}
                  <div className="pt-4">
                    <h3 className="text-xs text-gray-400 uppercase mb-2 px-2">Agents</h3>
                    <div className="space-y-1">
                      <button className="w-full flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-800/50 transition text-left">
                        <Play size={16} className="text-green-400" />
                        <span className="text-sm">Web Scraper</span>
                      </button>
                      <button className="w-full flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-800/50 transition text-left">
                        <StopCircle size={16} className="text-red-400" />
                        <span className="text-sm">Data Processor</span>
                      </button>
                    </div>
                  </div>
                </nav>

                {/* Footer */}
                <div className="p-3 border-t border-gray-800 space-y-1">
                  <button className="w-full flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-800 transition">
                    <Settings size={18} />
                    <span>Settings</span>
                  </button>
                  <button className="w-full flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-800 transition">
                    <GitBranch size={18} />
                    <span>GitHub</span>
                  </button>
                </div>
              </>
            )}
          </motion.aside>
        )}
      </AnimatePresence>

      {/* Main Chat Area */}
      <main className="flex-1 flex flex-col min-w-0">
        {/* Header */}
        <header className="flex items-center justify-between px-4 py-3 border-b border-gray-800 bg-gray-900/30">
          <div className="flex items-center gap-3">
            <button
              onClick={() => setSidebarOpen(!sidebarOpen)}
              className="p-2 hover:bg-gray-800 rounded-lg transition"
            >
              <Menu size={20} />
            </button>
            <div>
              <h1 className="font-semibold">bapX Auto</h1>
              <p className="text-xs text-gray-400">
                {activeChat ? recentChats.find(c => c.id === activeChat)?.title : 'New conversation'}
              </p>
            </div>
          </div>
          
          <div className="flex items-center gap-2">
            <button
              onClick={() => setShowPreview(!showPreview)}
              className={`px-3 py-1.5 rounded-lg text-sm font-medium transition flex items-center gap-2 ${
                showPreview ? 'bg-blue-600' : 'bg-gray-800 hover:bg-gray-700'
              }`}
            >
              <Code size={16} />
              <span className="hidden sm:inline">Preview</span>
            </button>
            <button className="p-2 hover:bg-gray-800 rounded-lg transition">
              <MoreVertical size={18} />
            </button>
          </div>
        </header>

        {/* Messages */}
        <div className="flex-1 flex overflow-hidden">
          <div className="flex-1 overflow-y-auto p-4 space-y-4">
            {messages.map((message) => (
              <motion.div
                key={message.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className={`flex gap-3 ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}
              >
                {message.role !== 'user' && (
                  <div className="w-8 h-8 rounded-full bg-gradient-to-r from-blue-500 via-purple-500 to-pink-500 flex items-center justify-center flex-shrink-0">
                    <Bot size={18} />
                  </div>
                )}

                <div className={`max-w-[85%] lg:max-w-[75%] space-y-2`}>
                  <div
                    className={`rounded-2xl px-4 py-3 ${
                      message.role === 'user'
                        ? 'bg-blue-600 text-white'
                        : message.role === 'system'
                        ? 'bg-gray-800/50 border border-gray-700 text-gray-300'
                        : 'bg-gray-800 text-gray-100'
                    }`}
                  >
                    <div className="prose prose-invert prose-sm max-w-none">
                      {message.content.split('\n').map((line, i) => (
                        <p key={i} className="whitespace-pre-wrap text-sm leading-relaxed">
                          {line}
                        </p>
                      ))}
                    </div>
                  </div>

                  {/* Message Metadata */}
                  {message.metadata && message.role === 'assistant' && (
                    <div className="flex items-center gap-3 px-2 text-xs text-gray-500">
                      <span>{message.metadata.model}</span>
                      <span>•</span>
                      <span>{message.metadata.tokens} tokens</span>
                      {message.metadata.tools && (
                        <>
                          <span>•</span>
                          <div className="flex gap-1">
                            {message.metadata.tools.map((tool, i) => (
                              <span key={i} className="px-1.5 py-0.5 bg-gray-800 rounded">
                                {tool}
                              </span>
                            ))}
                          </div>
                        </>
                      )}
                      <button
                        onClick={() => copyToClipboard(message.content, message.id!)}
                        className="ml-auto p-1 hover:bg-gray-800 rounded"
                      >
                        {copiedId === message.id ? <Check size={14} className="text-green-400" /> : <Copy size={14} />}
                      </button>
                    </div>
                  )}
                </div>

                {message.role === 'user' && (
                  <div className="w-8 h-8 rounded-full bg-gray-700 flex items-center justify-center flex-shrink-0">
                    <User size={18} />
                  </div>
                )}
              </motion.div>
            ))}

            {isLoading && (
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                className="flex gap-3"
              >
                <div className="w-8 h-8 rounded-full bg-gradient-to-r from-blue-500 via-purple-500 to-pink-500 flex items-center justify-center">
                  <Bot size={18} />
                </div>
                <div className="bg-gray-800 rounded-2xl px-4 py-3">
                  <div className="flex gap-1">
                    <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" />
                    <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0.2s' }} />
                    <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0.4s' }} />
                  </div>
                </div>
              </motion.div>
            )}

            <div ref={messagesEndRef} />
          </div>

          {/* Preview Panel - Like Bolt.new / Lovable */}
          <AnimatePresence>
            {showPreview && (
              <motion.div
                initial={{ width: 0, opacity: 0 }}
                animate={{ width: 500, opacity: 1 }}
                exit={{ width: 0, opacity: 0 }}
                className="border-l border-gray-800 bg-gray-900/30 overflow-hidden"
              >
                <div className="h-full flex flex-col">
                  <div className="flex items-center justify-between px-4 py-3 border-b border-gray-800">
                    <h2 className="font-semibold">Preview</h2>
                    <div className="flex items-center gap-2">
                      <button className="p-1.5 hover:bg-gray-800 rounded">
                        <Download size={16} />
                      </button>
                      <button className="p-1.5 hover:bg-gray-800 rounded">
                        <Upload size={16} />
                      </button>
                      <button
                        onClick={() => setShowPreview(false)}
                        className="p-1.5 hover:bg-gray-800 rounded"
                      >
                        <Minimize2 size={16} />
                      </button>
                    </div>
                  </div>
                  <div className="flex-1 p-4 overflow-y-auto">
                    <div className="aspect-video bg-gray-800 rounded-lg flex items-center justify-center">
                      <div className="text-center text-gray-500">
                        <Code size={48} className="mx-auto mb-2" />
                        <p>Preview will appear here</p>
                        <p className="text-sm mt-1">Start building your app</p>
                      </div>
                    </div>
                    
                    {/* File Tree */}
                    <div className="mt-4">
                      <h3 className="text-xs text-gray-400 uppercase mb-2">Files</h3>
                      <div className="space-y-1 text-sm">
                        <div className="flex items-center gap-2 px-2 py-1.5 hover:bg-gray-800 rounded cursor-pointer">
                          <FileText size={14} className="text-blue-400" />
                          <span>App.tsx</span>
                        </div>
                        <div className="flex items-center gap-2 px-2 py-1.5 hover:bg-gray-800 rounded cursor-pointer">
                          <FileText size={14} className="text-yellow-400" />
                          <span>package.json</span>
                        </div>
                        <div className="flex items-center gap-2 px-2 py-1.5 hover:bg-gray-800 rounded cursor-pointer">
                          <Database size={14} className="text-green-400" />
                          <span>schema.sql</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        {/* Input Area */}
        <div className="border-t border-gray-800 p-4 bg-gray-900/30">
          <div className="max-w-4xl mx-auto">
            <div className="relative flex gap-3">
              <textarea
                ref={textareaRef}
                value={input}
                onChange={autoResizeTextarea}
                onKeyDown={handleKeyDown}
                placeholder="What would you like to build? (e.g., 'Build a SaaS app with Stripe payments and Supabase database')"
                className="flex-1 bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none min-h-[48px] max-h-[200px]"
                rows={1}
              />
              <button
                onClick={sendMessage}
                disabled={!input.trim() || isLoading}
                className="px-6 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-700 disabled:cursor-not-allowed rounded-xl font-medium transition flex items-center gap-2"
              >
                <Send size={18} />
                <span className="hidden sm:inline">Send</span>
              </button>
            </div>
            <div className="flex items-center justify-between mt-3 text-xs text-gray-500">
              <div className="flex items-center gap-3">
                <span>Press Enter to send, Shift+Enter for new line</span>
                <span className="px-2 py-0.5 bg-gray-800 rounded">GPT-4o</span>
              </div>
              <p>bapX Auto can make mistakes. Verify important information.</p>
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}
