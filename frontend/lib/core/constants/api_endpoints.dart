class ApiEndpoints {
  static const String defaultProductionUrl = 'https://notes-app-f0ae.onrender.com';
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: defaultProductionUrl);
  static String? _dynamicBaseUrl;

  static void setCustomBaseUrl(String? url) {
    _dynamicBaseUrl = url;
  }

  static String get baseUrl {
    if (_dynamicBaseUrl != null && _dynamicBaseUrl!.isNotEmpty) {
      final clean = _dynamicBaseUrl!.trim().replaceAll(RegExp(r'/+$'), '');
      return clean.endsWith('/api/v1') ? clean : '$clean/api/v1';
    }
    if (_envBaseUrl.isNotEmpty) {
      final clean = _envBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
      return clean.endsWith('/api/v1') ? clean : '$clean/api/v1';
    }
    return '$defaultProductionUrl/api/v1';
  }

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String googleAuth = '/auth/google';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  // User endpoints
  static const String userMe = '/users/me';

  // Subjects endpoints
  static const String subjects = '/subjects';
  static const String subjectsSummary = '/subjects/summary';
  static String subjectById(String id) => '/subjects/$id';
  static String subjectArchive(String id) => '/subjects/$id/archive';

  // Notes endpoints
  static const String notes = '/notes';
  static const String notesRecent = '/notes/recent';
  static String noteById(String id) => '/notes/$id';
  static String noteFavorite(String id) => '/notes/$id/favorite';
  static String notePin(String id) => '/notes/$id/pin';

  // Files & Storage endpoints
  static const String files = '/files';
  static const String filesUpload = '/files/upload';
  static const String filesStorage = '/files/storage';
  static const String folders = '/files/folders';
  static String fileById(String id) => '/files/$id';
  static String fileDownload(String id) => '/files/$id/download';
  static String fileFavorite(String id) => '/files/$id/favorite';
  static String folderById(String id) => '/files/folders/$id';

  // Assignments & Planner endpoints
  static const String assignments = '/assignments';
  static const String assignmentsUpcoming = '/assignments/upcoming';
  static const String assignmentsSummary = '/assignments/summary';
  static String assignmentById(String id) => '/assignments/$id';
  static String assignmentStatus(String id) => '/assignments/$id/status';

  // Exams & Calendar endpoints
  static const String exams = '/exams';
  static const String examsUpcoming = '/exams/upcoming';
  static const String examsCalendar = '/exams/calendar';
  static String examById(String id) => '/exams/$id';

  // Timetable & Attendance endpoints
  static const String timetableSlots = '/timetable/slots';
  static const String timetableToday = '/timetable/today';
  static const String timetableWeekly = '/timetable/weekly';
  static String timetableSlotById(String id) => '/timetable/slots/$id';
  static const String attendance = '/timetable/attendance';
  static const String attendanceSummary = '/timetable/attendance/summary';
  static const String attendanceLogs = '/timetable/attendance/logs';
  static String attendanceLogById(String id) => '/timetable/attendance/$id';

  // Analytics & GPA endpoints
  static const String gpaSummary = '/analytics/gpa/summary';
  static const String gpaSemesters = '/analytics/gpa/semesters';
  static String subjectGrade(String id) => '/analytics/subjects/$id/grade';
  static const String gpaWhatIf = '/analytics/gpa/what-if';

  // Notifications & Alerts endpoints
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationsGenerateAlerts = '/notifications/generate-alerts';
  static const String notificationsMarkAllRead = '/notifications/mark-all-read';
  static const String notificationsDeleteRead = '/notifications/read';
  static String notificationRead(String id) => '/notifications/$id/read';
  static String notificationById(String id) => '/notifications/$id';

  // Ingestion & AI Vector Embeddings endpoints
  static const String ingestionStats = '/ingestion/stats';
  static const String ingestionQuery = '/ingestion/query';
  static String ingestFile(String id) => '/ingestion/files/$id/process';
  static String ingestNote(String id) => '/ingestion/notes/$id/process';
  static String ingestionStatus(String sourceId) => '/ingestion/status/$sourceId';
  static String deleteIngestionSource(String sourceId) => '/ingestion/sources/$sourceId';

  // AI Study Assistant & RAG Engine endpoints
  static const String aiChat = '/ai/chat';
  static const String aiGenerateQuiz = '/ai/generate-quiz';
  static const String aiGenerateFlashcards = '/ai/generate-flashcards';
  static const String aiSummarize = '/ai/summarize';
  static const String aiConversations = '/ai/conversations';
  static String aiConversationById(String sessionId) => '/ai/conversations/$sessionId';

  // System
  static const String health = '/health';
}



