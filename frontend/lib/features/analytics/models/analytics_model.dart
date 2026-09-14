enum GradingScale {
  scale40('scale_4_0', '4.0 Scale (US/Standard)'),
  scale100('scale_10_0', '10.0 Scale (European/Indian)'),
  percentage('percentage', 'Percentage Scale (0-100%)');

  final String value;
  final String label;
  const GradingScale(this.value, this.label);

  static GradingScale fromString(String val) {
    return GradingScale.values.firstWhere(
      (e) => e.value == val,
      orElse: () => GradingScale.scale40,
    );
  }
}

class SubjectGradeModel {
  final String subjectId;
  final String subjectCode;
  final String subjectName;
  final String subjectColor;
  final int semester;
  final int credits;
  final String? letterGrade;
  final double? numericalGrade;
  final double? gradePoint;
  final String? targetGrade;
  final bool isGraded;

  SubjectGradeModel({
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    required this.subjectColor,
    required this.semester,
    required this.credits,
    this.letterGrade,
    this.numericalGrade,
    this.gradePoint,
    this.targetGrade,
    this.isGraded = false,
  });

  factory SubjectGradeModel.fromJson(Map<String, dynamic> json) {
    return SubjectGradeModel(
      subjectId: json['subject_id'] ?? '',
      subjectCode: json['subject_code'] ?? '',
      subjectName: json['subject_name'] ?? '',
      subjectColor: json['subject_color'] ?? '#3B82F6',
      semester: json['semester'] ?? 1,
      credits: json['credits'] ?? 3,
      letterGrade: json['letter_grade'],
      numericalGrade: json['numerical_grade'] != null
          ? (json['numerical_grade'] as num).toDouble()
          : null,
      gradePoint: json['grade_point'] != null
          ? (json['grade_point'] as num).toDouble()
          : null,
      targetGrade: json['target_grade'],
      isGraded: json['is_graded'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject_id': subjectId,
      'subject_code': subjectCode,
      'subject_name': subjectName,
      'subject_color': subjectColor,
      'semester': semester,
      'credits': credits,
      'letter_grade': letterGrade,
      'numerical_grade': numericalGrade,
      'grade_point': gradePoint,
      'target_grade': targetGrade,
      'is_graded': isGraded,
    };
  }
}

class SemesterGpaModel {
  final int semester;
  final String semesterLabel;
  final int totalCredits;
  final int gradedCredits;
  final double sgpa;
  final List<SubjectGradeModel> subjects;

  SemesterGpaModel({
    required this.semester,
    required this.semesterLabel,
    required this.totalCredits,
    required this.gradedCredits,
    required this.sgpa,
    this.subjects = const [],
  });

  factory SemesterGpaModel.fromJson(Map<String, dynamic> json) {
    return SemesterGpaModel(
      semester: json['semester'] ?? 1,
      semesterLabel: json['semester_label'] ?? 'Semester',
      totalCredits: json['total_credits'] ?? 0,
      gradedCredits: json['graded_credits'] ?? 0,
      sgpa: (json['sgpa'] as num?)?.toDouble() ?? 0.0,
      subjects: (json['subjects'] as List<dynamic>?)
              ?.map((e) => SubjectGradeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'semester': semester,
      'semester_label': semesterLabel,
      'total_credits': totalCredits,
      'graded_credits': gradedCredits,
      'sgpa': sgpa,
      'subjects': subjects.map((e) => e.toJson()).toList(),
    };
  }
}

class GpaSummaryModel {
  final double currentCgpa;
  final double? targetCgpa;
  final String scale;
  final int totalEnrolledCredits;
  final int totalEarnedCredits;
  final int graduationRequiredCredits;
  final double creditsProgressPercentage;
  final String honorsStanding;
  final String academicStatus;
  final List<SemesterGpaModel> semesterBreakdown;
  final int? highestSgpaSemester;
  final int? lowestSgpaSemester;

  GpaSummaryModel({
    required this.currentCgpa,
    this.targetCgpa,
    required this.scale,
    required this.totalEnrolledCredits,
    required this.totalEarnedCredits,
    this.graduationRequiredCredits = 120,
    required this.creditsProgressPercentage,
    required this.honorsStanding,
    required this.academicStatus,
    this.semesterBreakdown = const [],
    this.highestSgpaSemester,
    this.lowestSgpaSemester,
  });

  factory GpaSummaryModel.fromJson(Map<String, dynamic> json) {
    return GpaSummaryModel(
      currentCgpa: (json['current_cgpa'] as num?)?.toDouble() ?? 0.0,
      targetCgpa: (json['target_cgpa'] as num?)?.toDouble(),
      scale: json['scale'] ?? 'scale_4_0',
      totalEnrolledCredits: json['total_enrolled_credits'] ?? 0,
      totalEarnedCredits: json['total_earned_credits'] ?? 0,
      graduationRequiredCredits: json['graduation_required_credits'] ?? 120,
      creditsProgressPercentage: (json['credits_progress_percentage'] as num?)?.toDouble() ?? 0.0,
      honorsStanding: json['honors_standing'] ?? 'Good Standing',
      academicStatus: json['academic_status'] ?? 'Good Standing',
      semesterBreakdown: (json['semester_breakdown'] as List<dynamic>?)
              ?.map((e) => SemesterGpaModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      highestSgpaSemester: json['highest_sgpa_semester'],
      lowestSgpaSemester: json['lowest_sgpa_semester'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_cgpa': currentCgpa,
      'target_cgpa': targetCgpa,
      'scale': scale,
      'total_enrolled_credits': totalEnrolledCredits,
      'total_earned_credits': totalEarnedCredits,
      'graduation_required_credits': graduationRequiredCredits,
      'credits_progress_percentage': creditsProgressPercentage,
      'honors_standing': honorsStanding,
      'academic_status': academicStatus,
      'semester_breakdown': semesterBreakdown.map((e) => e.toJson()).toList(),
      'highest_sgpa_semester': highestSgpaSemester,
      'lowest_sgpa_semester': lowestSgpaSemester,
    };
  }
}

class WhatIfCourseInputModel {
  final String? subjectId;
  final String? courseName;
  final int credits;
  final String hypotheticalGrade;

  WhatIfCourseInputModel({
    this.subjectId,
    this.courseName,
    this.credits = 4,
    required this.hypotheticalGrade,
  });

  factory WhatIfCourseInputModel.fromJson(Map<String, dynamic> json) {
    return WhatIfCourseInputModel(
      subjectId: json['subject_id'],
      courseName: json['course_name'],
      credits: json['credits'] ?? 4,
      hypotheticalGrade: json['hypothetical_grade'] ?? 'A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (subjectId != null) 'subject_id': subjectId,
      if (courseName != null) 'course_name': courseName,
      'credits': credits,
      'hypothetical_grade': hypotheticalGrade,
    };
  }
}

class WhatIfScenarioResponseModel {
  final double baselineCgpa;
  final double projectedCgpa;
  final double cgpaDifference;
  final int totalProjectedCredits;
  final double? targetCgpa;
  final bool? targetAchieved;
  final double? requiredAverageGradePoint;
  final String projectionMessage;

  WhatIfScenarioResponseModel({
    required this.baselineCgpa,
    required this.projectedCgpa,
    required this.cgpaDifference,
    required this.totalProjectedCredits,
    this.targetCgpa,
    this.targetAchieved,
    this.requiredAverageGradePoint,
    required this.projectionMessage,
  });

  factory WhatIfScenarioResponseModel.fromJson(Map<String, dynamic> json) {
    return WhatIfScenarioResponseModel(
      baselineCgpa: (json['baseline_cgpa'] as num?)?.toDouble() ?? 0.0,
      projectedCgpa: (json['projected_cgpa'] as num?)?.toDouble() ?? 0.0,
      cgpaDifference: (json['cgpa_difference'] as num?)?.toDouble() ?? 0.0,
      totalProjectedCredits: json['total_projected_credits'] ?? 0,
      targetCgpa: (json['target_cgpa'] as num?)?.toDouble(),
      targetAchieved: json['target_achieved'],
      requiredAverageGradePoint: (json['required_average_grade_point'] as num?)?.toDouble(),
      projectionMessage: json['projection_message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseline_cgpa': baselineCgpa,
      'projected_cgpa': projectedCgpa,
      'cgpa_difference': cgpaDifference,
      'total_projected_credits': totalProjectedCredits,
      'target_cgpa': targetCgpa,
      'target_achieved': targetAchieved,
      'required_average_grade_point': requiredAverageGradePoint,
      'projection_message': projectionMessage,
    };
  }
}
