from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class BlockType(str, Enum):
    PARAGRAPH = "paragraph"
    HEADING_1 = "heading_1"
    HEADING_2 = "heading_2"
    HEADING_3 = "heading_3"
    BULLET_LIST = "bullet_list"
    NUMBERED_LIST = "numbered_list"
    CHECKLIST = "checklist"
    QUOTE = "quote"
    CALLOUT = "callout"
    DIVIDER = "divider"
    CODE = "code"
    TABLE = "table"
    EQUATION = "equation"
    IMAGE = "image"
    FILE = "file"


class NoteBlock(BaseModel):
    id: str = Field(..., description="Unique ID for block")
    type: BlockType = Field(default=BlockType.PARAGRAPH, description="Type of note block")
    content: str = Field(default="", description="Text or raw payload of block")
    properties: Dict[str, Any] = Field(
        default_factory=dict,
        description="Block-specific metadata, e.g. checked state, code language, callout icon, table rows"
    )
    order: int = Field(default=0, description="Sequential display order")


class NoteBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=250, description="Note title")
    subject_id: Optional[str] = Field(default=None, description="Linked subject ObjectId")
    tags: List[str] = Field(default_factory=list, description="Categorization tags, e.g. #trees, #exam")
    cover_image: Optional[str] = Field(default=None, description="Optional banner image URL")
    icon: Optional[str] = Field(default="article", description="Note icon identifier")
    blocks: List[NoteBlock] = Field(default_factory=list, description="Ordered blocks making up the note body")
    is_favorite: bool = Field(default=False)
    is_pinned: bool = Field(default=False)


class NoteCreate(NoteBase):
    pass


class NoteUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=250)
    subject_id: Optional[str] = None
    tags: Optional[List[str]] = None
    cover_image: Optional[str] = None
    icon: Optional[str] = None
    blocks: Optional[List[NoteBlock]] = None
    is_favorite: Optional[bool] = None
    is_pinned: Optional[bool] = None
    is_archived: Optional[bool] = None


class NoteResponse(NoteBase):
    id: str
    user_id: str
    is_archived: bool = False
    subject_name: Optional[str] = None
    subject_code: Optional[str] = None
    subject_color: Optional[str] = None
    preview_snippet: str = ""
    created_at: datetime
    updated_at: datetime


class NoteSummaryResponse(BaseModel):
    id: str
    user_id: str
    title: str
    subject_id: Optional[str] = None
    subject_name: Optional[str] = None
    subject_code: Optional[str] = None
    subject_color: Optional[str] = None
    tags: List[str] = []
    icon: str = "article"
    preview_snippet: str = ""
    blocks_count: int = 0
    is_favorite: bool = False
    is_pinned: bool = False
    is_archived: bool = False
    created_at: datetime
    updated_at: datetime


class NoteListResponse(BaseModel):
    notes: List[NoteSummaryResponse]
    total_count: int
    subject_id: Optional[str] = None
    tag: Optional[str] = None
