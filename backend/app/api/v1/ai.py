from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.api.deps import get_current_user, get_rag_service, get_ai_repository
from app.repositories.ai_repository import AiRepository
from app.schemas.ai import (
    ChatRequest,
    ChatResponse,
    ConversationListResponse,
    FlashcardGenerateRequest,
    FlashcardGenerateResponse,
    QuizGenerateRequest,
    QuizGenerateResponse,
    SummaryGenerateRequest,
    SummaryGenerateResponse,
)
from app.schemas.user import UserProfileResponse
from app.services.rag_service import RagService

router = APIRouter(prefix="/ai", tags=["AI Study Assistant & RAG Engine"])


@router.post(
    "/chat",
    response_model=ChatResponse,
    status_code=status.HTTP_200_OK,
    summary="Ask AI Study Assistant with grounded course citations",
)
async def grounded_chat(
    req: ChatRequest,
    current_user: UserProfileResponse = Depends(get_current_user),
    rag_service: RagService = Depends(get_rag_service),
):
    """Retrieve semantically relevant course materials and generate a grounded, cited study explanation."""
    user_id = str(current_user.id)
    return await rag_service.chat_grounded(user_id=user_id, req=req)


@router.post(
    "/generate-quiz",
    response_model=QuizGenerateResponse,
    status_code=status.HTTP_200_OK,
    summary="Generate practice multiple choice quiz from course notes and documents",
)
async def generate_quiz(
    req: QuizGenerateRequest,
    current_user: UserProfileResponse = Depends(get_current_user),
    rag_service: RagService = Depends(get_rag_service),
):
    """Auto-generate an interactive practice quiz with 4 options, answer keys, explanations, and source links."""
    user_id = str(current_user.id)
    return await rag_service.generate_quiz(user_id=user_id, req=req)


@router.post(
    "/generate-flashcards",
    response_model=FlashcardGenerateResponse,
    status_code=status.HTTP_200_OK,
    summary="Generate flashcard deck from indexed course materials",
)
async def generate_flashcards(
    req: FlashcardGenerateRequest,
    current_user: UserProfileResponse = Depends(get_current_user),
    rag_service: RagService = Depends(get_rag_service),
):
    """Extract key terms, definitions, and formulas into interactive study flashcards."""
    user_id = str(current_user.id)
    return await rag_service.generate_flashcards(user_id=user_id, req=req)


@router.post(
    "/summarize",
    response_model=SummaryGenerateResponse,
    status_code=status.HTTP_200_OK,
    summary="Generate high-yield exam revision summary cheat sheet",
)
async def generate_summary(
    req: SummaryGenerateRequest,
    current_user: UserProfileResponse = Depends(get_current_user),
    rag_service: RagService = Depends(get_rag_service),
):
    """Compile a comprehensive syllabus overview, core formulas, and exam tips from uploaded study materials."""
    user_id = str(current_user.id)
    return await rag_service.generate_summary(user_id=user_id, req=req)


@router.get(
    "/conversations",
    response_model=ConversationListResponse,
    summary="List past AI study conversations",
)
async def list_conversations(
    limit: int = Query(default=30, ge=1, le=100),
    current_user: UserProfileResponse = Depends(get_current_user),
    ai_repo: AiRepository = Depends(get_ai_repository),
):
    """Retrieve list of historical AI chat sessions with message counts and last previews."""
    user_id = str(current_user.id)
    sessions = await ai_repo.get_user_sessions(user_id=user_id, limit=limit)
    return ConversationListResponse(
        sessions=sessions,
        total=len(sessions),
    )


@router.get(
    "/conversations/{session_id}",
    summary="Get full conversation message history",
)
async def get_conversation(
    session_id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    ai_repo: AiRepository = Depends(get_ai_repository),
):
    """Fetch complete message trajectory and citations for a study session."""
    user_id = str(current_user.id)
    session = await ai_repo.get_session(user_id=user_id, session_id=session_id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Study session {session_id} not found",
        )
    return session


@router.delete(
    "/conversations/{session_id}",
    status_code=status.HTTP_200_OK,
    summary="Delete an AI study session",
)
async def delete_conversation(
    session_id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    ai_repo: AiRepository = Depends(get_ai_repository),
):
    """Permanently delete an AI conversation session."""
    user_id = str(current_user.id)
    deleted = await ai_repo.delete_session(user_id=user_id, session_id=session_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Study session {session_id} not found or already deleted",
        )
    return {"message": f"Session {session_id} deleted successfully."}
