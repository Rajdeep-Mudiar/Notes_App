from datetime import datetime, timezone, timedelta
from typing import Any, Dict, List, Optional
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase


class ExamRepository:
    def __init__(self, db: AsyncIOMotorDatabase):
        self.db = db
        self.collection = db["exams"]
        self.subjects_collection = db["subjects"]
        self.assignments_collection = db["assignments"]

    def _helper(self, doc: dict, subject_doc: Optional[dict] = None) -> dict:
        now = datetime.now(timezone.utc)
        dt = doc["date_time"]
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)

        has_grade = doc.get("actual_grade") is not None
        is_past = dt < now
        is_completed = has_grade or is_past

        # Countdown calculation
        countdown_text = self._calculate_countdown(dt, now, is_completed)

        return {
            "id": str(doc["_id"]),
            "user_id": str(doc["user_id"]),
            "subject_id": str(doc["subject_id"]) if doc.get("subject_id") else None,
            "subject_code": subject_doc.get("code") if subject_doc else None,
            "subject_name": subject_doc.get("name") if subject_doc else None,
            "subject_color": subject_doc.get("color", "#4F46E5") if subject_doc else None,
            "title": doc["title"],
            "exam_type": doc.get("exam_type", "midterm"),
            "date_time": dt,
            "duration_minutes": doc.get("duration_minutes", 60),
            "location": doc.get("location", ""),
            "seat_number": doc.get("seat_number"),
            "syllabus_topics": doc.get("syllabus_topics", []),
            "weight_percentage": doc.get("weight_percentage"),
            "target_grade": doc.get("target_grade"),
            "actual_grade": doc.get("actual_grade"),
            "notes": doc.get("notes", ""),
            "is_completed": is_completed,
            "countdown_text": countdown_text,
            "created_at": doc.get("created_at", now),
            "updated_at": doc.get("updated_at", now),
        }

    @staticmethod
    def _calculate_countdown(dt: datetime, now: datetime, is_completed: bool) -> str:
        delta = dt - now
        total_seconds = int(delta.total_seconds())

        if total_seconds < 0:
            past_days = abs(total_seconds) // 86400
            if past_days == 0:
                return "Ended Today"
            elif past_days == 1:
                return "Completed 1 day ago"
            else:
                return f"Completed {past_days} days ago"

        days = total_seconds // 86400
        hours = (total_seconds % 86400) // 3600

        if days == 0:
            if hours == 0:
                minutes = max(1, (total_seconds % 3600) // 60)
                return f"Starting in {minutes} mins"
            elif hours == 1:
                return "In 1 hour"
            else:
                return f"In {hours} hours"
        elif days == 1:
            return "Tomorrow"
        elif days < 7:
            return f"In {days} days"
        elif days < 14:
            return "Next week"
        else:
            return f"In {days // 7} weeks"

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
        dt = data["date_time"]
        if isinstance(dt, str):
            dt = datetime.fromisoformat(dt.replace("Z", "+00:00"))
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)

        doc = {
            "user_id": ObjectId(data["user_id"]),
            "subject_id": ObjectId(data["subject_id"]) if data.get("subject_id") else None,
            "title": data["title"],
            "exam_type": data.get("exam_type", "midterm"),
            "date_time": dt,
            "duration_minutes": data.get("duration_minutes", 60),
            "location": data.get("location", ""),
            "seat_number": data.get("seat_number"),
            "syllabus_topics": data.get("syllabus_topics", []),
            "weight_percentage": data.get("weight_percentage"),
            "target_grade": data.get("target_grade"),
            "actual_grade": data.get("actual_grade"),
            "notes": data.get("notes", ""),
            "created_at": now,
            "updated_at": now,
        }
        result = await self.collection.insert_one(doc)
        doc["_id"] = result.inserted_id
        return await self._populate_subject(doc)

    async def get_by_id(self, exam_id: str, user_id: str) -> Optional[dict]:
        try:
            doc = await self.collection.find_one({
                "_id": ObjectId(exam_id),
                "user_id": ObjectId(user_id),
            })
            return await self._populate_subject(doc) if doc else None
        except Exception:
            return None

    async def get_all(
        self,
        user_id: str,
        subject_id: Optional[str] = None,
        exam_type: Optional[str] = None,
        is_upcoming: Optional[bool] = None,
        search: Optional[str] = None,
        limit: int = 100,
        skip: int = 0,
    ) -> List[dict]:
        query: Dict[str, Any] = {"user_id": ObjectId(user_id)}
        now = datetime.now(timezone.utc)

        if subject_id:
            try:
                query["subject_id"] = ObjectId(subject_id)
            except Exception:
                return []

        if exam_type:
            query["exam_type"] = exam_type.lower()

        if is_upcoming is True:
            query["date_time"] = {"$gte": now}
        elif is_upcoming is False:
            query["date_time"] = {"$lt": now}

        if search:
            query["title"] = {"$regex": search, "$options": "i"}

        sort_direction = 1 if is_upcoming is not False else -1
        cursor = self.collection.find(query).sort("date_time", sort_direction).skip(skip).limit(limit)
        docs = await cursor.to_list(length=limit)

        results = []
        for d in docs:
            results.append(await self._populate_subject(d))
        return results

    async def get_upcoming(self, user_id: str, limit: int = 5) -> List[dict]:
        now = datetime.now(timezone.utc)
        query = {
            "user_id": ObjectId(user_id),
            "date_time": {"$gte": now},
        }
        cursor = self.collection.find(query).sort("date_time", 1).limit(limit)
        docs = await cursor.to_list(length=limit)

        results = []
        for d in docs:
            results.append(await self._populate_subject(d))
        return results

    async def get_calendar_events(
        self,
        user_id: str,
        start_date: datetime,
        end_date: datetime,
    ) -> List[dict]:
        uid = ObjectId(user_id)
        if start_date.tzinfo is None:
            start_date = start_date.replace(tzinfo=timezone.utc)
        if end_date.tzinfo is None:
            end_date = end_date.replace(tzinfo=timezone.utc)

        # 1. Fetch Exams in range
        exams_cursor = self.collection.find({
            "user_id": uid,
            "date_time": {"$gte": start_date, "$lte": end_date},
        }).sort("date_time", 1)
        exam_docs = await exams_cursor.to_list(length=200)

        # 2. Fetch Assignments in range
        asgns_cursor = self.assignments_collection.find({
            "user_id": uid,
            "due_date": {"$gte": start_date, "$lte": end_date},
        }).sort("due_date", 1)
        asgn_docs = await asgns_cursor.to_list(length=200)

        # Fetch subjects lookup map
        subjects_cursor = self.subjects_collection.find({"user_id": uid})
        sub_docs = await subjects_cursor.to_list(length=100)
        sub_map = {str(s["_id"]): s for s in sub_docs}

        events = []

        for e in exam_docs:
            sub_id = str(e["subject_id"]) if e.get("subject_id") else None
            sub = sub_map.get(sub_id)
            dt = e["date_time"]
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)

            events.append({
                "id": str(e["_id"]),
                "type": "exam",
                "title": e["title"],
                "date_time": dt,
                "subject_code": sub.get("code") if sub else None,
                "subject_name": sub.get("name") if sub else None,
                "subject_color": sub.get("color", "#4F46E5") if sub else None,
                "priority_or_type": e.get("exam_type", "midterm"),
                "is_completed": e.get("actual_grade") is not None or dt < datetime.now(timezone.utc),
                "location_or_desc": e.get("location", ""),
            })

        for a in asgn_docs:
            sub_id = str(a["subject_id"]) if a.get("subject_id") else None
            sub = sub_map.get(sub_id)
            dt = a["due_date"]
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)

            is_completed = a.get("status") in ["submitted", "graded"]
            events.append({
                "id": str(a["_id"]),
                "type": "assignment",
                "title": a["title"],
                "date_time": dt,
                "subject_code": sub.get("code") if sub else None,
                "subject_name": sub.get("name") if sub else None,
                "subject_color": sub.get("color", "#4F46E5") if sub else None,
                "priority_or_type": a.get("priority", "medium"),
                "is_completed": is_completed,
                "location_or_desc": a.get("description", ""),
            })

        # Sort combined events chronologically
        events.sort(key=lambda x: x["date_time"])
        return events

    async def update(self, exam_id: str, user_id: str, data: Dict[str, Any]) -> Optional[dict]:
        try:
            update_fields: Dict[str, Any] = {"updated_at": datetime.now(timezone.utc)}

            for key in ["title", "exam_type", "duration_minutes", "location", "seat_number", "syllabus_topics", "weight_percentage", "target_grade", "actual_grade", "notes"]:
                if key in data and data[key] is not None:
                    update_fields[key] = data[key]

            if "subject_id" in data:
                update_fields["subject_id"] = ObjectId(data["subject_id"]) if data["subject_id"] else None

            if "date_time" in data and data["date_time"] is not None:
                dt = data["date_time"]
                if isinstance(dt, str):
                    dt = datetime.fromisoformat(dt.replace("Z", "+00:00"))
                if dt.tzinfo is None:
                    dt = dt.replace(tzinfo=timezone.utc)
                update_fields["date_time"] = dt

            await self.collection.update_one(
                {"_id": ObjectId(exam_id), "user_id": ObjectId(user_id)},
                {"$set": update_fields}
            )

            return await self.get_by_id(exam_id, user_id)
        except Exception:
            return None

    async def delete(self, exam_id: str, user_id: str) -> Optional[dict]:
        try:
            doc = await self.get_by_id(exam_id, user_id)
            if not doc:
                return None
            await self.collection.delete_one({"_id": ObjectId(exam_id), "user_id": ObjectId(user_id)})
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

        total = await self.collection.count_documents({"user_id": uid})
        upcoming = await self.collection.count_documents({"user_id": uid, "date_time": {"$gte": now}})
        completed = total - upcoming

        return {
            "total": total,
            "upcoming_count": upcoming,
            "completed_count": completed,
        }
