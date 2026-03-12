"""
bapX Auto Redis Service

Redis connection and utilities for caching, rate limiting, and pub/sub.
"""

import redis.asyncio as redis
from typing import Optional


class RedisService:
    def __init__(self):
        self.client: Optional[redis.Redis] = None
    
    async def initialize(self, host: str = "localhost", port: int = 6379, password: Optional[str] = None):
        """Initialize Redis connection"""
        self.client = redis.Redis(
            host=host,
            port=port,
            password=password,
            decode_responses=True
        )
        await self.client.ping()
    
    async def close(self):
        """Close Redis connection"""
        if self.client:
            await self.client.close()
    
    async def get(self, key: str) -> Optional[str]:
        """Get value from Redis"""
        return await self.client.get(key) if self.client else None
    
    async def set(self, key: str, value: str, ex: Optional[int] = None):
        """Set value in Redis"""
        if self.client:
            await self.client.set(key, value, ex=ex)
    
    async def delete(self, key: str):
        """Delete key from Redis"""
        if self.client:
            await self.client.delete(key)


# Global instance
redis_service = RedisService()
