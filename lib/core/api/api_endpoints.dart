class ApiEndpoints {
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

  // Profiles
  static const String myProfile = '/profiles/students/me';
  static const String studentProfile = '/profiles/students'; // Append /{userId}

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

  // Journals
  static const String myJournals = '/practice-journals/me';
  static const String createJournal = '/practice-journals';
  static const String journalsByPractice = '/practice-journals/practice'; // Append /{practiceId}

  // Answers (Homework/Assignments)
  static const String answers = '/answers';
  static const String myAnswers = '/answers/me';
  static const String answerScore = '/score'; // Use with answer ID
}
