from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase


class FileRepository:
    def __init__(self, db: AsyncIOMotorDatabase):
        self.db = db
        self.files_collection = db["files"]
        self.folders_collection = db["folders"]

    def _file_helper(self, file_doc: dict) -> dict:
        return {
            "id": str(file_doc["_id"]),
            "user_id": str(file_doc["user_id"]),
            "subject_id": str(file_doc["subject_id"]) if file_doc.get("subject_id") else None,
            "folder_id": str(file_doc["folder_id"]) if file_doc.get("folder_id") else None,
            "filename": file_doc["filename"],
            "original_name": file_doc["original_name"],
            "file_type": file_doc["file_type"],
            "mime_type": file_doc["mime_type"],
            "size_bytes": file_doc["size_bytes"],
            "size_formatted": file_doc["size_formatted"],
            "download_url": file_doc.get("download_url", f"/api/v1/files/{str(file_doc['_id'])}/download"),
            "is_favorite": file_doc.get("is_favorite", False),
            "created_at": file_doc.get("created_at", datetime.now(timezone.utc)),
            "updated_at": file_doc.get("updated_at", datetime.now(timezone.utc)),
        }

    def _folder_helper(self, folder_doc: dict, items_count: int = 0) -> dict:
        return {
            "id": str(folder_doc["_id"]),
            "user_id": str(folder_doc["user_id"]),
            "name": folder_doc["name"],
            "subject_id": str(folder_doc["subject_id"]) if folder_doc.get("subject_id") else None,
            "parent_id": str(folder_doc["parent_id"]) if folder_doc.get("parent_id") else None,
            "color": folder_doc.get("color", "#4F46E5"),
            "icon": folder_doc.get("icon", "folder"),
            "items_count": items_count,
            "created_at": folder_doc.get("created_at", datetime.now(timezone.utc)),
            "updated_at": folder_doc.get("updated_at", datetime.now(timezone.utc)),
        }

    # ==================== FILES ====================

    async def create_file(self, file_data: Dict[str, Any]) -> dict:
        now = datetime.now(timezone.utc)
        doc = {
            "user_id": ObjectId(file_data["user_id"]),
            "subject_id": ObjectId(file_data["subject_id"]) if file_data.get("subject_id") else None,
            "folder_id": ObjectId(file_data["folder_id"]) if file_data.get("folder_id") else None,
            "filename": file_data["filename"],
            "original_name": file_data["original_name"],
            "file_type": file_data["file_type"],
            "mime_type": file_data["mime_type"],
            "size_bytes": file_data["size_bytes"],
            "size_formatted": file_data["size_formatted"],
            "download_url": file_data.get("download_url", ""),
            "is_favorite": file_data.get("is_favorite", False),
            "created_at": now,
            "updated_at": now,
        }
        result = await self.files_collection.insert_one(doc)
        doc["_id"] = result.inserted_id
        if not doc["download_url"]:
            doc["download_url"] = f"/api/v1/files/{str(result.inserted_id)}/download"
            await self.files_collection.update_one({"_id": result.inserted_id}, {"$set": {"download_url": doc["download_url"]}})
        return self._file_helper(doc)

    async def get_file_by_id(self, file_id: str, user_id: str) -> Optional[dict]:
        try:
            doc = await self.files_collection.find_one({
                "_id": ObjectId(file_id),
                "user_id": ObjectId(user_id)
            })
            return self._file_helper(doc) if doc else None
        except Exception:
            return None

    async def get_files(
        self,
        user_id: str,
        subject_id: Optional[str] = None,
        folder_id: Optional[str] = None,
        file_type: Optional[str] = None,
        search: Optional[str] = None,
        is_favorite: Optional[bool] = None,
        limit: int = 100,
        skip: int = 0,
    ) -> List[dict]:
        query: Dict[str, Any] = {"user_id": ObjectId(user_id)}

        if subject_id:
            try:
                query["subject_id"] = ObjectId(subject_id)
            except Exception:
                return []

        if folder_id is not None:
            if folder_id == "root" or folder_id == "":
                query["folder_id"] = None
            else:
                try:
                    query["folder_id"] = ObjectId(folder_id)
                except Exception:
                    return []

        if file_type:
            query["file_type"] = file_type.lower()

        if is_favorite is not None:
            query["is_favorite"] = is_favorite

        if search:
            query["original_name"] = {"$regex": search, "$options": "i"}

        cursor = self.files_collection.find(query).sort("created_at", -1).skip(skip).limit(limit)
        docs = await cursor.to_list(length=limit)
        return [self._file_helper(d) for d in docs]

    async def count_files(
        self,
        user_id: str,
        subject_id: Optional[str] = None,
        folder_id: Optional[str] = None,
        file_type: Optional[str] = None,
        search: Optional[str] = None,
    ) -> int:
        query: Dict[str, Any] = {"user_id": ObjectId(user_id)}
        if subject_id:
            try:
                query["subject_id"] = ObjectId(subject_id)
            except Exception:
                return 0
        if folder_id is not None:
            if folder_id == "root" or folder_id == "":
                query["folder_id"] = None
            else:
                try:
                    query["folder_id"] = ObjectId(folder_id)
                except Exception:
                    return 0
        if file_type:
            query["file_type"] = file_type.lower()
        if search:
            query["original_name"] = {"$regex": search, "$options": "i"}

        return await self.files_collection.count_documents(query)

    async def delete_file(self, file_id: str, user_id: str) -> Optional[dict]:
        try:
            doc = await self.files_collection.find_one({
                "_id": ObjectId(file_id),
                "user_id": ObjectId(user_id)
            })
            if not doc:
                return None
            await self.files_collection.delete_one({"_id": ObjectId(file_id)})
            return self._file_helper(doc)
        except Exception:
            return None

    async def toggle_favorite(self, file_id: str, user_id: str) -> Optional[dict]:
        try:
            doc = await self.files_collection.find_one({
                "_id": ObjectId(file_id),
                "user_id": ObjectId(user_id)
            })
            if not doc:
                return None
            new_fav = not doc.get("is_favorite", False)
            await self.files_collection.update_one(
                {"_id": ObjectId(file_id)},
                {"$set": {"is_favorite": new_fav, "updated_at": datetime.now(timezone.utc)}}
            )
            doc["is_favorite"] = new_fav
            return self._file_helper(doc)
        except Exception:
            return None

    async def get_storage_usage(self, user_id: str) -> Dict[str, Any]:
        pipeline = [
            {"$match": {"user_id": ObjectId(user_id)}},
            {
                "$group": {
                    "_id": "$file_type",
                    "total_bytes": {"$sum": "$size_bytes"},
                    "count": {"$sum": 1},
                }
            },
        ]
        results = await self.files_collection.aggregate(pipeline).to_list(length=100)
        by_type: Dict[str, int] = {}
        total_bytes = 0
        total_count = 0
        for r in results:
            ftype = r["_id"] or "other"
            bytes_val = r["total_bytes"]
            by_type[ftype] = bytes_val
            total_bytes += bytes_val
            total_count += r["count"]

        return {
            "total_bytes": total_bytes,
            "files_count": total_count,
            "by_type": by_type,
        }

    # ==================== FOLDERS ====================

    async def create_folder(self, folder_data: Dict[str, Any]) -> dict:
        now = datetime.now(timezone.utc)
        doc = {
            "user_id": ObjectId(folder_data["user_id"]),
            "name": folder_data["name"],
            "subject_id": ObjectId(folder_data["subject_id"]) if folder_data.get("subject_id") else None,
            "parent_id": ObjectId(folder_data["parent_id"]) if folder_data.get("parent_id") else None,
            "color": folder_data.get("color", "#4F46E5"),
            "icon": folder_data.get("icon", "folder"),
            "created_at": now,
            "updated_at": now,
        }
        result = await self.folders_collection.insert_one(doc)
        doc["_id"] = result.inserted_id
        return self._folder_helper(doc, items_count=0)

    async def get_folder_by_id(self, folder_id: str, user_id: str) -> Optional[dict]:
        try:
            doc = await self.folders_collection.find_one({
                "_id": ObjectId(folder_id),
                "user_id": ObjectId(user_id)
            })
            if not doc:
                return None
            items_count = await self.files_collection.count_documents({"folder_id": ObjectId(folder_id)})
            return self._folder_helper(doc, items_count=items_count)
        except Exception:
            return None

    async def get_folders(
        self,
        user_id: str,
        subject_id: Optional[str] = None,
        parent_id: Optional[str] = None,
    ) -> List[dict]:
        query: Dict[str, Any] = {"user_id": ObjectId(user_id)}
        if subject_id:
            try:
                query["subject_id"] = ObjectId(subject_id)
            except Exception:
                return []
        if parent_id is not None:
            if parent_id == "root" or parent_id == "":
                query["parent_id"] = None
            else:
                try:
                    query["parent_id"] = ObjectId(parent_id)
                except Exception:
                    return []

        cursor = self.folders_collection.find(query).sort("name", 1)
        docs = await cursor.to_list(length=100)
        results = []
        for d in docs:
            f_id = d["_id"]
            count = await self.files_collection.count_documents({"folder_id": f_id})
            results.append(self._folder_helper(d, items_count=count))
        return results

    async def delete_folder(self, folder_id: str, user_id: str) -> bool:
        try:
            # Unlink files from this folder (move to root) or delete
            await self.files_collection.update_many(
                {"folder_id": ObjectId(folder_id), "user_id": ObjectId(user_id)},
                {"$set": {"folder_id": None}}
            )
            result = await self.folders_collection.delete_one({
                "_id": ObjectId(folder_id),
                "user_id": ObjectId(user_id)
            })
            return result.deleted_count > 0
        except Exception:
            return False
