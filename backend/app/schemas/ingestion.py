from datetime import datetime, timezone
from enum import Enum
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class SourceTypeEnum(str, Enum):
    FILE = "file"
    NOTE = "note"


class IngestionStatusEnum(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"


class DocumentChunkCreate(BaseModel):
    user_id: str
    subject_id: Optional[str] = None
    source_type: SourceTypeEnum
    source_id: str
    source_name: str
    chunk_index: int
    page_or_section: Optional[str] = None
    text_content: str
    token_count: int
    embedding: Optional[List[float]] = None
    metadata: Dict[str, Any] = Field(default_factory=dict)
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class DocumentChunkResponse(BaseModel):
    id: str
    user_id: str
    subject_id: Optional[str] = None
    source_type: SourceTypeEnum
    source_id: str
    source_name: str
    chunk_index: int
    page_or_section: Optional[str] = None
    text_content: str
    token_count: int
    metadata: Dict[str, Any] = Field(default_factory=dict)
    created_at: datetime


class IngestionStatusResponse(BaseModel):
    source_id: str
    source_type: SourceTypeEnum
    source_name: str
    status: IngestionStatusEnum
    chunks_count: int
    total_tokens: int
    error_message: Optional[str] = None
    updated_at: datetime


class IngestionStatsResponse(BaseModel):
    total_chunks: int
    total_indexed_files: int
    total_indexed_notes: int
    total_tokens_estimated: int
    by_subject: Dict[str, int] = Field(default_factory=dict)
    by_type: Dict[str, int] = Field(default_factory=dict)


class SemanticSearchQuery(BaseModel):
    query: str = Field(..., min_length=1, max_length=1000)
    subject_id: Optional[str] = None
    source_id: Optional[str] = None
    source_type: Optional[SourceTypeEnum] = None
    top_k: int = Field(default=5, ge=1, le=50)
    similarity_threshold: float = Field(default=0.0, ge=0.0, le=1.0)


class SemanticSearchResultItem(BaseModel):
    chunk_id: str
    source_id: str
    source_type: SourceTypeEnum
    source_name: str
    subject_id: Optional[str] = None
    page_or_section: Optional[str] = None
    text_content: str
    similarity_score: float
    metadata: Dict[str, Any] = Field(default_factory=dict)


class SemanticSearchResponse(BaseModel):
    query: str
    results_count: int
    results: List[SemanticSearchResultItem]
