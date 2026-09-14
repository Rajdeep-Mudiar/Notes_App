from fastapi import APIRouter
from app.api.v1 import auth, users, subjects, notes, files, assignments, exams, timetable, analytics, notifications, ingestion, ai, system
from app.core.database import db_manager
from app.schemas.response import ApiResponse

api_router = APIRouter()

api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(subjects.router)
api_router.include_router(notes.router)
api_router.include_router(files.router)
api_router.include_router(assignments.router)
api_router.include_router(exams.router)
api_router.include_router(timetable.router)
api_router.include_router(analytics.router)
api_router.include_router(notifications.router)
api_router.include_router(ingestion.router)
api_router.include_router(ai.router)
api_router.include_router(system.router)



@api_router.get("/health", response_model=ApiResponse[dict], tags=["Health"])
async def health_check():
    """Health check endpoint to verify backend and MongoDB connection."""
    mongo_status = "connected" if db_manager.client is not None else "disconnected"
    try:
        if db_manager.client:
            await db_manager.client.admin.command("ping")
    except Exception as e:
        mongo_status = f"error: {str(e)}"

    return ApiResponse(
        success=True,
        message="Student OS Backend is healthy and operational.",
        data={
            "status": "healthy",
            "mongodb": mongo_status,
            "version": "1.0.0"
        }
    )
