from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.schemas.timetable import DayOfWeekEnum, TimetableSlotCreate, TimetableSlotUpdate


class TimetableRepository:
    def __init__(self, db: AsyncIOMotorDatabase):
        self.db = db
        self.collection = db["timetable_slots"]
        self.subjects_collection = db["subjects"]

    def _helper(self, doc: dict, subject_doc: Optional[dict] = None) -> dict:
        now = datetime.now(timezone.utc)
        sub_id = str(doc["subject_id"]) if doc.get("subject_id") else None

        title = doc.get("title")
        if not title:
            if subject_doc:
                title = subject_doc.get("name") or subject_doc.get("code") or "Class"
            else:
                title = "Class Session"

        return {
            "id": str(doc["_id"]),
            "user_id": str(doc["user_id"]),
            "subject_id": sub_id,
            "subject_code": subject_doc.get("code") if subject_doc else None,
            "subject_name": subject_doc.get("name") if subject_doc else None,
            "subject_color": subject_doc.get("color", "#4F46E5") if subject_doc else None,
            "title": title,
            "day_of_week": doc.get("day_of_week", "monday"),
            "start_time": doc.get("start_time", "09:00"),
            "end_time": doc.get("end_time", "10:00"),
            "class_type": doc.get("class_type", "lecture"),
            "location": doc.get("location", ""),
            "professor_name": doc.get("professor_name") or (subject_doc.get("professor") if subject_doc else None),
            "notes": doc.get("notes"),
            "created_at": doc.get("created_at", now),
            "updated_at": doc.get("updated_at", now),
        }

    async def _populate_subject(self, doc: dict) -> dict:
        subject_doc = None
        if doc.get("subject_id"):
            try:
                sub_id = doc["subject_id"]
                if isinstance(sub_id, str) and ObjectId.is_valid(sub_id):
                    sub_id = ObjectId(sub_id)
                subject_doc = await self.subjects_collection.find_one({"_id": sub_id})
            except Exception:
                pass
        return self._helper(doc, subject_doc)

    async def _get_subject_map(self, user_id: str) -> Dict[str, dict]:
        user_filter = [user_id]
        if ObjectId.is_valid(user_id):
            user_filter.append(ObjectId(user_id))
        cursor = self.subjects_collection.find({"user_id": {"$in": user_filter}})
        subjects = await cursor.to_list(length=100)
        return {str(s["_id"]): s for s in subjects}

    async def create_slot(self, user_id: str, data: TimetableSlotCreate) -> dict:
        now = datetime.now(timezone.utc)
        doc = {
            "user_id": ObjectId(user_id) if ObjectId.is_valid(user_id) else user_id,
            "subject_id": ObjectId(data.subject_id) if data.subject_id and ObjectId.is_valid(data.subject_id) else None,
            "title": data.title,
            "day_of_week": data.day_of_week.value,
            "start_time": data.start_time,
            "end_time": data.end_time,
            "class_type": data.class_type.value,
            "location": data.location,
            "professor_name": data.professor_name,
            "notes": data.notes,
            "created_at": now,
            "updated_at": now,
        }
        result = await self.collection.insert_one(doc)
        doc["_id"] = result.inserted_id
        return await self._populate_subject(doc)

    async def get_slot_by_id(self, slot_id: str, user_id: str) -> Optional[dict]:
        if not ObjectId.is_valid(slot_id):
            return None
        user_filter = [user_id]
        if ObjectId.is_valid(user_id):
            user_filter.append(ObjectId(user_id))

        doc = await self.collection.find_one({
            "_id": ObjectId(slot_id),
            "user_id": {"$in": user_filter},
        })
        if not doc:
            return None
        return await self._populate_subject(doc)

    async def list_slots(
        self,
        user_id: str,
        day_of_week: Optional[str] = None,
        subject_id: Optional[str] = None,
    ) -> List[dict]:
        user_filter = [user_id]
        if ObjectId.is_valid(user_id):
            user_filter.append(ObjectId(user_id))

        query: Dict[str, Any] = {"user_id": {"$in": user_filter}}
        if day_of_week:
            query["day_of_week"] = day_of_week.lower()
        if subject_id and ObjectId.is_valid(subject_id):
            query["subject_id"] = ObjectId(subject_id)

        cursor = self.collection.find(query).sort("start_time", 1)
        docs = await cursor.to_list(length=200)

        sub_map = await self._get_subject_map(user_id)
        return [self._helper(d, sub_map.get(str(d.get("subject_id")))) for d in docs]

    async def update_slot(self, slot_id: str, user_id: str, data: TimetableSlotUpdate) -> Optional[dict]:
        if not ObjectId.is_valid(slot_id):
            return None

        user_filter = [user_id]
        if ObjectId.is_valid(user_id):
            user_filter.append(ObjectId(user_id))

        update_dict: Dict[str, Any] = {"updated_at": datetime.now(timezone.utc)}
        data_dict = data.model_dump(exclude_unset=True)

        for k, v in data_dict.items():
            if v is not None:
                if k == "subject_id":
                    update_dict["subject_id"] = ObjectId(v) if v and ObjectId.is_valid(v) else None
                elif k in ["day_of_week", "class_type"]:
                    update_dict[k] = v.value if hasattr(v, "value") else str(v)
                else:
                    update_dict[k] = v

        result = await self.collection.find_one_and_update(
            {"_id": ObjectId(slot_id), "user_id": {"$in": user_filter}},
            {"$set": update_dict},
            return_document=True,
        )
        if not result:
            return None

        return await self._populate_subject(result)

    async def delete_slot(self, slot_id: str, user_id: str) -> bool:
        if not ObjectId.is_valid(slot_id):
            return False
        user_filter = [user_id]
        if ObjectId.is_valid(user_id):
            user_filter.append(ObjectId(user_id))

        result = await self.collection.delete_one({
            "_id": ObjectId(slot_id),
            "user_id": {"$in": user_filter},
        })
        return result.deleted_count > 0

    async def check_collision(
        self,
        user_id: str,
        day_of_week: str,
        start_time: str,
        end_time: str,
        exclude_slot_id: Optional[str] = None,
    ) -> bool:
        user_filter = [user_id]
        if ObjectId.is_valid(user_id):
            user_filter.append(ObjectId(user_id))

        query: Dict[str, Any] = {
            "user_id": {"$in": user_filter},
            "day_of_week": day_of_week.lower(),
        }
        if exclude_slot_id and ObjectId.is_valid(exclude_slot_id):
            query["_id"] = {"$ne": ObjectId(exclude_slot_id)}

        cursor = self.collection.find(query)
        existing_slots = await cursor.to_list(length=100)

        for slot in existing_slots:
            s_start = slot.get("start_time", "00:00")
            s_end = slot.get("end_time", "00:00")
            if s_start < end_time and s_end > start_time:
                return True

        return False
