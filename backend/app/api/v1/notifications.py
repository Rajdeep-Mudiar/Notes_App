from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.api.deps import get_current_user, get_notification_service
from app.schemas.notification import (
    NotificationCreate,
    NotificationListResponse,
    NotificationResponse,
    UnreadCountResponse,
)
from app.schemas.response import ApiResponse
from app.schemas.user import UserProfileResponse
from app.services.notification_service import NotificationService

router = APIRouter(prefix="/notifications", tags=["Smart Notifications & Alerts"])


@router.get(
    "",
    response_model=ApiResponse[NotificationListResponse],
    summary="Get user notifications with filtering and pagination",
)
async def get_notifications(
    is_read: Optional[bool] = Query(None, description="Filter by read status"),
    type: Optional[str] = Query(None, description="Filter by notification type (assignment_due, exam_upcoming, etc.)"),
    limit: int = Query(50, ge=1, le=100),
    skip: int = Query(0, ge=0),
    current_user: UserProfileResponse = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service),
) -> ApiResponse[NotificationListResponse]:
    result = await service.get_notifications(
        user_id=current_user.id,
        is_read=is_read,
        type=type,
        limit=limit,
        skip=skip,
    )
    return ApiResponse(success=True, message="Notifications retrieved successfully", data=result)


@router.get(
    "/unread-count",
    response_model=ApiResponse[UnreadCountResponse],
    summary="Get count of unread notifications for badge counter",
)
async def get_unread_count(
    current_user: UserProfileResponse = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service),
) -> ApiResponse[UnreadCountResponse]:
    count = await service.get_unread_count(user_id=current_user.id)
    return ApiResponse(
        success=True,
        message="Unread count retrieved",
        data=UnreadCountResponse(unread_count=count),
    )


@router.post(
    "/generate-alerts",
    response_model=ApiResponse[dict],
    summary="Trigger smart background alert scan (deadlines, exams, classes, attendance)",
)
async def generate_smart_alerts(
    current_user: UserProfileResponse = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service),
) -> ApiResponse[dict]:
    created_count = await service.generate_smart_alerts(user_id=current_user.id)
    return ApiResponse(
        success=True,
        message=f"Smart alert scan completed. {created_count} new notification(s) created.",
        data={"new_notifications_count": created_count},
    )


@router.post(
    "",
    response_model=ApiResponse[NotificationResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Create a custom notification",
)
async def create_notification(
    notification_in: NotificationCreate,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service),
) -> ApiResponse[NotificationResponse]:
    created = await service.create_custom_notification(user_id=current_user.id, notification_in=notification_in)
    return ApiResponse(success=True, message="Notification created successfully", data=created)


@router.patch(
    "/{id}/read",
    response_model=ApiResponse[NotificationResponse],
    summary="Mark a specific notification as read",
)
async def mark_as_read(
    id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service),
) -> ApiResponse[NotificationResponse]:
    updated = await service.mark_as_read(notification_id=id, user_id=current_user.id)
    if not updated:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")
    return ApiResponse(success=True, message="Notification marked as read", data=updated)


@router.post(
    "/mark-all-read",
    response_model=ApiResponse[dict],
    summary="Mark all unread notifications as read",
)
async def mark_all_as_read(
    current_user: UserProfileResponse = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service),
) -> ApiResponse[dict]:
    count = await service.mark_all_as_read(user_id=current_user.id)
    return ApiResponse(
        success=True,
        message=f"{count} notification(s) marked as read",
        data={"marked_read_count": count},
    )


@router.delete(
    "/read",
    response_model=ApiResponse[dict],
    summary="Clear/delete all read notifications",
)
async def delete_all_read(
    current_user: UserProfileResponse = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service),
) -> ApiResponse[dict]:
    count = await service.delete_all_read(user_id=current_user.id)
    return ApiResponse(
        success=True,
        message=f"{count} read notification(s) cleared",
        data={"deleted_count": count},
    )


@router.delete(
    "/{id}",
    response_model=ApiResponse[dict],
    summary="Delete a single notification",
)
async def delete_notification(
    id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service),
) -> ApiResponse[dict]:
    deleted = await service.delete_notification(notification_id=id, user_id=current_user.id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")
    return ApiResponse(success=True, message="Notification deleted successfully", data={"deleted": True})
