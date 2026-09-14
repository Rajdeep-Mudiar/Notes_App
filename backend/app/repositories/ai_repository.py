import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.schemas.ai import ConversationSessionModel


class AiRepository:
    """MongoDB repository for storing and managing AI study sessions, message histories, and generated study decks."""

    def __init__(self, db: AsyncIOMotorDatabase):
        self.db = db
        self.conversations_collection = db["ai_conversations"]

    async def save_turn(
        self,
        user_id: str,
        session_id: Optional[str],
        title: str,
        subject_id: Optional[str],
        user_msg: Dict[str, Any],
        assistant_msg: Dict[str, Any],
    ) -> str:
        """Append a user question and assistant response pair to an existing or new study session."""
        now = datetime.now(timezone.utc)
        target_session_id = session_id if session_id else str(uuid.uuid4())

        existing = await self.conversations_collection.find_one({
            "user_id": user_id,
            "session_id": target_session_id,
        })

        if existing:
            await self.conversations_collection.update_one(
                {"_id": existing["_id"]},
                {
                    "$push": {"messages": {"$each": [user_msg, assistant_msg]}},
                    "$set": {
                        "updated_at": now,
                        "title": title or existing.get("title", "Study Session"),
                        "last_preview": assistant_msg.get("content", "")[:100],
                    },
                },
            )
        else:
            new_doc = {
                "user_id": user_id,
                "session_id": target_session_id,
                "title": title or "Study Session",
                "subject_id": subject_id,
                "messages": [user_msg, assistant_msg],
                "last_preview": assistant_msg.get("content", "")[:100],
                "created_at": now,
                "updated_at": now,
            }
            await self.conversations_collection.insert_one(new_doc)

        return target_session_id

    async def get_session(self, user_id: str, session_id: str) -> Optional[Dict[str, Any]]:
        """Retrieve full conversation message history for a session."""
        doc = await self.conversations_collection.find_one({
            "user_id": user_id,
            "session_id": session_id,
        })
        if not doc:
            return None
        doc["id"] = str(doc.pop("_id"))
        return doc

    async def get_user_sessions(self, user_id: str, limit: int = 30) -> List[ConversationSessionModel]:
        """Fetch list of active study sessions for the user."""
        cursor = self.conversations_collection.find({"user_id": user_id}).sort("updated_at", -1).limit(limit)

        sessions: List[ConversationSessionModel] = []
        async for doc in cursor:
            messages = doc.get("messages", [])
            last_msg = messages[-1]["content"] if messages else ""
            sessions.append(
                ConversationSessionModel(
                    id=doc["session_id"],
                    user_id=user_id,
                    title=doc.get("title", "Study Session"),
                    subject_id=doc.get("subject_id"),
                    messages_count=len(messages),
                    last_message_preview=doc.get("last_preview", last_msg[:100]),
                    updated_at=doc.get("updated_at", datetime.now(timezone.utc)),
                )
            )
        return sessions

    async def delete_session(self, user_id: str, session_id: str) -> bool:
        """Delete an AI conversation session."""
        res = await self.conversations_collection.delete_one({
            "user_id": user_id,
            "session_id": session_id,
        })
        return res.deleted_count > 0
