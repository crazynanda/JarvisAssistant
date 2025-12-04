"""
J.A.R.V.I.S Memory System
Combines SQLite for conversation storage and ChromaDB for semantic recall
"""

import sqlite3
from datetime import datetime
from typing import List, Dict, Optional
import logging
import os

# Optional imports with fallbacks
try:
    from sentence_transformers import SentenceTransformer
    SENTENCE_TRANSFORMERS_AVAILABLE = True
except ImportError:
    SENTENCE_TRANSFORMERS_AVAILABLE = False

logger = logging.getLogger(__name__)

class JarvisMemory:
    """
    Memory system for J.A.R.V.I.S with SQLite storage and semantic search
    """
    
    def __init__(self, db_path: str = "jarvis_memory.db", chroma_path: str = "./chroma_db"):
        """
        Initialize memory system
        
        Args:
            db_path: Path to SQLite database
            chroma_path: Path to ChromaDB storage
        """
        self.db_path = db_path
        self.chroma_path = chroma_path
        
        # Initialize SQLite
        self._init_sqlite()
        
        # Initialize ChromaDB
        self._init_chroma()
        
        logger.info("J.A.R.V.I.S Memory System initialized")
    
    def _init_sqlite(self):
        """Initialize SQLite database with messages table"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                role TEXT NOT NULL,
                content TEXT NOT NULL,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Create index on timestamp for faster recent queries
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_timestamp 
            ON messages(timestamp DESC)
        """)
        
        conn.commit()
        conn.close()
        
        logger.info(f"SQLite database initialized at {self.db_path}")
    
    def _init_chroma(self):
        """Initialize ChromaDB for semantic search"""
        try:
            # Try to import chromadb
            import chromadb
            from chromadb.config import Settings
            
            # Initialize ChromaDB client
            self.chroma_client = chromadb.PersistentClient(
                path=self.chroma_path,
                settings=Settings(
                    anonymized_telemetry=False,
                    allow_reset=True
                )
            )
            
            # Get or create collection
            self.collection = self.chroma_client.get_or_create_collection(
                name="jarvis_conversations",
                metadata={"description": "J.A.R.V.I.S conversation memory"}
            )
            
            # Initialize sentence transformer for embeddings if available
            if SENTENCE_TRANSFORMERS_AVAILABLE:
                self.encoder = SentenceTransformer('all-MiniLM-L6-v2')
            else:
                self.encoder = None
            
            logger.info(f"ChromaDB initialized at {self.chroma_path}")
            
        except ImportError:
            logger.warning("ChromaDB not available - using in-memory fallback")
            # Simple in-memory fallback
            self.chroma_client = None
            self.collection = None
            self.encoder = None
            self._memory_store = []  # Simple list for testing
            
        except Exception as e:
            logger.error(f"Error initializing ChromaDB: {e}")
            # Fallback to in-memory
            self.chroma_client = None
            self.collection = None
            self.encoder = None
            self._memory_store = []
    
    def store_message(self, role: str, text: str) -> int:
        """
        Store a message in both SQLite and ChromaDB
        
        Args:
            role: Message role ('user' or 'assistant')
            text: Message content
            
        Returns:
            Message ID from SQLite
        """
        try:
            # Store in SQLite
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute(
                "INSERT INTO messages (role, content) VALUES (?, ?)",
                (role, text)
            )
            
            message_id = cursor.lastrowid
            conn.commit()
            conn.close()
            
            # Store in ChromaDB for semantic search
            # Only store user messages and assistant responses for context
            if text.strip() and self.collection is not None:
                try:
                    self.collection.add(
                        documents=[text],
                        metadatas=[{
                            "role": role,
                            "timestamp": datetime.now().isoformat(),
                            "message_id": message_id
                        }],
                        ids=[f"msg_{message_id}"]
                    )
                except Exception as e:
                    logger.warning(f"Error adding to ChromaDB: {e}")
            elif text.strip() and hasattr(self, '_memory_store'):
                # Fallback: store in memory
                self._memory_store.append({
                    "id": message_id,
                    "role": role,
                    "content": text,
                    "timestamp": datetime.now().isoformat()
                })
            
            logger.debug(f"Stored message {message_id}: {role} - {text[:50]}...")
            return message_id
            
        except Exception as e:
            logger.error(f"Error storing message: {e}")
            raise
    
    def get_recent(self, limit: int = 10) -> List[Dict]:
        """
        Get recent messages from SQLite
        
        Args:
            limit: Maximum number of messages to retrieve
            
        Returns:
            List of message dictionaries
        """
        try:
            conn = sqlite3.connect(self.db_path)
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            
            cursor.execute(
                """
                SELECT id, role, content, timestamp 
                FROM messages 
                ORDER BY timestamp DESC 
                LIMIT ?
                """,
                (limit,)
            )
            
            messages = [dict(row) for row in cursor.fetchall()]
            conn.close()
            
            # Reverse to get chronological order
            messages.reverse()
            
            logger.debug(f"Retrieved {len(messages)} recent messages")
            return messages
            
        except Exception as e:
            logger.error(f"Error retrieving recent messages: {e}")
            return []
    
    def recall_semantic(self, query: str, n_results: int = 5) -> List[Dict]:
        """
        Perform semantic search on conversation history
        
        Args:
            query: Search query
            n_results: Number of results to return
            
        Returns:
            List of relevant message dictionaries
        """
        try:
            if self.collection is None:
                # Fallback: simple text matching
                if not hasattr(self, '_memory_store'):
                    return []
                    
                query_lower = query.lower()
                matches = []
                for msg in self._memory_store:
                    if query_lower in msg['content'].lower():
                        matches.append({
                            'content': msg['content'],
                            'role': msg['role'],
                            'timestamp': msg['timestamp'],
                            'message_id': msg['id'],
                            'relevance_score': 0.5
                        })
                return matches[:n_results]
            
            # Query ChromaDB
            results = self.collection.query(
                query_texts=[query],
                n_results=n_results
            )
            
            if not results['documents'] or not results['documents'][0]:
                logger.debug("No semantic matches found")
                return []
            
            # Format results
            recalled_messages = []
            for i, doc in enumerate(results['documents'][0]):
                metadata = results['metadatas'][0][i]
                distance = results['distances'][0][i] if 'distances' in results else None
                
                recalled_messages.append({
                    'content': doc,
                    'role': metadata.get('role', 'unknown'),
                    'timestamp': metadata.get('timestamp', ''),
                    'message_id': metadata.get('message_id', 0),
                    'relevance_score': 1 - distance if distance else 0
                })
            
            logger.debug(f"Recalled {len(recalled_messages)} semantically relevant messages")
            return recalled_messages
            
        except Exception as e:
            logger.error(f"Error in semantic recall: {e}")
            return []
    
    def get_conversation_context(self, user_input: str, recent_limit: int = 10, semantic_limit: int = 3) -> str:
        """
        Build conversation context from recent history and semantic recall
        
        Args:
            user_input: Current user input for semantic search
            recent_limit: Number of recent messages to include
            semantic_limit: Number of semantic matches to include
            
        Returns:
            Formatted context string
        """
        context_parts = []
        
        # Get recent conversation
        recent_messages = self.get_recent(limit=recent_limit)
        if recent_messages:
            context_parts.append("RECENT CONVERSATION:")
            for msg in recent_messages[-5:]:  # Last 5 for context
                role_label = "User" if msg['role'] == 'user' else "J.A.R.V.I.S"
                context_parts.append(f"{role_label}: {msg['content']}")
        
        # Get semantically relevant past conversations
        semantic_results = self.recall_semantic(user_input, n_results=semantic_limit)
        if semantic_results:
            # Filter out very recent messages (already in recent context)
            recent_ids = {msg['id'] for msg in recent_messages}
            unique_semantic = [
                msg for msg in semantic_results 
                if msg.get('message_id') not in recent_ids
            ]
            
            if unique_semantic:
                context_parts.append("\nRELEVANT PAST CONTEXT:")
                for msg in unique_semantic:
                    role_label = "User" if msg['role'] == 'user' else "J.A.R.V.I.S"
                    context_parts.append(f"{role_label}: {msg['content']}")
        
        return "\n".join(context_parts) if context_parts else ""
    
    def clear_old_messages(self, days: int = 30):
        """
        Clear messages older than specified days
        
        Args:
            days: Number of days to keep
        """
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute(
                """
                DELETE FROM messages 
                WHERE timestamp < datetime('now', '-' || ? || ' days')
                """,
                (days,)
            )
            
            deleted_count = cursor.rowcount
            conn.commit()
            conn.close()
            
            logger.info(f"Cleared {deleted_count} messages older than {days} days")
            
        except Exception as e:
            logger.error(f"Error clearing old messages: {e}")
    
    def get_stats(self) -> Dict:
        """Get memory statistics"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute("SELECT COUNT(*) FROM messages")
            total_messages = cursor.fetchone()[0]
            
            cursor.execute("SELECT COUNT(*) FROM messages WHERE role = 'user'")
            user_messages = cursor.fetchone()[0]
            
            cursor.execute("SELECT COUNT(*) FROM messages WHERE role = 'assistant'")
            assistant_messages = cursor.fetchone()[0]
            
            conn.close()
            
            chroma_count = self.collection.count()
            
            return {
                'total_messages': total_messages,
                'user_messages': user_messages,
                'assistant_messages': assistant_messages,
                'vector_embeddings': chroma_count
            }
            
        except Exception as e:
            logger.error(f"Error getting stats: {e}")
            return {}

    def store_summary(self, summary: str):
        """
        Store a conversation summary in ChromaDB
        
        Args:
            summary: Concise facts and preferences summary
        """
        try:
            timestamp = datetime.now().isoformat()
            summary_id = f"summary_{int(datetime.now().timestamp())}"
            
            if self.collection is not None:
                self.collection.add(
                    documents=[summary],
                    metadatas=[{
                        "type": "summary",
                        "timestamp": timestamp
                    }],
                    ids=[summary_id]
                )
                logger.info(f"Stored summary: {summary[:50]}...")
            elif hasattr(self, '_memory_store'):
                # Fallback: store in memory
                self._memory_store.append({
                    "id": summary_id,
                    "type": "summary",
                    "content": summary,
                    "timestamp": timestamp
                })
                logger.info(f"Stored summary (in-memory): {summary[:50]}...")
            
        except Exception as e:
            logger.error(f"Error storing summary: {e}")

    def get_summaries(self, limit: int = 5) -> List[str]:
        """
        Get recent conversation summaries
        
        Args:
            limit: Number of summaries to retrieve
            
        Returns:
            List of summary strings
        """
        try:
            if self.collection is None:
                # Fallback: get from memory
                if not hasattr(self, '_memory_store'):
                    return []
                    
                summaries = [
                    msg for msg in self._memory_store 
                    if msg.get('type') == 'summary'
                ]
                summaries.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
                return [s['content'] for s in summaries[:limit]]
            
            # Get summaries from ChromaDB
            results = self.collection.get(
                where={"type": "summary"},
                limit=limit,
                include=["documents", "metadatas"]
            )
            
            if not results['documents']:
                return []
                
            # Sort by timestamp descending
            summaries = []
            for i, doc in enumerate(results['documents']):
                metadata = results['metadatas'][i]
                summaries.append({
                    'content': doc,
                    'timestamp': metadata.get('timestamp', '')
                })
            
            summaries.sort(key=lambda x: x['timestamp'], reverse=True)
            return [s['content'] for s in summaries]
            
        except Exception as e:
            logger.error(f"Error retrieving summaries: {e}")
            return []

    def get_message_count(self) -> int:
        """Get total number of messages stored"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM messages")
            count = cursor.fetchone()[0]
            conn.close()
            return count
        except Exception as e:
            logger.error(f"Error getting message count: {e}")
            return 0

# Global memory instance
memory = None

def get_memory() -> JarvisMemory:
    """Get or create global memory instance"""
    global memory
    if memory is None:
        memory = JarvisMemory()
    return memory
