from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.schemas.analytics import SubjectGradeInput


class AnalyticsRepository:
    def __init__(self, db: AsyncIOMotorDatabase):
        self.db = db
        self.subjects_collection = db["subjects"]
        self.users_collection = db["users"]

    async def get_user_subjects(self, user_id: str) -> List[dict]:
        user_filter = [user_id]
        if ObjectId.is_valid(user_id):
            user_filter.append(ObjectId(user_id))

        cursor = self.subjects_collection.find({"user_id": {"$in": user_filter}}).sort([
            ("semester", 1),
            ("code", 1),
        ])
        return await cursor.to_list(length=200)

    async def get_subject_by_id(self, subject_id: str, user_id: str) -> Optional[dict]:
        if not ObjectId.is_valid(subject_id):
            return None
        user_filter = [user_id]
        if ObjectId.is_valid(user_id):
            user_filter.append(ObjectId(user_id))

        return await self.subjects_collection.find_one({
            "_id": ObjectId(subject_id),
            "user_id": {"$in": user_filter},
        })

    async def update_subject_grade(
        self,
        subject_id: str,
        user_id: str,
        letter_grade: Optional[str],
        numerical_grade: Optional[float],
        grade_point: Optional[float],
        target_grade: Optional[str],
    ) -> Optional[dict]:
        if not ObjectId.is_valid(subject_id):
            return None
        user_filter = [user_id]
        if ObjectId.is_valid(user_id):
            user_filter.append(ObjectId(user_id))

        update_dict: Dict[str, Any] = {
            "updated_at": datetime.now(timezone.utc),
            "letter_grade": letter_grade,
            "numerical_grade": numerical_grade,
            "grade_point": grade_point,
            "target_grade": target_grade,
        }

        return await self.subjects_collection.find_one_and_update(
            {"_id": ObjectId(subject_id), "user_id": {"$in": user_filter}},
            {"$set": update_dict},
            return_document=True,
        )

    async def get_user_profile(self, user_id: str) -> Optional[dict]:
        if not ObjectId.is_valid(user_id):
            return None
        return await self.users_collection.find_one({"_id": ObjectId(user_id)})
