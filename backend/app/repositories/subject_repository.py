from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from motor.motor_asyncio import AsyncIOMotorDatabase
from bson import ObjectId
from app.models.user import user_helper


def subject_helper(doc: Dict[str, Any]) -> Dict[str, Any]:
    """Helper to convert MongoDB subject document to serializable dict."""
    if not doc:
        return {}
    res = dict(doc)
    if "_id" in res:
        res["id"] = str(res.pop("_id"))
    res.setdefault("notes_count", 0)
    res.setdefault("files_count", 0)
    res.setdefault("assignments_count", 0)
    res.setdefault("exams_count", 0)
    return res


class SubjectRepository:
    def __init__(self, db: AsyncIOMotorDatabase):
        self.collection = db["subjects"]

    async def get_by_id(self, subject_id: str, user_id: str) -> Optional[Dict[str, Any]]:
        try:
            doc = await self.collection.find_one({
                "_id": ObjectId(subject_id),
                "user_id": user_id
            })
            return subject_helper(doc) if doc else None
        except Exception:
            return None

    async def get_by_code_and_semester(self, user_id: str, code: str, semester: int) -> Optional[Dict[str, Any]]:
        doc = await self.collection.find_one({
            "user_id": user_id,
            "code": code.strip().upper(),
            "semester": semester
        })
        return subject_helper(doc) if doc else None

    async def get_all_by_user(
        self,
        user_id: str,
        semester: Optional[int] = None,
        include_archived: bool = False
    ) -> List[Dict[str, Any]]:
        query: Dict[str, Any] = {"user_id": user_id}
        if semester is not None:
            query["semester"] = semester
        if not include_archived:
            query["is_archived"] = False

        cursor = self.collection.find(query).sort([("semester", 1), ("created_at", -1)])
        subjects = []
        async for doc in cursor:
            subjects.append(subject_helper(doc))
        return subjects

    async def create(self, subject_dict: Dict[str, Any]) -> Dict[str, Any]:
        now = datetime.now(timezone.utc)
        subject_dict["code"] = subject_dict["code"].strip().upper()
        subject_dict["is_archived"] = False
        subject_dict["created_at"] = now
        subject_dict["updated_at"] = now
        subject_dict["notes_count"] = 0
        subject_dict["files_count"] = 0
        subject_dict["assignments_count"] = 0
        subject_dict["exams_count"] = 0

        result = await self.collection.insert_one(subject_dict)
        subject_dict["id"] = str(result.inserted_id)
        if "_id" in subject_dict:
            del subject_dict["_id"]
        return subject_dict

    async def update(self, subject_id: str, user_id: str, update_dict: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        try:
            if "code" in update_dict and update_dict["code"]:
                update_dict["code"] = update_dict["code"].strip().upper()
            update_dict["updated_at"] = datetime.now(timezone.utc)

            await self.collection.update_one(
                {"_id": ObjectId(subject_id), "user_id": user_id},
                {"$set": update_dict}
            )
            return await self.get_by_id(subject_id, user_id)
        except Exception:
            return None

    async def delete(self, subject_id: str, user_id: str) -> bool:
        try:
            res = await self.collection.delete_one({
                "_id": ObjectId(subject_id),
                "user_id": user_id
            })
            return res.deleted_count > 0
        except Exception:
            return False

    async def get_academic_summary(self, user_id: str, current_semester: int) -> Dict[str, Any]:
        cursor = self.collection.find({"user_id": user_id})
        all_subjects = []
        async for doc in cursor:
            all_subjects.append(doc)

        total_subjects = len(all_subjects)
        active_subjects = [s for s in all_subjects if not s.get("is_archived", False)]
        archived_subjects = [s for s in all_subjects if s.get("is_archived", False)]
        
        total_credits = sum(s.get("credits", 0) for s in active_subjects)
        current_sem_subjects = [s for s in active_subjects if s.get("semester") == current_semester]
        semester_credits = sum(s.get("credits", 0) for s in current_sem_subjects)

        return {
            "total_subjects": total_subjects,
            "active_subjects": len(active_subjects),
            "archived_subjects": len(archived_subjects),
            "total_credits": total_credits,
            "current_semester": current_semester,
            "semester_credits": semester_credits
        }
