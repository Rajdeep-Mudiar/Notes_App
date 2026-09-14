from datetime import datetime, timezone, timedelta
from typing import Any, Dict, List, Optional
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase


class AssignmentRepository:
    def __init__(self, db: AsyncIOMotorDatabase):
        self.db = db
        self.collection = db["assignments"]
        self.subjects_collection = db["subjects"]

    def _helper(self, doc: dict, subject_doc: Optional[dict] = None) -> dict:
        now = datetime.now(timezone.utc)
        due_date = doc["due_date"]
        if due_date.tzinfo is None:
            due_date = due_date.replace(tzinfo=timezone.utc)

        is_completed = doc.get("status") in ["submitted", "graded"]
        is_overdue = (due_date < now) and not is_completed

        # Countdown calculation
        countdown_text = self._calculate_countdown(due_date, now, is_completed)

        return {
            "id": str(doc["_id"]),
            "user_id": str(doc["user_id"]),
            "subject_id": str(doc["subject_id"]) if doc.get("subject_id") else None,
            "subject_code": subject_doc.get("code") if subject_doc else None,
            "subject_name": subject_doc.get("name") if subject_doc else None,
            "subject_color": subject_doc.get("color", "#4F46E5") if subject_doc else None,
            "title": doc["title"],
            "description": doc.get("description", ""),
            "due_date": due_date,
            "priority": doc.get("priority", "medium"),
            "status": doc.get("status", "pending"),
            "weight_percentage": doc.get("weight_percentage"),
            "grade_received": doc.get("grade_received"),
            "feedback": doc.get("feedback"),
            "file_ids": [str(fid) for fid in doc.get("file_ids", [])],
            "is_overdue": is_overdue,
            "countdown_text": countdown_text,
            "created_at": doc.get("created_at", now),
            "updated_at": doc.get("updated_at", now),
        }

    @staticmethod
    def _calculate_countdown(due_date: datetime, now: datetime, is_completed: bool) -> str:
        if is_completed:
            return "Completed"

        delta = due_date - now
        total_seconds = int(delta.total_seconds())

        if total_seconds < 0:
            past_days = abs(total_seconds) // 86400
            if past_days == 0:
                return "Overdue (Today)"
            elif past_days == 1:
                return "Overdue by 1 day"
            else:
                return f"Overdue by {past_days} days"

        days = total_seconds // 86400
        hours = (total_seconds % 86400) // 3600

        if days == 0:
            if hours == 0:
                minutes = (total_seconds % 3600) // 60
                return f"Due in {max(1, minutes)} mins"
            elif hours == 1:
                return "Due in 1 hour"
            else:
                return f"Due in {hours} hours"
        elif days == 1:
            return "Due Tomorrow"
        elif days < 7:
            return f"Due in {days} days"
        elif days < 14:
            return "Due next week"
        else:
            return f"Due in {days // 7} weeks"

    async def _populate_subject(self, doc: dict) -> dict:
        subject_doc = None
        if doc.get("subject_id"):
            try:
                subject_doc = await self.subjects_collection.find_one({"_id": doc["subject_id"]})
            except Exception:
                pass
        return self._helper(doc, subject_doc)

    async def create(self, data: Dict[str, Any]) -> dict:
        now = datetime.now(timezone.utc)
        due_date = data["due_date"]
        if isinstance(due_date, str):
            due_date = datetime.fromisoformat(due_date.replace("Z", "+00:00"))
        if due_date.tzinfo is None:
            due_date = due_date.replace(tzinfo=timezone.utc)

        file_object_ids = []
        for fid in data.get("file_ids", []):
            try:
                file_object_ids.append(ObjectId(fid))
            except Exception:
                pass

        doc = {
            "user_id": ObjectId(data["user_id"]),
            "subject_id": ObjectId(data["subject_id"]) if data.get("subject_id") else None,
            "title": data["title"],
            "description": data.get("description", ""),
            "due_date": due_date,
            "priority": data.get("priority", "medium"),
            "status": data.get("status", "pending"),
            "weight_percentage": data.get("weight_percentage"),
            "grade_received": data.get("grade_received"),
            "feedback": data.get("feedback"),
            "file_ids": file_object_ids,
            "created_at": now,
            "updated_at": now,
        }
        result = await self.collection.insert_one(doc)
        doc["_id"] = result.inserted_id
        return await self._populate_subject(doc)

    async def get_by_id(self, assignment_id: str, user_id: str) -> Optional[dict]:
        try:
            doc = await self.collection.find_one({
                "_id": ObjectId(assignment_id),
                "user_id": ObjectId(user_id),
            })
            return await self._populate_subject(doc) if doc else None
        except Exception:
            return None

    async def get_all(
        self,
        user_id: str,
        subject_id: Optional[str] = None,
        status: Optional[str] = None,
        priority: Optional[str] = None,
        search: Optional[str] = None,
        limit: int = 100,
        skip: int = 0,
    ) -> List[dict]:
        query: Dict[str, Any] = {"user_id": ObjectId(user_id)}

        if subject_id:
            try:
                query["subject_id"] = ObjectId(subject_id)
            except Exception:
                return []

        if status:
            query["status"] = status.lower()

        if priority:
            query["priority"] = priority.lower()

        if search:
            query["title"] = {"$regex": search, "$options": "i"}

        cursor = self.collection.find(query).sort("due_date", 1).skip(skip).limit(limit)
        docs = await cursor.to_list(length=limit)

        results = []
        for d in docs:
            results.append(await self._populate_subject(d))
        return results

    async def get_upcoming(self, user_id: str, limit: int = 5) -> List[dict]:
        query = {
            "user_id": ObjectId(user_id),
            "status": {"$in": ["pending", "in_progress"]},
        }
        cursor = self.collection.find(query).sort("due_date", 1).limit(limit)
        docs = await cursor.to_list(length=limit)

        results = []
        for d in docs:
            results.append(await self._populate_subject(d))
        return results

    async def update(self, assignment_id: str, user_id: str, data: Dict[str, Any]) -> Optional[dict]:
        try:
            update_fields: Dict[str, Any] = {"updated_at": datetime.now(timezone.utc)}

            for key in ["title", "description", "priority", "status", "weight_percentage", "grade_received", "feedback"]:
                if key in data and data[key] is not None:
                    update_fields[key] = data[key]

            if "subject_id" in data:
                update_fields["subject_id"] = ObjectId(data["subject_id"]) if data["subject_id"] else None

            if "due_date" in data and data["due_date"] is not None:
                due_date = data["due_date"]
                if isinstance(due_date, str):
                    due_date = datetime.fromisoformat(due_date.replace("Z", "+00:00"))
                if due_date.tzinfo is None:
                    due_date = due_date.replace(tzinfo=timezone.utc)
                update_fields["due_date"] = due_date

            if "file_ids" in data and data["file_ids"] is not None:
                update_fields["file_ids"] = [ObjectId(fid) for fid in data["file_ids"] if ObjectId.is_valid(fid)]

            await self.collection.update_one(
                {"_id": ObjectId(assignment_id), "user_id": ObjectId(user_id)},
                {"$set": update_fields}
            )

            return await self.get_by_id(assignment_id, user_id)
        except Exception:
            return None

    async def delete(self, assignment_id: str, user_id: str) -> Optional[dict]:
        try:
            doc = await self.get_by_id(assignment_id, user_id)
            if not doc:
                return None
            await self.collection.delete_one({"_id": ObjectId(assignment_id), "user_id": ObjectId(user_id)})
            return doc
        except Exception:
            return None

    async def count_by_subject(self, subject_id: str, user_id: str) -> int:
        try:
            return await self.collection.count_documents({
                "user_id": ObjectId(user_id),
                "subject_id": ObjectId(subject_id),
            })
        except Exception:
            return 0

    async def get_summary(self, user_id: str) -> Dict[str, int]:
        uid = ObjectId(user_id)
        now = datetime.now(timezone.utc)
        week_ahead = now + timedelta(days=7)

        total = await self.collection.count_documents({"user_id": uid})
        pending = await self.collection.count_documents({"user_id": uid, "status": "pending"})
        in_progress = await self.collection.count_documents({"user_id": uid, "status": "in_progress"})
        submitted = await self.collection.count_documents({"user_id": uid, "status": "submitted"})
        graded = await self.collection.count_documents({"user_id": uid, "status": "graded"})

        overdue = await self.collection.count_documents({
            "user_id": uid,
            "status": {"$in": ["pending", "in_progress"]},
            "due_date": {"$lt": now},
        })

        due_this_week = await self.collection.count_documents({
            "user_id": uid,
            "status": {"$in": ["pending", "in_progress"]},
            "due_date": {"$gte": now, "$lte": week_ahead},
        })

        return {
            "total_assignments": total,
            "pending_count": pending,
            "in_progress_count": in_progress,
            "submitted_count": submitted,
            "graded_count": graded,
            "overdue_count": overdue,
            "due_this_week_count": due_this_week,
        }
