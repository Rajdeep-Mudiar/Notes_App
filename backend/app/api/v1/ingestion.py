from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.api.deps import get_current_user, get_ingestion_service
from app.schemas.user import UserProfileResponse
from app.schemas.ingestion import (
    IngestionStatsResponse,
    IngestionStatusResponse,
    SemanticSearchQuery,
    SemanticSearchResponse,
)
from app.services.ingestion_service import IngestionService

router = APIRouter(prefix="/ingestion", tags=["Document Ingestion & Embeddings"])


@router.post(
    "/files/{file_id}/process",
    response_model=IngestionStatusResponse,
    status_code=status.HTTP_200_OK,
    summary="Process and vectorize a cloud file",
)
async def process_file(
    file_id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    ingestion_service: IngestionService = Depends(get_ingestion_service),
):
    """Extract text, create chunks, generate embeddings, and index a stored cloud document for AI/RAG."""
    user_id = str(current_user.id)
    return await ingestion_service.ingest_file(user_id=user_id, file_id=file_id)


@router.post(
    "/notes/{note_id}/process",
    response_model=IngestionStatusResponse,
    status_code=status.HTTP_200_OK,
    summary="Process and vectorize a Notion-style block note",
)
async def process_note(
    note_id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    ingestion_service: IngestionService = Depends(get_ingestion_service),
):
    """Extract structured blocks, chunk text, generate dense embeddings, and index a note for AI/RAG."""
    user_id = str(current_user.id)
    return await ingestion_service.ingest_note(user_id=user_id, note_id=note_id)


@router.get(
    "/status/{source_id}",
    response_model=IngestionStatusResponse,
    summary="Get ingestion status for a file or note",
)
async def get_ingestion_status(
    source_id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    ingestion_service: IngestionService = Depends(get_ingestion_service),
):
    """Retrieve indexing state, chunk count, and total token count for a specific file or note."""
    user_id = str(current_user.id)
    status_res = await ingestion_service.get_status(user_id=user_id, source_id=source_id)
    if not status_res:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No ingestion status found for source {source_id}",
        )
    return status_res


@router.get(
    "/stats",
    response_model=IngestionStatsResponse,
    summary="Get aggregated student knowledge base indexing stats",
)
async def get_ingestion_stats(
    current_user: UserProfileResponse = Depends(get_current_user),
    ingestion_service: IngestionService = Depends(get_ingestion_service),
):
    """Return total indexed chunks, indexed files count, indexed notes count, tokens, and subject breakdown."""
    user_id = str(current_user.id)
    return await ingestion_service.get_stats(user_id=user_id)


@router.delete(
    "/sources/{source_id}",
    status_code=status.HTTP_200_OK,
    summary="Purge indexed chunks for a deleted file or note",
)
async def delete_source_index(
    source_id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    ingestion_service: IngestionService = Depends(get_ingestion_service),
):
    """Delete all vector embeddings and chunk records associated with a source."""
    user_id = str(current_user.id)
    deleted_count = await ingestion_service.delete_source(user_id=user_id, source_id=source_id)
    return {
        "message": f"Successfully deleted {deleted_count} chunk(s) for source {source_id}",
        "deleted_count": deleted_count,
    }


@router.post(
    "/query",
    response_model=SemanticSearchResponse,
    summary="Perform vector semantic similarity search across knowledge base chunks",
)
async def semantic_search(
    query_body: SemanticSearchQuery,
    current_user: UserProfileResponse = Depends(get_current_user),
    ingestion_service: IngestionService = Depends(get_ingestion_service),
):
    """Generate dense embedding for query and retrieve top-k semantically relevant chunks."""
    user_id = str(current_user.id)
    return await ingestion_service.search_similar_chunks(user_id=user_id, search_query=query_body)

