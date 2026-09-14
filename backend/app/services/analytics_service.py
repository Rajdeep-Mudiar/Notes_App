from typing import Any, Dict, List, Optional
from fastapi import HTTPException, status

from app.repositories.analytics_repository import AnalyticsRepository
from app.schemas.analytics import (
    CGPASummaryResponse,
    GradingScaleEnum,
    SemesterGPAResponse,
    SubjectGradeInput,
    SubjectGradeResponse,
    WhatIfScenarioRequest,
    WhatIfScenarioResponse,
)


class AnalyticsService:
    GRADE_MAP_4_0 = {
        "A+": 4.0,
        "A": 4.0,
        "A-": 3.7,
        "B+": 3.3,
        "B": 3.0,
        "B-": 2.7,
        "C+": 2.3,
        "C": 2.0,
        "C-": 1.7,
        "D+": 1.3,
        "D": 1.0,
        "F": 0.0,
    }

    GRADE_MAP_10_0 = {
        "O": 10.0,
        "A+": 10.0,
        "A": 9.0,
        "A-": 8.5,
        "B+": 8.0,
        "B": 7.0,
        "B-": 6.5,
        "C+": 6.0,
        "C": 5.5,
        "P": 5.0,
        "F": 0.0,
    }

    def __init__(self, analytics_repo: AnalyticsRepository):
        self.analytics_repo = analytics_repo

    def _convert_to_grade_point(
        self,
        letter_grade: Optional[str],
        numerical_grade: Optional[float],
        scale: GradingScaleEnum = GradingScaleEnum.SCALE_4_0,
    ) -> Optional[float]:
        # 1. Letter grade lookup
        if letter_grade:
            clean_letter = letter_grade.strip().upper()
            if scale == GradingScaleEnum.SCALE_10_0:
                if clean_letter in self.GRADE_MAP_10_0:
                    return self.GRADE_MAP_10_0[clean_letter]
            else:
                if clean_letter in self.GRADE_MAP_4_0:
                    return self.GRADE_MAP_4_0[clean_letter]
            try:
                val = float(clean_letter)
                max_val = 10.0 if scale == GradingScaleEnum.SCALE_10_0 else 4.0
                return min(max(0.0, val), max_val)
            except ValueError:
                pass

        # 2. Percentage lookup
        if numerical_grade is not None:
            pct = max(0.0, min(100.0, numerical_grade))
            if scale == GradingScaleEnum.SCALE_10_0:
                return round(pct / 10.0, 2)
            else:
                if pct >= 93.0:
                    return 4.0
                elif pct >= 90.0:
                    return 3.7
                elif pct >= 87.0:
                    return 3.3
                elif pct >= 83.0:
                    return 3.0
                elif pct >= 80.0:
                    return 2.7
                elif pct >= 77.0:
                    return 2.3
                elif pct >= 73.0:
                    return 2.0
                elif pct >= 70.0:
                    return 1.7
                elif pct >= 65.0:
                    return 1.3
                elif pct >= 60.0:
                    return 1.0
                else:
                    return 0.0

        return None

    def _get_honors_standing(self, cgpa: float, scale: GradingScaleEnum) -> str:
        if scale == GradingScaleEnum.SCALE_10_0:
            if cgpa >= 9.0:
                return "First Class with Distinction"
            elif cgpa >= 8.0:
                return "First Class with Honors"
            elif cgpa >= 6.5:
                return "First Class"
            elif cgpa >= 5.0:
                return "Second Class"
            else:
                return "Academic Warning"
        else:
            if cgpa >= 3.90:
                return "Summa Cum Laude (Highest Honors)"
            elif cgpa >= 3.75:
                return "Magna Cum Laude (High Honors)"
            elif cgpa >= 3.50:
                return "Cum Laude (Dean's Honors)"
            elif cgpa >= 3.00:
                return "Good Academic Standing"
            elif cgpa >= 2.00:
                return "Satisfactory Standing"
            else:
                return "Academic Probation / Warning"

    async def update_subject_grade(
        self,
        subject_id: str,
        user_id: str,
        grade_in: SubjectGradeInput,
        scale: GradingScaleEnum = GradingScaleEnum.SCALE_4_0,
    ) -> SubjectGradeResponse:
        subject = await self.analytics_repo.get_subject_by_id(subject_id, user_id)
        if not subject:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Subject not found.",
            )

        grade_point = self._convert_to_grade_point(
            letter_grade=grade_in.letter_grade,
            numerical_grade=grade_in.numerical_grade,
            scale=scale,
        )

        updated = await self.analytics_repo.update_subject_grade(
            subject_id=subject_id,
            user_id=user_id,
            letter_grade=grade_in.letter_grade.strip().upper() if grade_in.letter_grade else None,
            numerical_grade=grade_in.numerical_grade,
            grade_point=grade_point,
            target_grade=grade_in.target_grade.strip().upper() if grade_in.target_grade else None,
        )

        return SubjectGradeResponse(
            subject_id=str(updated["_id"]),
            subject_code=updated.get("code", ""),
            subject_name=updated.get("name", ""),
            subject_color=updated.get("color", "#4F46E5"),
            semester=updated.get("semester", 1),
            credits=updated.get("credits", 4),
            letter_grade=updated.get("letter_grade"),
            numerical_grade=updated.get("numerical_grade"),
            grade_point=updated.get("grade_point"),
            target_grade=updated.get("target_grade"),
            is_graded=updated.get("grade_point") is not None,
        )

    async def get_gpa_summary(
        self,
        user_id: str,
        scale: GradingScaleEnum = GradingScaleEnum.SCALE_4_0,
        graduation_required_credits: int = 120,
    ) -> CGPASummaryResponse:
        subjects = await self.analytics_repo.get_user_subjects(user_id)

        # Group subjects by semester
        semester_groups: Dict[int, List[dict]] = {}
        total_enrolled_credits = 0
        total_earned_credits = 0
        total_quality_points = 0.0
        total_graded_credits = 0

        for sub in subjects:
            sem = sub.get("semester", 1)
            semester_groups.setdefault(sem, []).append(sub)
            creds = sub.get("credits", 4)
            total_enrolled_credits += creds

        semester_responses: List[SemesterGPAResponse] = []
        highest_sgpa: Optional[float] = None
        highest_sem: Optional[int] = None
        lowest_sgpa: Optional[float] = None
        lowest_sem: Optional[int] = None

        for sem in sorted(semester_groups.keys()):
            sem_subjects = semester_groups[sem]
            sem_total_credits = 0
            sem_graded_credits = 0
            sem_quality_points = 0.0
            sub_responses: List[SubjectGradeResponse] = []

            for s in sem_subjects:
                creds = s.get("credits", 4)
                sem_total_credits += creds

                # Check / convert grade point
                gp = s.get("grade_point")
                if gp is None:
                    gp = self._convert_to_grade_point(
                        letter_grade=s.get("letter_grade"),
                        numerical_grade=s.get("numerical_grade"),
                        scale=scale,
                    )

                is_graded = gp is not None
                if is_graded:
                    sem_graded_credits += creds
                    sem_quality_points += (creds * gp)
                    total_earned_credits += creds
                    total_graded_credits += creds
                    total_quality_points += (creds * gp)

                sub_responses.append(
                    SubjectGradeResponse(
                        subject_id=str(s["_id"]),
                        subject_code=s.get("code", ""),
                        subject_name=s.get("name", ""),
                        subject_color=s.get("color", "#4F46E5"),
                        semester=sem,
                        credits=creds,
                        letter_grade=s.get("letter_grade"),
                        numerical_grade=s.get("numerical_grade"),
                        grade_point=gp,
                        target_grade=s.get("target_grade"),
                        is_graded=is_graded,
                    )
                )

            sgpa = round(sem_quality_points / sem_graded_credits, 2) if sem_graded_credits > 0 else 0.0

            if sem_graded_credits > 0:
                if highest_sgpa is None or sgpa > highest_sgpa:
                    highest_sgpa = sgpa
                    highest_sem = sem
                if lowest_sgpa is None or sgpa < lowest_sgpa:
                    lowest_sgpa = sgpa
                    lowest_sem = sem

            semester_responses.append(
                SemesterGPAResponse(
                    semester=sem,
                    semester_label=f"Semester {sem}",
                    total_credits=sem_total_credits,
                    graded_credits=sem_graded_credits,
                    sgpa=sgpa,
                    subjects=sub_responses,
                )
            )

        current_cgpa = round(total_quality_points / total_graded_credits, 2) if total_graded_credits > 0 else 0.0
        progress_pct = min(100.0, round((total_earned_credits / graduation_required_credits) * 100.0, 1))
        honors = self._get_honors_standing(current_cgpa, scale)
        academic_status = "Good Standing" if current_cgpa >= (2.0 if scale != GradingScaleEnum.SCALE_10_0 else 5.0) else "Academic Warning"

        return CGPASummaryResponse(
            current_cgpa=current_cgpa,
            scale=scale,
            total_enrolled_credits=total_enrolled_credits,
            total_earned_credits=total_earned_credits,
            graduation_required_credits=graduation_required_credits,
            credits_progress_percentage=progress_pct,
            honors_standing=honors,
            academic_status=academic_status,
            semester_breakdown=semester_responses,
            highest_sgpa_semester=highest_sem,
            lowest_sgpa_semester=lowest_sem,
        )

    async def calculate_what_if(
        self,
        user_id: str,
        request: WhatIfScenarioRequest,
    ) -> WhatIfScenarioResponse:
        scale = request.scale
        summary = await self.get_gpa_summary(user_id, scale=scale)

        baseline_cgpa = summary.current_cgpa
        baseline_credits = summary.total_earned_credits
        baseline_points = baseline_cgpa * baseline_credits

        hypo_credits = 0
        hypo_points = 0.0

        for course in request.courses:
            gp = self._convert_to_grade_point(
                letter_grade=course.hypothetical_grade,
                numerical_grade=None,
                scale=scale,
            ) or 0.0
            hypo_credits += course.credits
            hypo_points += (course.credits * gp)

        total_projected_credits = baseline_credits + hypo_credits
        projected_cgpa = (
            round((baseline_points + hypo_points) / total_projected_credits, 2)
            if total_projected_credits > 0
            else 0.0
        )
        diff = round(projected_cgpa - baseline_cgpa, 2)

        target_achieved = None
        req_avg_gp = None

        if request.target_cgpa is not None:
            target_achieved = projected_cgpa >= request.target_cgpa
            if hypo_credits > 0:
                # Needed points: target * total_credits - baseline_points
                needed_total_pts = request.target_cgpa * total_projected_credits - baseline_points
                req_avg_gp = round(needed_total_pts / hypo_credits, 2)

        if diff > 0:
            msg = f"Projected CGPA will increase by +{diff:.2f} to {projected_cgpa:.2f} across {hypo_credits} additional credits."
        elif diff < 0:
            msg = f"Projected CGPA will decrease by {diff:.2f} to {projected_cgpa:.2f} across {hypo_credits} additional credits."
        else:
            msg = f"Projected CGPA remains stable at {projected_cgpa:.2f}."

        return WhatIfScenarioResponse(
            baseline_cgpa=baseline_cgpa,
            projected_cgpa=projected_cgpa,
            cgpa_difference=diff,
            total_projected_credits=total_projected_credits,
            target_cgpa=request.target_cgpa,
            target_achieved=target_achieved,
            required_average_grade_point=req_avg_gp,
            projection_message=msg,
        )
