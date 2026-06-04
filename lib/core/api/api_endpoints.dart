class ApiEndpoints {
  // Real device (phone) must use your computer LAN IP, not localhost.
  static const String baseUrl = 'https://api.rspcm.uz/api';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String swaggerAdminToken = '/auth/swagger-admin-token';

  // Student Dashboard
  static const String studentDashboard = '/student-dashboard/me';
  static const String myExams = '/exams/my';
  static const String examPractices = '/exams'; // /{examId}/practices
  static const String examMyParticipation = '/exams'; // /{examId}/participation/me
  static const String examSelectPractice = '/exams'; // /{examId}/practices/{examPracticeId}/select
  static const String examAttemptStart = '/exams'; // /{examId}/attempt/start
  static const String examAttemptMe = '/exams'; // /{examId}/attempt/me
  static const String examQuestionsMe = '/exams'; // /{examId}/questions/me
  static const String examQuestionAnswer = '/exams'; // /{examId}/questions/{examQuestionId}/answer
  static const String examAttemptSubmit = '/exams'; // /{examId}/attempt/submit

  // Profiles
  static const String myProfile = '/profiles/students/me';
  static const String studentProfile = '/profiles/students'; // Append /{userId}

  // Subjects
  static const String subjects = '/subjects';

  // Practices
  static const String practices = '/practices';
  static const String practiceDetail = '/practices'; // Append /{id}
  static const String assignGroups = '/assign-groups'; // Use with practice ID

  // Practice Topics
  static const String practiceTopics = '/topics'; // Base is /api/practices/{id}/topics

  // Practice Teams
  static const String practiceParticipationsMe = '/practice-participations/me';
  static const String practiceParticipationMembersInvite = '/practice-participations'; // /{id}/members/invite
  static const String myTeamInvitations = '/practice-participations/members/invitations/me';
  static const String leaveMyTeam = '/practice-participations'; // /{participationId}/members/me
  static const String availableStudentsForInvite = '/student/practice-participations'; // /{participationId}/members/available
  static const String removeTeamMember = '/student/practice-participations'; // /{participationId}/members/{memberId}

  // Journals
  static const String myJournals = '/practice-journals/me';
  static const String createJournal = '/practice-journals';
  static const String journalsByPractice = '/practice-journals/practice'; // Append /{practiceId}

  // Answers (Homework/Assignments)
  static const String answers = '/answers';
  static const String myAnswers = '/answers/me';
  static const String answerScore = '/score'; // Use with answer ID

  // Practice submissions
  static const String practiceSubmissions = '/practice-submissions'; // /participation/{id}, /participation/{id}/submit

  // Chat
  static const String myChats = '/chats/me';
  static const String chats = '/chats'; // /{chatId}/messages
  static const String directChat = '/chats/direct';

  // Student groups
  static const String studentGroups = '/student/groups'; // GET /api/student/groups, GET /api/student/groups/{id}/members

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationsReadAll = '/notifications/read-all';
  // Mark one: PATCH /notifications/{id}/read

  // FCM Push Notifications
  static const String fcmToken = '/fcm/token';

  // Teacher — profile
  static const String teacherProfileMe = '/profiles/teachers/me';

  // Teacher — own subjects
  static const String teacherOwnSubjects = '/subjects/own';

  // Teacher — groups
  static const String teacherGroups = '/teacher/groups';

  // Teacher — exams  (GET /exams?own=true, POST /exams, PUT /exams/{id}, DELETE /exams/{id}, PATCH /exams/{id}/status)
  static const String teacherExams = '/exams';

  // Teacher — practices  (GET /practices?own=true, POST /practices, PUT /practices/{id}, DELETE /practices/{id})
  static const String teacherPractices = '/practices';

  // Teacher — exam-practices  (GET /exam-practices?examId=..., POST /exam-practices, DELETE /exam-practices/{id})
  static const String examPracticesTeacher = '/exam-practices';

  // Teacher — submissions  (GET /practice-submissions?examId=..., PATCH /{id}/grade, PATCH /{id}/return)
  static const String teacherSubmissions = '/practice-submissions';

  // Teacher — question bank  (GET /questions?own=true, POST /questions, PUT /questions/{id}, DELETE /questions/{id})
  static const String teacherQuestions = '/questions';

  // Admin Dashboard
  static const String adminDashboardStats = '/admin-dashboard/general-stats';
  static const String adminDashboardRecentReports = '/admin-dashboard/recent-reports';
  static const String adminDashboardGroups = '/admin-dashboard/groups';
}
