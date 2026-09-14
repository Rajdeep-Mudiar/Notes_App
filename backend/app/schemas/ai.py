from datetime import datetime, timezone
from enum import Enum
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field
from app.schemas.ingestion import SourceTypeEnum


class StudyModeEnum(str, Enum):
    CHAT = "chat"
    QUIZ = "quiz"
    FLASHCARDS = "flashcards"
    SUMMARY = "summary"


class CitationItemModel(BaseModel):
    chunk_id: str
    source_id: str
    source_name: str
    source_type: SourceTypeEnum
    subject_id: Optional[str] = None
    page_or_section: Optional[str] = None
    snippet: str
    similarity_score: float = 0.0


class ChatMessageModel(BaseModel):
    role: str = Field(..., description="'user' or 'assistant'")
    content: str
    citations: List[CitationItemModel] = Field(default_factory=list)
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    subject_id: Optional[str] = None
    session_id: Optional[str] = None
    history: List[ChatMessageModel] = Field(default_factory=list)


class ChatResponse(BaseModel):
    session_id: str
    reply: str
    citations: List[CitationItemModel] = Field(default_factory=list)
    mode: StudyModeEnum = StudyModeEnum.CHAT
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class QuizQuestionModel(BaseModel):
    id: str
    question: str
    options: List[str]
    correct_option_index: int
    explanation: str
    citation: Optional[CitationItemModel] = None


class QuizGenerateRequest(BaseModel):
    subject_id: Optional[str] = None
    num_questions: int = Field(default=5, ge=1, le=20)
    topic: Optional[str] = None


class QuizGenerateResponse(BaseModel):
    title: str
    subject_id: Optional[str] = None
    questions: List[QuizQuestionModel]
    total_questions: int
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class FlashcardItemModel(BaseModel):
    id: str
    front: str
    back: str
    category: str = "General"
    citation: Optional[CitationItemModel] = None


class FlashcardGenerateRequest(BaseModel):
    subject_id: Optional[str] = None
    num_cards: int = Field(default=6, ge=1, le=30)
    topic: Optional[str] = None


class FlashcardGenerateResponse(BaseModel):
    title: str
    subject_id: Optional[str] = None
    cards: List[FlashcardItemModel]
    total_cards: int
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class SummaryGenerateRequest(BaseModel):
    subject_id: Optional[str] = None
    topic: Optional[str] = None
    focus_areas: Optional[List[str]] = None


class SummaryGenerateResponse(BaseModel):
    title: str
    subject_id: Optional[str] = None
    overview: str
    key_concepts: List[str]
    important_formulas_or_takeaways: List[str]
    exam_tips: List[str]
    citations: List[CitationItemModel] = Field(default_factory=list)
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class ConversationSessionModel(BaseModel):
    id: str
    user_id: str
    title: str
    subject_id: Optional[str] = None
    messages_count: int
    last_message_preview: str
    updated_at: datetime


class ConversationListResponse(BaseModel):
    sessions: List[ConversationSessionModel]
    total: int
