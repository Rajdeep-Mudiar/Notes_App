from datetime import datetime, timezone
from typing import Any, Dict, Optional
from motor.motor_asyncio import AsyncIOMotorDatabase
from bson import ObjectId
from app.models.user import user_helper


class UserRepository:
    def __init__(self, db: AsyncIOMotorDatabase):
        self.collection = db["users"]

    async def get_by_id(self, user_id: str) -> Optional[Dict[str, Any]]:
        try:
            doc = await self.collection.find_one({"_id": ObjectId(user_id)})
            return user_helper(doc) if doc else None
        except Exception:
            return None

    async def get_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        doc = await self.collection.find_one({"email": email.strip().lower()})
        return user_helper(doc) if doc else None

    async def create(self, user_dict: Dict[str, Any]) -> Dict[str, Any]:
        now = datetime.now(timezone.utc)
        user_dict["email"] = user_dict["email"].strip().lower()
        user_dict["created_at"] = now
        user_dict["updated_at"] = now
        user_dict["is_active"] = True

        result = await self.collection.insert_one(user_dict)
        user_dict["id"] = str(result.inserted_id)
        if "_id" in user_dict:
            del user_dict["_id"]
        return user_dict

    async def update(self, user_id: str, update_dict: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        try:
            update_dict["updated_at"] = datetime.now(timezone.utc)
            await self.collection.update_one(
                {"_id": ObjectId(user_id)},
                {"$set": update_dict}
            )
            return await self.get_by_id(user_id)
        except Exception:
            return None
