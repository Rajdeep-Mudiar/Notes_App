from datetime import date, datetime, timezone
import math
from typing import Any, Dict, List, Optional
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.schemas.timetable import (
    AttendanceLogCreate,
    AttendanceLogUpdate,
    AttendanceStatusEnum,
    AttendanceSummaryResponse,
    SubjectAttendanceStats,
)


class AttendanceRepository:
    def __init__(self, db: AsyncIOMotorDatabase):
        self.db = db
        self.collection = db["attendance_logs"]
        self.subjects_collection = db["subjects"]
        self.slots_collection = db["timetable_slots"]

    def _helper(self, doc: dict, subject_doc: Optional[dict] = None) -> dict:
        now = datetime.now(timezone.utc)
        sub_id = str(doc["subject_id"]) if doc.get("subject_id") else None

        d = doc.get("date")
        if isinstance(d, datetime):
            d = d.date()
        elif isinstance(d, str):
            d = date.fromisoformat(d)
        elif not isinstance(d, date):
            d = now.date()

        return {
            "id": str(doc["_id"]),
            "user_id": str(doc["user_id"]),
            "slot_id": str(doc["slot_id"]) if doc.get("slot_id") else None,
            "subject_id": sub_id,
            "subject_code": subject_doc.get("code") if subject_doc else None,
            "subject_name": subject_doc.get("name") if subject_doc else None,
            "subject_color": subject_doc.get("color", "#4F46E5") if subject_doc else None,
            "date": d,
            "status": doc.get("status", "present"),
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

    async def log_attendance(self, user_id: str, data: AttendanceLogCreate) -> dict:
        now = datetime.now(timezone.utc)
        user_filter = [user_id]
        if ObjectId.is_valid(user_id):
            user_filter.append(ObjectId(user_id))

        subject_id = data.subject_id
        if not subject_id and data.slot_id and ObjectId.is_valid(data.slot_id):
            slot = await self.slots_collection.find_one({"_id": ObjectId(data.slot_id)})
            if slot and slot.get("subject_id"):
                subject_id = str(slot["subject_id"])

        query: Dict[str, Any] = {
            "user_id": {"$in": user_filter},
            "date": data.date.isoformat(),
        }
        if data.slot_id and ObjectId.is_valid(data.slot_id):
            query["slot_id"] = ObjectId(data.slot_id)
        elif subject_id and ObjectId.is_valid(subject_id):
            query["subject_id"] = ObjectId(subject_id)

        existing = await self.collection.find_one(query)

        if existing:
            updated = await self.collection.find_one_and_update(
                {"_id": existing["_id"]},
                {
                    "$set": {
                        "status": data.status.value,
                        "notes": data.notes,
                        "updated_at": now,
                    }
                },
                return_document=True,
            )
            return await self._populate_subject(updated)

        doc = {
            "user_id": ObjectId(user_id) if ObjectId.is_valid(user_id) else user_id,
            "slot_id": ObjectId(data.slot_id) if data.slot_id and ObjectId.is_valid(data.slot_id) else None,
            "subject_id": ObjectId(subject_id) if subject_id and ObjectId.is_valid(subject_id) else None,
            "date": data.date.isoformat(),
            "status": data.status.value,
            "notes": data.notes,
            "created_at": now,
            "updated_at": now,
        }
        result = await self.collection.insert_one(doc)
        doc["_id"] = result.inserted_id
        return await self._populate_subject(doc)

    async def get_log_by_id(self, log_id: str, user_id: str) -> Optional[dict]:
        if not ObjectId.is_valid(log_id):
            return None
        user_filter = [user_id]
        if ObjectId.is_valid(user_id):
            user_filter.append(ObjectId(user_id))

        doc = await self.collection.find_one({
            "_id": ObjectId(log_id),
            "user_id": {"$in": user_filter},
        })
        if not doc:
            return None
        return await self._populate_subject(doc)

    async def list_logs(
        self,
        user_id: str,
        subject_id: Optional[str] = None,
        slot_id: Optional[str] = None,
        limit: int = 100,
    ) -> List[dict]:
        user_filter = [user_id]
        if ObjectId.is_valid(user_id):
            user_filter.append(ObjectId(user_id))

        query: Dict[str, Any] = {"user_id": {"$in": user_filter}}
        if subject_id and ObjectId.is_valid(subject_id):
            query["subject_id"] = ObjectId(subject_id)
        if slot_id and ObjectId.is_valid(slot_id):
            query["slot_id"] = ObjectId(slot_id)

        cursor = self.collection.find(query).sort("date", -1).limit(limit)
        docs = await cursor.to_list(length=limit)

        sub_map = await self._get_subject_map(user_id)
        return [self._helper(d, sub_map.get(str(d.get("subject_id")))) for d in docs]

    async def get_logs_for_date(self, user_id: str, target_date: date) -> Dict[str, dict]:
        date_str = target_date.isoformat()
        user_filter = [user_id]
        if ObjectId.is_valid(user_id):
            user_filter.append(ObjectId(user_id))

        cursor = self.collection.find({
            "user_id": {"$in": user_filter},
            "date": date_str,
        })
        docs = await cursor.to_list(length=50)

        result: Dict[str, dict] = {}
        for d in docs:
            if d.get("slot_id"):
                result[str(d["slot_id"])] = d
            if d.get("subject_id"):
                result[f"sub_{str(d['subject_id'])}"] = d
        return result

    async def update_log(self, log_id: str, user_id: str, data: AttendanceLogUpdate) -> Optional[dict]:
        if not ObjectId.is_valid(log_id):
            return None

        user_filter = [user_id]
        if ObjectId.is_valid(user_id):
            user_filter.append(ObjectId(user_id))

        update_dict: Dict[str, Any] = {"updated_at": datetime.now(timezone.utc)}
        if data.status is not None:
            update_dict["status"] = data.status.value
        if data.notes is not None:
            update_dict["notes"] = data.notes

        result = await self.collection.find_one_and_update(
            {"_id": ObjectId(log_id), "user_id": {"$in": user_filter}},
            {"$set": update_dict},
            return_document=True,
        )
        if not result:
            return None

        return await self._populate_subject(result)

    async def delete_log(self, log_id: str, user_id: str) -> bool:
        if not ObjectId.is_valid(log_id):
            return False
        user_filter = [user_id]
        if ObjectId.is_valid(user_id):
            user_filter.append(ObjectId(user_id))

        result = await self.collection.delete_one({
            "_id": ObjectId(log_id),
            "user_id": {"$in": user_filter},
        })
        return result.deleted_count > 0

    @staticmethod
    def _calculate_attendance_math(
        attended: int,
        total: int,
        target_pct: float = 75.0,
    ) -> tuple[float, int, int]:
        if total == 0:
            return (100.0, 0, 0)

        pct = round((attended / total) * 100.0, 1)
        target_fraction = target_pct / 100.0

        if pct >= target_pct:
            safe_bunks = max(0, math.floor((attended / target_fraction) - total))
            classes_needed = 0
        else:
            safe_bunks = 0
            numerator = target_fraction * total - attended
            denominator = 1.0 - target_fraction
            classes_needed = max(1, math.ceil(numerator / denominator))

        return (pct, safe_bunks, classes_needed)

    async def get_attendance_summary(self, user_id: str, target_percentage: float = 75.0) -> AttendanceSummaryResponse:
        user_filter = [user_id]
        if ObjectId.is_valid(user_id):
            user_filter.append(ObjectId(user_id))

        subjects_cursor = self.subjects_collection.find({
            "user_id": {"$in": user_filter},
            "is_archived": False,
        })
        subjects = await subjects_cursor.to_list(length=100)

        logs_cursor = self.collection.find({"user_id": {"$in": user_filter}})
        all_logs = await logs_cursor.to_list(length=1000)

        subject_logs: Dict[str, List[dict]] = {}
        for log in all_logs:
            sub_id = str(log.get("subject_id")) if log.get("subject_id") else None
            if sub_id:
                subject_logs.setdefault(sub_id, []).append(log)

        overall_total = 0
        overall_attended = 0
        overall_absent = 0
        critical_count = 0
        subject_stats_list: List[SubjectAttendanceStats] = []

        for sub in subjects:
            sub_id = str(sub["_id"])
            logs = subject_logs.get(sub_id, [])

            total = len(logs)
            present = sum(1 for l in logs if l.get("status") == "present")
            late = sum(1 for l in logs if l.get("status") == "late")
            excused = sum(1 for l in logs if l.get("status") == "excused")
            absent = sum(1 for l in logs if l.get("status") == "absent")
            
            attended = present + late + excused

            pct, safe_bunks, classes_needed = self._calculate_attendance_math(
                attended=attended,
                total=total,
                target_pct=target_percentage,
            )

            is_critical = pct < target_percentage and total > 0
            if is_critical:
                critical_count += 1

            overall_total += total
            overall_attended += attended
            overall_absent += absent

            subject_stats_list.append(
                SubjectAttendanceStats(
                    subject_id=sub_id,
                    subject_code=sub.get("code", "SUB"),
                    subject_name=sub.get("name", "Subject"),
                    subject_color=sub.get("color", "#4F46E5"),
                    total_classes=total,
                    attended_classes=attended,
                    absent_classes=absent,
                    late_classes=late,
                    excused_classes=excused,
                    attendance_percentage=pct,
                    target_percentage=target_percentage,
                    is_critical=is_critical,
                    safe_bunks=safe_bunks,
                    classes_needed_to_target=classes_needed,
                )
            )

        overall_pct = (
            round((overall_attended / overall_total) * 100.0, 1)
            if overall_total > 0
            else 100.0
        )

        return AttendanceSummaryResponse(
            overall_total_classes=overall_total,
            overall_attended_classes=overall_attended,
            overall_absent_classes=overall_absent,
            overall_percentage=overall_pct,
            minimum_required_percentage=target_percentage,
            critical_subjects_count=critical_count,
            subjects_stats=subject_stats_list,
        )
