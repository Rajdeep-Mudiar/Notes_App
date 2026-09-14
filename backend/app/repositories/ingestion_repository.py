from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.schemas.ingestion import (
    DocumentChunkCreate,
    DocumentChunkResponse,
    IngestionStatsResponse,
    IngestionStatusEnum,
    IngestionStatusResponse,
    SourceTypeEnum,
)


class IngestionRepository:
    """MongoDB repository for storing and querying document chunks, vector embeddings, and ingestion statuses."""

    def __init__(self, db: AsyncIOMotorDatabase):
        self.db = db
        self.chunks_collection = db["document_chunks"]
        self.status_collection = db["ingestion_status"]

    async def save_chunks(self, chunks: List[DocumentChunkCreate]) -> int:
        """Batch insert document chunks."""
        if not chunks:
            return 0

        docs = [c.model_dump() for c in chunks]
        res = await self.chunks_collection.insert_many(docs)
        return len(res.inserted_ids)

    async def delete_chunks_by_source(self, user_id: str, source_id: str) -> int:
        """Delete all chunks belonging to a file or note source."""
        res = await self.chunks_collection.delete_many({
            "user_id": user_id,
            "source_id": source_id,
        })
        # Also clean up ingestion status record
        await self.status_collection.delete_one({
            "user_id": user_id,
            "source_id": source_id,
        })
        return res.deleted_count

    async def get_chunks_by_source(self, user_id: str, source_id: str) -> List[DocumentChunkResponse]:
        """Fetch all chunks for a source."""
        cursor = self.chunks_collection.find({
            "user_id": user_id,
            "source_id": source_id,
        }).sort("chunk_index", 1)

        chunks: List[DocumentChunkResponse] = []
        async for doc in cursor:
            doc["id"] = str(doc.pop("_id"))
            chunks.append(DocumentChunkResponse(**doc))
        return chunks

    async def get_candidate_chunks_for_search(
        self,
        user_id: str,
        subject_id: Optional[str] = None,
        source_id: Optional[str] = None,
        source_type: Optional[str] = None,
        limit: int = 300,
    ) -> List[Dict[str, Any]]:
        """Retrieve candidate chunk documents containing vector embeddings for similarity matching."""
        query: Dict[str, Any] = {"user_id": user_id}

        if subject_id:
            query["subject_id"] = subject_id
        if source_id:
            query["source_id"] = source_id
        if source_type:
            query["source_type"] = source_type

        cursor = self.chunks_collection.find(query).limit(limit)
        results: List[Dict[str, Any]] = []
        async for doc in cursor:
            doc["id"] = str(doc.pop("_id"))
            results.append(doc)
        return results

    async def upsert_ingestion_status(
        self,
        user_id: str,
        source_id: str,
        source_type: str,
        source_name: str,
        status: IngestionStatusEnum,
        chunks_count: int,
        total_tokens: int,
        error_message: Optional[str] = None,
    ) -> IngestionStatusResponse:
        """Insert or update ingestion status for a file or note."""
        now = datetime.now(timezone.utc)
        update_data = {
            "user_id": user_id,
            "source_id": source_id,
            "source_type": source_type,
            "source_name": source_name,
            "status": status.value,
            "chunks_count": chunks_count,
            "total_tokens": total_tokens,
            "error_message": error_message,
            "updated_at": now,
        }

        await self.status_collection.update_one(
            {"user_id": user_id, "source_id": source_id},
            {"$set": update_data},
            upsert=True,
        )

        return IngestionStatusResponse(
            source_id=source_id,
            source_type=SourceTypeEnum(source_type),
            source_name=source_name,
            status=status,
            chunks_count=chunks_count,
            total_tokens=total_tokens,
            error_message=error_message,
            updated_at=now,
        )

    async def get_ingestion_status(self, user_id: str, source_id: str) -> Optional[IngestionStatusResponse]:
        """Fetch current ingestion status for a source."""
        doc = await self.status_collection.find_one({
            "user_id": user_id,
            "source_id": source_id,
        })
        if not doc:
            return None

        return IngestionStatusResponse(
            source_id=doc["source_id"],
            source_type=SourceTypeEnum(doc["source_type"]),
            source_name=doc.get("source_name", "Unknown Source"),
            status=IngestionStatusEnum(doc["status"]),
            chunks_count=doc.get("chunks_count", 0),
            total_tokens=doc.get("total_tokens", 0),
            error_message=doc.get("error_message"),
            updated_at=doc.get("updated_at", datetime.now(timezone.utc)),
        )

    async def get_ingestion_stats(self, user_id: str) -> IngestionStatsResponse:
        """Aggregate total indexed knowledge stats for the student."""
        # 1. Total chunks count & token estimates
        pipeline = [
            {"$match": {"user_id": user_id}},
            {
                "$group": {
                    "_id": None,
                    "total_chunks": {"$sum": 1},
                    "total_tokens": {"$sum": "$token_count"},
                }
            }
        ]
        agg_res = await self.chunks_collection.aggregate(pipeline).to_list(1)
        total_chunks = agg_res[0]["total_chunks"] if agg_res else 0
        total_tokens = agg_res[0]["total_tokens"] if agg_res else 0

        # 2. Distinct indexed files and notes count
        indexed_files = await self.chunks_collection.distinct("source_id", {"user_id": user_id, "source_type": "file"})
        indexed_notes = await self.chunks_collection.distinct("source_id", {"user_id": user_id, "source_type": "note"})

        # 3. Breakdown by subject
        subject_pipeline = [
            {"$match": {"user_id": user_id, "subject_id": {"$ne": None}}},
            {"$group": {"_id": "$subject_id", "count": {"$sum": 1}}}
        ]
        sub_agg = await self.chunks_collection.aggregate(subject_pipeline).to_list(100)
        by_subject = {item["_id"]: item["count"] for item in sub_agg if item["_id"]}

        # 4. Breakdown by source type
        type_pipeline = [
            {"$match": {"user_id": user_id}},
            {"$group": {"_id": "$source_type", "count": {"$sum": 1}}}
        ]
        type_agg = await self.chunks_collection.aggregate(type_pipeline).to_list(10)
        by_type = {item["_id"]: item["count"] for item in type_agg if item["_id"]}

        return IngestionStatsResponse(
            total_chunks=total_chunks,
            total_indexed_files=len(indexed_files),
            total_indexed_notes=len(indexed_notes),
            total_tokens_estimated=total_tokens,
            by_subject=by_subject,
            by_type=by_type,
        )
