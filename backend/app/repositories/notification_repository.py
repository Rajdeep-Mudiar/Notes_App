from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.schemas.notification import NotificationCreate, NotificationPriorityEnum, NotificationTypeEnum


class NotificationRepository:
    def __init__(self, db: AsyncIOMotorDatabase):
        self.db = db
        self.collection = db["notifications"]

    def _helper(self, doc: dict) -> dict:
        created_at = doc.get("created_at", datetime.now(timezone.utc))
        if created_at.tzinfo is None:
            created_at = created_at.replace(tzinfo=timezone.utc)

        read_at = doc.get("read_at")
        if read_at and read_at.tzinfo is None:
            read_at = read_at.replace(tzinfo=timezone.utc)

        return {
            "id": str(doc["_id"]),
            "user_id": str(doc["user_id"]),
            "type": doc.get("type", NotificationTypeEnum.SYSTEM.value),
            "title": doc["title"],
            "message": doc["message"],
            "priority": doc.get("priority", NotificationPriorityEnum.NORMAL.value),
            "is_read": doc.get("is_read", False),
            "action_route": doc.get("action_route"),
            "metadata": doc.get("metadata", {}),
            "created_at": created_at,
            "read_at": read_at,
        }

    async def create_notification(
        self,
        user_id: str,
        notification_in: NotificationCreate,
        dedup_key: Optional[str] = None,
    ) -> dict:
        now = datetime.now(timezone.utc)
        doc = {
            "user_id": ObjectId(user_id),
            "type": notification_in.type.value if isinstance(notification_in.type, NotificationTypeEnum) else notification_in.type,
            "title": notification_in.title,
            "message": notification_in.message,
            "priority": notification_in.priority.value if isinstance(notification_in.priority, NotificationPriorityEnum) else notification_in.priority,
            "is_read": False,
            "action_route": notification_in.action_route,
            "metadata": notification_in.metadata or {},
            "dedup_key": dedup_key,
            "created_at": now,
            "read_at": None,
        }
        result = await self.collection.insert_one(doc)
        doc["_id"] = result.inserted_id
        return self._helper(doc)

    async def notification_exists(self, user_id: str, dedup_key: str, min_created_at: Optional[datetime] = None) -> bool:
        query: Dict[str, Any] = {
            "user_id": ObjectId(user_id),
            "dedup_key": dedup_key,
        }
        if min_created_at:
            query["created_at"] = {"$gte": min_created_at}

        doc = await self.collection.find_one(query)
        return doc is not None

    async def get_notifications(
        self,
        user_id: str,
        is_read: Optional[bool] = None,
        type: Optional[str] = None,
        limit: int = 50,
        skip: int = 0,
    ) -> List[dict]:
        query: Dict[str, Any] = {"user_id": ObjectId(user_id)}
        if is_read is not None:
            query["is_read"] = is_read
        if type:
            query["type"] = type

        cursor = self.collection.find(query).sort("created_at", -1).skip(skip).limit(limit)
        items = await cursor.to_list(length=limit)
        return [self._helper(item) for item in items]

    async def count_notifications(
        self,
        user_id: str,
        is_read: Optional[bool] = None,
        type: Optional[str] = None,
    ) -> int:
        query: Dict[str, Any] = {"user_id": ObjectId(user_id)}
        if is_read is not None:
            query["is_read"] = is_read
        if type:
            query["type"] = type

        return await self.collection.count_documents(query)

    async def get_unread_count(self, user_id: str) -> int:
        return await self.collection.count_documents({"user_id": ObjectId(user_id), "is_read": False})

    async def mark_as_read(self, notification_id: str, user_id: str) -> Optional[dict]:
        if not ObjectId.is_valid(notification_id):
            return None

        now = datetime.now(timezone.utc)
        result = await self.collection.find_one_and_update(
            {"_id": ObjectId(notification_id), "user_id": ObjectId(user_id)},
            {"$set": {"is_read": True, "read_at": now}},
            return_document=True,
        )
        if result:
            return self._helper(result)
        return None

    async def mark_all_as_read(self, user_id: str) -> int:
        now = datetime.now(timezone.utc)
        result = await self.collection.update_many(
            {"user_id": ObjectId(user_id), "is_read": False},
            {"$set": {"is_read": True, "read_at": now}},
        )
        return result.modified_count

    async def delete_notification(self, notification_id: str, user_id: str) -> bool:
        if not ObjectId.is_valid(notification_id):
            return False

        result = await self.collection.delete_one(
            {"_id": ObjectId(notification_id), "user_id": ObjectId(user_id)}
        )
        return result.deleted_count > 0

    async def delete_all_read(self, user_id: str) -> int:
        result = await self.collection.delete_many(
            {"user_id": ObjectId(user_id), "is_read": True}
        )
        return result.deleted_count
