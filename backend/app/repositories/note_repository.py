from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from motor.motor_asyncio import AsyncIOMotorDatabase
from bson import ObjectId
from app.models.user import user_helper


def note_helper(doc: Dict[str, Any]) -> Dict[str, Any]:
    """Helper to convert MongoDB note document to serializable dict."""
    if not doc:
        return {}
    res = dict(doc)
    if "_id" in res:
        res["id"] = str(res.pop("_id"))
    res.setdefault("blocks", [])
    res.setdefault("tags", [])
    res.setdefault("is_favorite", False)
    res.setdefault("is_pinned", False)
    res.setdefault("is_archived", False)
    return res


class NoteRepository:
    def __init__(self, db: AsyncIOMotorDatabase):
        self.collection = db["notes"]

    async def get_by_id(self, note_id: str, user_id: str) -> Optional[Dict[str, Any]]:
        try:
            doc = await self.collection.find_one({
                "_id": ObjectId(note_id),
                "user_id": user_id
            })
            return note_helper(doc) if doc else None
        except Exception:
            return None

    async def get_all_by_user(
        self,
        user_id: str,
        subject_id: Optional[str] = None,
        tag: Optional[str] = None,
        is_favorite: Optional[bool] = None,
        is_pinned: Optional[bool] = None,
        search: Optional[str] = None,
        include_archived: bool = False,
        limit: int = 100,
        skip: int = 0
    ) -> List[Dict[str, Any]]:
        query: Dict[str, Any] = {"user_id": user_id}
        if not include_archived:
            query["is_archived"] = False
        if subject_id:
            query["subject_id"] = subject_id
        if tag:
            query["tags"] = {"$regex": f"^{tag}$", "$options": "i"}
        if is_favorite is not None:
            query["is_favorite"] = is_favorite
        if is_pinned is not None:
            query["is_pinned"] = is_pinned
        if search:
            query["$or"] = [
                {"title": {"$regex": search, "$options": "i"}},
                {"blocks.content": {"$regex": search, "$options": "i"}},
                {"tags": {"$regex": search, "$options": "i"}},
            ]

        cursor = self.collection.find(query).sort([
            ("is_pinned", -1),
            ("updated_at", -1)
        ]).skip(skip).limit(limit)

        notes = []
        async for doc in cursor:
            notes.append(note_helper(doc))
        return notes

    async def get_recent(self, user_id: str, limit: int = 5) -> List[Dict[str, Any]]:
        cursor = self.collection.find({
            "user_id": user_id,
            "is_archived": False
        }).sort("updated_at", -1).limit(limit)

        notes = []
        async for doc in cursor:
            notes.append(note_helper(doc))
        return notes

    async def create(self, note_dict: Dict[str, Any]) -> Dict[str, Any]:
        now = datetime.now(timezone.utc)
        note_dict["is_archived"] = False
        note_dict["created_at"] = now
        note_dict["updated_at"] = now

        result = await self.collection.insert_one(note_dict)
        note_dict["id"] = str(result.inserted_id)
        if "_id" in note_dict:
            del note_dict["_id"]
        return note_dict

    async def update(self, note_id: str, user_id: str, update_dict: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        try:
            update_dict["updated_at"] = datetime.now(timezone.utc)
            await self.collection.update_one(
                {"_id": ObjectId(note_id), "user_id": user_id},
                {"$set": update_dict}
            )
            return await self.get_by_id(note_id, user_id)
        except Exception:
            return None

    async def delete(self, note_id: str, user_id: str) -> bool:
        try:
            res = await self.collection.delete_one({
                "_id": ObjectId(note_id),
                "user_id": user_id
            })
            return res.deleted_count > 0
        except Exception:
            return False

    async def count_by_subject(self, subject_id: str, user_id: str) -> int:
        return await self.collection.count_documents({
            "user_id": user_id,
            "subject_id": subject_id,
            "is_archived": False
        })
