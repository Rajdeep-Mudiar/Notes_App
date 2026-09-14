from typing import Dict, Any
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.core.database import get_database
from app.core.security import decode_token
from app.repositories.user_repository import UserRepository
from app.repositories.subject_repository import SubjectRepository
from app.repositories.note_repository import NoteRepository
from app.repositories.file_repository import FileRepository
from app.repositories.assignment_repository import AssignmentRepository
from app.repositories.exam_repository import ExamRepository
from app.repositories.timetable_repository import TimetableRepository
from app.repositories.attendance_repository import AttendanceRepository
from app.repositories.analytics_repository import AnalyticsRepository
from app.repositories.notification_repository import NotificationRepository
from app.repositories.ingestion_repository import IngestionRepository
from app.repositories.ai_repository import AiRepository
from app.services.auth_service import AuthService
from app.services.subject_service import SubjectService
from app.services.note_service import NoteService
from app.services.file_service import FileService
from app.services.assignment_service import AssignmentService
from app.services.exam_service import ExamService
from app.services.timetable_service import TimetableService
from app.services.analytics_service import AnalyticsService
from app.services.notification_service import NotificationService
from app.services.embedding_service import EmbeddingService
from app.services.ingestion_service import IngestionService
from app.services.rag_service import RagService
from app.schemas.user import UserProfileResponse

bearer_scheme = HTTPBearer(auto_error=True)


def get_user_repository(db: AsyncIOMotorDatabase = Depends(get_database)) -> UserRepository:
    return UserRepository(db)


def get_subject_repository(db: AsyncIOMotorDatabase = Depends(get_database)) -> SubjectRepository:
    return SubjectRepository(db)


def get_note_repository(db: AsyncIOMotorDatabase = Depends(get_database)) -> NoteRepository:
    return NoteRepository(db)


def get_file_repository(db: AsyncIOMotorDatabase = Depends(get_database)) -> FileRepository:
    return FileRepository(db)


def get_assignment_repository(db: AsyncIOMotorDatabase = Depends(get_database)) -> AssignmentRepository:
    return AssignmentRepository(db)


def get_exam_repository(db: AsyncIOMotorDatabase = Depends(get_database)) -> ExamRepository:
    return ExamRepository(db)


def get_timetable_repository(db: AsyncIOMotorDatabase = Depends(get_database)) -> TimetableRepository:
    return TimetableRepository(db)


def get_attendance_repository(db: AsyncIOMotorDatabase = Depends(get_database)) -> AttendanceRepository:
    return AttendanceRepository(db)


def get_notification_repository(db: AsyncIOMotorDatabase = Depends(get_database)) -> NotificationRepository:
    return NotificationRepository(db)


def get_auth_service(user_repo: UserRepository = Depends(get_user_repository)) -> AuthService:
    return AuthService(user_repo)


def get_subject_service(
    subject_repo: SubjectRepository = Depends(get_subject_repository),
    user_repo: UserRepository = Depends(get_user_repository)
) -> SubjectService:
    return SubjectService(subject_repo, user_repo)


def get_note_service(
    note_repo: NoteRepository = Depends(get_note_repository),
    subject_repo: SubjectRepository = Depends(get_subject_repository)
) -> NoteService:
    return NoteService(note_repo, subject_repo)


def get_file_service(
    file_repo: FileRepository = Depends(get_file_repository),
    subject_repo: SubjectRepository = Depends(get_subject_repository)
) -> FileService:
    return FileService(file_repo, subject_repo)


def get_assignment_service(
    assignment_repo: AssignmentRepository = Depends(get_assignment_repository),
    subject_repo: SubjectRepository = Depends(get_subject_repository)
) -> AssignmentService:
    return AssignmentService(assignment_repo, subject_repo)


def get_exam_service(
    exam_repo: ExamRepository = Depends(get_exam_repository),
    subject_repo: SubjectRepository = Depends(get_subject_repository)
) -> ExamService:
    return ExamService(exam_repo, subject_repo)


def get_timetable_service(
    timetable_repo: TimetableRepository = Depends(get_timetable_repository),
    attendance_repo: AttendanceRepository = Depends(get_attendance_repository),
) -> TimetableService:
    return TimetableService(timetable_repo, attendance_repo)


def get_analytics_repository(db: AsyncIOMotorDatabase = Depends(get_database)) -> AnalyticsRepository:
    return AnalyticsRepository(db)


def get_analytics_service(
    analytics_repo: AnalyticsRepository = Depends(get_analytics_repository),
) -> AnalyticsService:
    return AnalyticsService(analytics_repo)


def get_notification_service(
    notification_repo: NotificationRepository = Depends(get_notification_repository),
    assignment_repo: AssignmentRepository = Depends(get_assignment_repository),
    exam_repo: ExamRepository = Depends(get_exam_repository),
    timetable_repo: TimetableRepository = Depends(get_timetable_repository),
    attendance_repo: AttendanceRepository = Depends(get_attendance_repository),
) -> NotificationService:
    return NotificationService(
        notification_repo=notification_repo,
        assignment_repo=assignment_repo,
        exam_repo=exam_repo,
        timetable_repo=timetable_repo,
        attendance_repo=attendance_repo,
    )


def get_ingestion_repository(db: AsyncIOMotorDatabase = Depends(get_database)) -> IngestionRepository:
    return IngestionRepository(db)


def get_embedding_service() -> EmbeddingService:
    from app.core.config import settings
    gemini_key = getattr(settings, "GEMINI_API_KEY", None)
    return EmbeddingService(api_key=gemini_key)


def get_ingestion_service(
    ingestion_repo: IngestionRepository = Depends(get_ingestion_repository),
    file_repo: FileRepository = Depends(get_file_repository),
    note_repo: NoteRepository = Depends(get_note_repository),
    embedding_service: EmbeddingService = Depends(get_embedding_service),
) -> IngestionService:
    return IngestionService(
        ingestion_repo=ingestion_repo,
        file_repo=file_repo,
        note_repo=note_repo,
        embedding_service=embedding_service,
    )


def get_ai_repository(db: AsyncIOMotorDatabase = Depends(get_database)) -> AiRepository:
    return AiRepository(db)


def get_rag_service(
    ingestion_service: IngestionService = Depends(get_ingestion_service),
    ai_repo: AiRepository = Depends(get_ai_repository),
) -> RagService:
    from app.core.config import settings
    gemini_key = getattr(settings, "GEMINI_API_KEY", None)
    return RagService(
        ingestion_service=ingestion_service,
        ai_repo=ai_repo,
        gemini_api_key=gemini_key,
    )


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    user_repo: UserRepository = Depends(get_user_repository)
) -> UserProfileResponse:
    token = credentials.credentials
    payload = decode_token(token)
    if not payload or payload.get("type") != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token or token expired.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user_id: str = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user = await user_repo.get_by_id(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User associated with token does not exist.",
        )

    if not user.get("is_active", True):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is inactive.",
        )

    return UserProfileResponse(**user)
