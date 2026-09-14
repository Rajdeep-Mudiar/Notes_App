from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status

from app.api.deps import get_current_user, get_analytics_service
from app.schemas.analytics import (
    CGPASummaryResponse,
    GradingScaleEnum,
    SemesterGPAResponse,
    SubjectGradeInput,
    SubjectGradeResponse,
    WhatIfScenarioRequest,
    WhatIfScenarioResponse,
)
from app.schemas.response import ApiResponse
from app.schemas.user import UserProfileResponse
from app.services.analytics_service import AnalyticsService

router = APIRouter(prefix="/analytics", tags=["Academic Performance & GPA Analytics"])


@router.get(
    "/gpa/summary",
    response_model=ApiResponse[CGPASummaryResponse],
    summary="Get comprehensive CGPA, degree graduation progress, and honors standing",
)
async def get_gpa_summary(
    scale: GradingScaleEnum = Query(GradingScaleEnum.SCALE_4_0, description="Grading scale (scale_4_0, scale_10_0, percentage)"),
    graduation_required_credits: int = Query(120, description="Total degree credit requirement (e.g. 120, 160)"),
    current_user: UserProfileResponse = Depends(get_current_user),
    service: AnalyticsService = Depends(get_analytics_service),
) -> ApiResponse[CGPASummaryResponse]:
    summary = await service.get_gpa_summary(
        user_id=current_user.id,
        scale=scale,
        graduation_required_credits=graduation_required_credits,
    )
    return ApiResponse(success=True, message="GPA summary retrieved successfully", data=summary)


@router.get(
    "/gpa/semesters",
    response_model=ApiResponse[List[SemesterGPAResponse]],
    summary="Get semester-by-semester GPA (SGPA) breakdown and course grades",
)
async def get_semester_gpa(
    scale: GradingScaleEnum = Query(GradingScaleEnum.SCALE_4_0),
    current_user: UserProfileResponse = Depends(get_current_user),
    service: AnalyticsService = Depends(get_analytics_service),
) -> ApiResponse[List[SemesterGPAResponse]]:
    summary = await service.get_gpa_summary(user_id=current_user.id, scale=scale)
    return ApiResponse(success=True, message="Semester GPA breakdown retrieved", data=summary.semester_breakdown)


@router.put(
    "/subjects/{id}/grade",
    response_model=ApiResponse[SubjectGradeResponse],
    summary="Record or update the received/target grade for a specific subject",
)
async def update_subject_grade(
    id: str,
    grade_in: SubjectGradeInput,
    scale: GradingScaleEnum = Query(GradingScaleEnum.SCALE_4_0),
    current_user: UserProfileResponse = Depends(get_current_user),
    service: AnalyticsService = Depends(get_analytics_service),
) -> ApiResponse[SubjectGradeResponse]:
    updated = await service.update_subject_grade(
        subject_id=id,
        user_id=current_user.id,
        grade_in=grade_in,
        scale=scale,
    )
    return ApiResponse(success=True, message="Subject grade updated successfully", data=updated)


@router.post(
    "/gpa/what-if",
    response_model=ApiResponse[WhatIfScenarioResponse],
    summary="Simulate 'What-If' future grade scenarios and project future CGPA",
)
async def calculate_what_if(
    request: WhatIfScenarioRequest,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: AnalyticsService = Depends(get_analytics_service),
) -> ApiResponse[WhatIfScenarioResponse]:
    result = await service.calculate_what_if(user_id=current_user.id, request=request)
    return ApiResponse(success=True, message="What-If scenario projection calculated", data=result)
