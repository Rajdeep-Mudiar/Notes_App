import logging
import os
from pathlib import Path
from typing import Any, Dict, List, Optional
from fastapi import HTTPException, status

from app.repositories.file_repository import FileRepository
from app.repositories.ingestion_repository import IngestionRepository
from app.repositories.note_repository import NoteRepository
from app.schemas.ingestion import (
    DocumentChunkCreate,
    IngestionStatsResponse,
    IngestionStatusEnum,
    IngestionStatusResponse,
    SemanticSearchQuery,
    SemanticSearchResponse,
    SemanticSearchResultItem,
    SourceTypeEnum,
)
from app.services.chunking_service import ChunkingService
from app.services.embedding_service import EmbeddingService
from app.services.text_extractor import TextExtractor

logger = logging.getLogger(__name__)

UPLOAD_DIR = Path(__file__).resolve().parent.parent.parent / "uploads"


class IngestionService:
    """Core orchestration service for document parsing, semantic chunking, vector embedding generation, and RAG retrieval."""

    def __init__(
        self,
        ingestion_repo: IngestionRepository,
        file_repo: FileRepository,
        note_repo: NoteRepository,
        embedding_service: EmbeddingService,
    ):
        self.ingestion_repo = ingestion_repo
        self.file_repo = file_repo
        self.note_repo = note_repo
        self.embedding_service = embedding_service
        self.upload_dir = UPLOAD_DIR

    async def ingest_file(self, user_id: str, file_id: str) -> IngestionStatusResponse:
        """Process and index a stored cloud file into vector chunks."""
        file_record = await self.file_repo.get_file_by_id(file_id, user_id)
        if not file_record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"File not found with ID {file_id}",
            )

        original_name = file_record.get("original_name", "Untitled Document")
        subject_id = file_record.get("subject_id")
        filename = file_record.get("filename")
        mime_type = file_record.get("mime_type")

        # Determine file path on disk
        file_path = self.upload_dir / user_id / filename
        if not os.path.exists(file_path):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Binary file payload missing on disk: {filename}",
            )

        # 1. Update status to PROCESSING
        await self.ingestion_repo.upsert_ingestion_status(
            user_id=user_id,
            source_id=file_id,
            source_type=SourceTypeEnum.FILE.value,
            source_name=original_name,
            status=IngestionStatusEnum.PROCESSING,
            chunks_count=0,
            total_tokens=0,
        )

        try:
            # 2. Extract text sections
            sections = TextExtractor.extract_from_file(
                file_path=str(file_path),
                mime_type=mime_type,
                original_name=original_name,
            )

            # 3. Chunk sections
            raw_chunks = ChunkingService.chunk_sections(sections)

            if not raw_chunks:
                raw_chunks = [{
                    "chunk_index": 0,
                    "page_or_section": "Page 1",
                    "text_content": f"Document: {original_name}",
                    "token_count": 5,
                }]

            # 4. Generate embeddings
            texts = [c["text_content"] for c in raw_chunks]
            embeddings = self.embedding_service.generate_embeddings(texts)

            # 5. Build DocumentChunkCreate models
            chunk_models: List[DocumentChunkCreate] = []
            total_tokens = 0

            for idx, c in enumerate(raw_chunks):
                token_count = c.get("token_count", 0)
                total_tokens += token_count

                chunk_models.append(
                    DocumentChunkCreate(
                        user_id=user_id,
                        subject_id=subject_id,
                        source_type=SourceTypeEnum.FILE,
                        source_id=file_id,
                        source_name=original_name,
                        chunk_index=c["chunk_index"],
                        page_or_section=c.get("page_or_section"),
                        text_content=c["text_content"],
                        token_count=token_count,
                        embedding=embeddings[idx] if idx < len(embeddings) else None,
                        metadata={
                            "mime_type": mime_type,
                            "original_name": original_name,
                        },
                    )
                )

            # 6. Purge existing chunks for this file and save new chunks
            await self.ingestion_repo.delete_chunks_by_source(user_id, file_id)
            saved_count = await self.ingestion_repo.save_chunks(chunk_models)

            # 7. Update status to COMPLETED
            return await self.ingestion_repo.upsert_ingestion_status(
                user_id=user_id,
                source_id=file_id,
                source_type=SourceTypeEnum.FILE.value,
                source_name=original_name,
                status=IngestionStatusEnum.COMPLETED,
                chunks_count=saved_count,
                total_tokens=total_tokens,
            )

        except Exception as e:
            logger.error(f"Error ingesting file {file_id}: {e}", exc_info=True)
            return await self.ingestion_repo.upsert_ingestion_status(
                user_id=user_id,
                source_id=file_id,
                source_type=SourceTypeEnum.FILE.value,
                source_name=original_name,
                status=IngestionStatusEnum.FAILED,
                chunks_count=0,
                total_tokens=0,
                error_message=str(e),
            )

    async def ingest_note(self, user_id: str, note_id: str) -> IngestionStatusResponse:
        """Process and index a Notion-style block note into vector chunks."""
        note_record = await self.note_repo.get_by_id(note_id, user_id)
        if not note_record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Note not found with ID {note_id}",
            )

        title = note_record.get("title", "Untitled Note")
        subject_id = note_record.get("subject_id")
        blocks = note_record.get("blocks", [])

        # 1. Update status to PROCESSING
        await self.ingestion_repo.upsert_ingestion_status(
            user_id=user_id,
            source_id=note_id,
            source_type=SourceTypeEnum.NOTE.value,
            source_name=title,
            status=IngestionStatusEnum.PROCESSING,
            chunks_count=0,
            total_tokens=0,
        )

        try:
            # 2. Extract structured markdown sections from note blocks
            sections = TextExtractor.extract_from_note_blocks(title=title, blocks=blocks)

            # 3. Chunk sections
            raw_chunks = ChunkingService.chunk_sections(sections)

            if not raw_chunks:
                raw_chunks = [{
                    "chunk_index": 0,
                    "page_or_section": f"Note: {title}",
                    "text_content": f"# {title}\n(No content)",
                    "token_count": 5,
                }]

            # 4. Generate embeddings
            texts = [c["text_content"] for c in raw_chunks]
            embeddings = self.embedding_service.generate_embeddings(texts)

            # 5. Build DocumentChunkCreate models
            chunk_models: List[DocumentChunkCreate] = []
            total_tokens = 0

            for idx, c in enumerate(raw_chunks):
                token_count = c.get("token_count", 0)
                total_tokens += token_count

                chunk_models.append(
                    DocumentChunkCreate(
                        user_id=user_id,
                        subject_id=subject_id,
                        source_type=SourceTypeEnum.NOTE,
                        source_id=note_id,
                        source_name=title,
                        chunk_index=c["chunk_index"],
                        page_or_section=c.get("page_or_section"),
                        text_content=c["text_content"],
                        token_count=token_count,
                        embedding=embeddings[idx] if idx < len(embeddings) else None,
                        metadata={
                            "tags": note_record.get("tags", []),
                            "is_pinned": note_record.get("is_pinned", False),
                        },
                    )
                )

            # 6. Purge existing chunks for this note and save new chunks
            await self.ingestion_repo.delete_chunks_by_source(user_id, note_id)
            saved_count = await self.ingestion_repo.save_chunks(chunk_models)

            # 7. Update status to COMPLETED
            return await self.ingestion_repo.upsert_ingestion_status(
                user_id=user_id,
                source_id=note_id,
                source_type=SourceTypeEnum.NOTE.value,
                source_name=title,
                status=IngestionStatusEnum.COMPLETED,
                chunks_count=saved_count,
                total_tokens=total_tokens,
            )

        except Exception as e:
            logger.error(f"Error ingesting note {note_id}: {e}", exc_info=True)
            return await self.ingestion_repo.upsert_ingestion_status(
                user_id=user_id,
                source_id=note_id,
                source_type=SourceTypeEnum.NOTE.value,
                source_name=title,
                status=IngestionStatusEnum.FAILED,
                chunks_count=0,
                total_tokens=0,
                error_message=str(e),
            )

    async def search_similar_chunks(
        self,
        user_id: str,
        search_query: SemanticSearchQuery,
    ) -> SemanticSearchResponse:
        """Perform semantic vector similarity search across indexed document and note chunks."""
        # 1. Generate query vector embedding
        query_vec = self.embedding_service.generate_embedding(search_query.query)

        # 2. Retrieve candidate chunks
        candidate_docs = await self.ingestion_repo.get_candidate_chunks_for_search(
            user_id=user_id,
            subject_id=search_query.subject_id,
            source_id=search_query.source_id,
            source_type=search_query.source_type.value if search_query.source_type else None,
            limit=300,
        )

        scored_results: List[SemanticSearchResultItem] = []

        for doc in candidate_docs:
            chunk_embedding = doc.get("embedding")
            if not chunk_embedding:
                continue

            similarity = EmbeddingService.cosine_similarity(query_vec, chunk_embedding)
            if similarity >= search_query.similarity_threshold:
                scored_results.append(
                    SemanticSearchResultItem(
                        chunk_id=doc["id"],
                        source_id=doc["source_id"],
                        source_type=SourceTypeEnum(doc["source_type"]),
                        source_name=doc.get("source_name", "Untitled Source"),
                        subject_id=doc.get("subject_id"),
                        page_or_section=doc.get("page_or_section"),
                        text_content=doc.get("text_content", ""),
                        similarity_score=round(similarity, 4),
                        metadata=doc.get("metadata", {}),
                    )
                )

        # 3. Sort by similarity descending
        scored_results.sort(key=lambda x: x.similarity_score, reverse=True)
        top_results = scored_results[: search_query.top_k]

        return SemanticSearchResponse(
            query=search_query.query,
            results_count=len(top_results),
            results=top_results,
        )

    async def delete_source(self, user_id: str, source_id: str) -> int:
        """Purge indexed chunks and status for a deleted file or note."""
        return await self.ingestion_repo.delete_chunks_by_source(user_id, source_id)

    async def get_status(self, user_id: str, source_id: str) -> Optional[IngestionStatusResponse]:
        """Fetch indexing status for a source."""
        return await self.ingestion_repo.get_ingestion_status(user_id, source_id)

    async def get_stats(self, user_id: str) -> IngestionStatsResponse:
        """Fetch aggregated student knowledge base stats."""
        return await self.ingestion_repo.get_ingestion_stats(user_id)
