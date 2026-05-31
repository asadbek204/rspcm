import 'dart:convert';
import '../models/models.dart';
import '../models/auth_models.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

class ApiService {
  final ApiClient _apiClient = ApiClient();

  bool _isNotFoundError(Object e) => e.toString().contains('Server Error (404)');

  // Auth Methods
  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _apiClient.post(ApiEndpoints.login, request.toJson());
    return AuthResponse.fromJson(jsonDecode(response.body));
  }

  Future<void> register(RegisterRequest request) async {
    await _apiClient.post(ApiEndpoints.register, request.toJson());
  }

  Future<bool> verifyOtp(VerifyOtpRequest request) async {
    try {
      await _apiClient.post(ApiEndpoints.verifyOtp, request.toJson());
      return true;
    } catch (e) {
      print('API Error (Verify OTP): $e');
      return false;
    }
  }

  Future<bool> resendOtp(ResendOtpRequest request) async {
    try {
      await _apiClient.post(ApiEndpoints.resendOtp, request.toJson());
      return true;
    } catch (e) {
      print('API Error (Resend OTP): $e');
      return false;
    }
  }

  // Dashboard
  Future<StudentDashboardResponse?> getStudentDashboard() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.studentDashboard);
      return StudentDashboardResponse.fromJson(json.decode(response.body));
    } catch (e) {
      print('API Error (Dashboard): $e');
      return null;
    }
  }

  // Profile
  Future<StudentProfileResponse?> getMyProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.myProfile);
      return StudentProfileResponse.fromJson(json.decode(response.body));
    } catch (e) {
      print('API Error (Profile): $e');
      return null;
    }
  }

  Future<StudentProfileResponse?> updateMyProfile({int? course}) async {
    try {
      final response = await _apiClient.put(ApiEndpoints.myProfile, {
        'course': course,
      });
      return StudentProfileResponse.fromJson(json.decode(response.body));
    } catch (e) {
      print('API Error (Update Profile): $e');
      return null;
    }
  }

  // Practices
  Future<List<Practice>> getPractices() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.practiceParticipationsMe);
      final List data = json.decode(response.body);
      return data
          .map((p) => Practice.fromJson((p as Map<String, dynamic>)['practice'] ?? {}))
          .toList();
    } catch (e) {
      print('API Error (Practices): $e');
      return [];
    }
  }

  Future<Practice?> getPracticeDetail(int id) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.practiceDetail}/$id');
      return Practice.fromJson(json.decode(response.body));
    } catch (e) {
      print('API Error (Practice Detail): $e');
      return null;
    }
  }

  // Practice Teams
  Future<PracticeTeamResponse?> getTeamByPractice(int practiceId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.practiceParticipationsMe);
      final List data = json.decode(response.body);
      final matched = data.cast<Map<String, dynamic>>().firstWhere(
        (item) => ((item['practice'] ?? {})['id'] ?? 0) == practiceId,
        orElse: () => <String, dynamic>{},
      );
      if (matched.isNotEmpty) {
        final members = (matched['members'] as List? ?? [])
            .map((m) => (m['user'] ?? {}) as Map<String, dynamic>)
            .toList();
        return PracticeTeamResponse.fromJson({
          'id': matched['participationId'] ?? 0,
          'name': 'Team',
          'members': members,
        });
      }
      return null;
    } catch (e) {
      print('API Error (Team): $e');
      return null;
    }
  }

  Future<bool> createTeam(int practiceId, String name, List<int> memberIds) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.practiceParticipationsMe);
      final List data = json.decode(response.body);
      final matched = data.cast<Map<String, dynamic>>().firstWhere(
        (item) => ((item['practice'] ?? {})['id'] ?? 0) == practiceId,
        orElse: () => <String, dynamic>{},
      );
      final participationId = matched['participationId'];
      if (participationId == null) {
        return false;
      }
      await _apiClient.post('${ApiEndpoints.practiceParticipationMembersInvite}/$participationId/members/invite', {
        'studentIds': memberIds,
      });
      return true;
    } catch (e) {
      print('API Error (Create Team): $e');
      return false;
    }
  }

  Future<bool> inviteTeamMembersByParticipation(int participationId, List<int> memberIds) async {
    try {
      await _apiClient.post(
        '${ApiEndpoints.practiceParticipationMembersInvite}/$participationId/members/invite',
        {'studentIds': memberIds},
      );
      return true;
    } catch (e) {
      print('API Error (Invite Members): $e');
      return false;
    }
  }

  // Journals
  Future<List<PracticeJournal>> getMyJournals() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.myJournals);
      final List data = json.decode(response.body);
      return data.map((j) => PracticeJournal.fromJson(j)).toList();
    } catch (e) {
      print('API Error (Journals): $e');
      return [];
    }
  }

  Future<bool> createJournal(int practiceId, String content, {int? teamId, String? filePath}) async {
    try {
      final body = {
        'practiceId': practiceId,
        'entryDate': DateTime.now().toIso8601String().split('T').first,
        'content': content,
        'draft': false,
      };
      if (filePath != null) body['filePath'] = filePath;
      
      await _apiClient.post(ApiEndpoints.createJournal, body);
      return true;
    } catch (e) {
      print('API Error (Create Journal): $e');
      return false;
    }
  }

  Future<List<StudentExam>> getMyExams() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.myExams);
      final data = json.decode(response.body) as Map<String, dynamic>;
      final content = data['content'] as List? ?? [];
      return content.map((e) => StudentExam.fromJson(e)).toList();
    } catch (e) {
      print('API Error (My Exams): $e');
      return [];
    }
  }

  Future<List<SubjectItem>> getSubjects({int page = 0, int size = 20}) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.subjects}?page=$page&size=$size');
      final data = json.decode(response.body) as Map<String, dynamic>;
      final content = data['content'] as List? ?? [];
      return content.map((e) => SubjectItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('API Error (Subjects): $e');
      return [];
    }
  }

  Future<List<ExamPracticeOption>> getExamPractices(int examId) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.examPractices}/$examId/practices');
      final data = json.decode(response.body) as List? ?? [];
      return data.map((e) => ExamPracticeOption.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('API Error (Exam Practices): $e');
      return [];
    }
  }

  Future<MyExamParticipation?> getMyExamParticipation(int examId) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.examMyParticipation}/$examId/participation/me');
      return MyExamParticipation.fromJson(json.decode(response.body) as Map<String, dynamic>);
    } catch (e) {
      if (_isNotFoundError(e)) {
        return null;
      }
      print('API Error (My Exam Participation): $e');
      return null;
    }
  }

  Future<bool> selectExamPractice(int examId, int examPracticeId) async {
    try {
      await _apiClient.post('${ApiEndpoints.examSelectPractice}/$examId/practices/$examPracticeId/select', {});
      return true;
    } catch (e) {
      print('API Error (Select Exam Practice): $e');
      return false;
    }
  }

  Future<bool> cancelExamParticipation(int examId) async {
    try {
      await _apiClient.delete('${ApiEndpoints.examMyParticipation}/$examId/participation/me');
      return true;
    } catch (e) {
      print('API Error (Cancel Participation): $e');
      return false;
    }
  }

  Future<List<StudentSummary>> getAvailableStudentsForInvite(int participationId) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.availableStudentsForInvite}/$participationId/members/available',
      );
      final data = json.decode(response.body) as List? ?? [];
      return data.map((e) => StudentSummary.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('API Error (Available Students): $e');
      return [];
    }
  }

  Future<bool> removeTeamMember(int participationId, int memberId) async {
    try {
      await _apiClient.delete('${ApiEndpoints.removeTeamMember}/$participationId/members/$memberId');
      return true;
    } catch (e) {
      print('API Error (Remove Team Member): $e');
      return false;
    }
  }

  Future<bool> leaveTeam(int participationId) async {
    try {
      await _apiClient.delete('${ApiEndpoints.leaveMyTeam}/$participationId/members/me');
      return true;
    } catch (e) {
      print('API Error (Leave Team): $e');
      return false;
    }
  }

  Future<PracticeSubmission?> getPracticeSubmissionByParticipation(int participationId) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.practiceSubmissions}/participation/$participationId',
      );
      return PracticeSubmission.fromJson(json.decode(response.body) as Map<String, dynamic>);
    } catch (e) {
      if (_isNotFoundError(e)) {
        return null;
      }
      print('API Error (Practice Submission): $e');
      return null;
    }
  }

  Future<bool> submitPracticeSubmission(int participationId, {String? textAnswer, String? fileUrl}) async {
    try {
      await _apiClient.post(
        '${ApiEndpoints.practiceSubmissions}/participation/$participationId/submit',
        {
          'textAnswer': textAnswer,
          'fileUrl': fileUrl,
        },
      );
      return true;
    } catch (e) {
      print('API Error (Submit Practice Submission): $e');
      return false;
    }
  }

  Future<bool> startExamAttempt(int examId) async {
    try {
      await _apiClient.post('${ApiEndpoints.examAttemptStart}/$examId/attempt/start', {});
      return true;
    } catch (e) {
      print('API Error (Start Exam Attempt): $e');
      return false;
    }
  }

  Future<StudentExamAttemptInfo?> getMyExamAttempt(int examId) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.examAttemptMe}/$examId/attempt/me');
      return StudentExamAttemptInfo.fromJson(json.decode(response.body) as Map<String, dynamic>);
    } catch (e) {
      if (_isNotFoundError(e)) {
        return null;
      }
      print('API Error (Get My Exam Attempt): $e');
      return null;
    }
  }

  Future<List<ExamQuestionItem>> getMyExamQuestions(int examId) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.examQuestionsMe}/$examId/questions/me');
      final data = json.decode(response.body) as List? ?? [];
      return data.map((e) => ExamQuestionItem.fromExamQuestionApi(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('API Error (Get My Exam Questions): $e');
      return [];
    }
  }

  Future<bool> saveExamAnswer(
    int examId,
    int examQuestionId, {
    String? textAnswer,
    List<int>? selectedOptionIds,
  }) async {
    try {
      await _apiClient.post(
        '${ApiEndpoints.examQuestionAnswer}/$examId/questions/$examQuestionId/answer',
        {
          'textAnswer': textAnswer,
          'selectedOptionIds': selectedOptionIds ?? [],
        },
      );
      return true;
    } catch (e) {
      print('API Error (Save Exam Answer): $e');
      return false;
    }
  }

  Future<bool> submitExamAttempt(int examId) async {
    try {
      await _apiClient.post('${ApiEndpoints.examAttemptSubmit}/$examId/attempt/submit', {});
      return true;
    } catch (e) {
      print('API Error (Submit Exam Attempt): $e');
      return false;
    }
  }

  Future<List<TeamInvitation>> getMyTeamInvitations() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.myTeamInvitations);
      final List data = json.decode(response.body);
      return data.map((e) => TeamInvitation.fromJson(e)).toList();
    } catch (e) {
      print('API Error (Team Invitations): $e');
      return [];
    }
  }

  Future<bool> acceptTeamInvitation(int participationId) async {
    try {
      await _apiClient.post('/practice-participations/$participationId/members/accept', {});
      return true;
    } catch (e) {
      print('API Error (Accept Invitation): $e');
      return false;
    }
  }

  Future<bool> declineTeamInvitation(int participationId) async {
    try {
      await _apiClient.post('/practice-participations/$participationId/members/decline', {});
      return true;
    } catch (e) {
      print('API Error (Decline Invitation): $e');
      return false;
    }
  }

  // Answers / Assignments
  Future<List<Map<String, dynamic>>> getMyAnswers() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.myAnswers);
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } catch (e) {
      print('API Error (My Answers): $e');
      return [];
    }
  }

  Future<bool> submitAnswer(int questionId, {String? text, String? url, String? filePath, String? selectedOption}) async {
    try {
      final Map<String, dynamic> body = {'examQuestionId': questionId};
      if (text != null) body['textAnswer'] = text;
      if (selectedOption != null) {
        final selectedId = int.tryParse(selectedOption);
        if (selectedId != null) {
          body['selectedOptionIds'] = [selectedId];
        }
      }

      await _apiClient.post(ApiEndpoints.answers, body);
      return true;
    } catch (e) {
      print('API Error (Submit Answer): $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getChats() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.myChats);
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } catch (e) {
      print('API Error (Get Chats): $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String chatId) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.chats}/$chatId/messages');
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } catch (e) {
      print('API Error (Get Chat Messages): $e');
      return [];
    }
  }

  Future<bool> sendMessage(String chatId, String message) async {
    try {
      await _apiClient.post('${ApiEndpoints.chats}/$chatId/messages', {'message': message});
      return true;
    } catch (e) {
      print('API Error (Send Chat Message): $e');
      return false;
    }
  }

  Future<void> registerFcmToken(String token) async {
    try {
      await _apiClient.post(ApiEndpoints.fcmToken, {'token': token});
    } catch (e) {
      print('API Error (Register FCM Token): $e');
    }
  }

  Future<void> unregisterFcmToken(String token) async {
    try {
      await _apiClient.delete('${ApiEndpoints.fcmToken}?token=$token');
    } catch (e) {
      print('API Error (Unregister FCM Token): $e');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Teacher — Profile
  // ───────────────────────────────────────────────────────────────────────────

  Future<TeacherProfileModel?> getTeacherProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.teacherProfileMe);
      return TeacherProfileModel.fromJson(json.decode(response.body));
    } catch (e) {
      print('API Error (Teacher Profile): $e');
      return null;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Teacher — Own subjects
  // ───────────────────────────────────────────────────────────────────────────

  Future<List<SubjectSummaryModel>> getTeacherOwnSubjects() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.teacherOwnSubjects);
      final List data = json.decode(response.body);
      return data
          .map((s) => SubjectSummaryModel.fromJson(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('API Error (Teacher Own Subjects): $e');
      return [];
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Teacher — Groups
  // ───────────────────────────────────────────────────────────────────────────

  Future<List<TeacherGroup>> getTeacherGroups() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.teacherGroups);
      final List data = json.decode(response.body);
      return data.map((g) => TeacherGroup.fromJson(g as Map<String, dynamic>)).toList();
    } catch (e) {
      print('API Error (Teacher Groups): $e');
      return [];
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Teacher — Exams
  // ───────────────────────────────────────────────────────────────────────────

  Future<List<TeacherExam>> getTeacherExams({int page = 0, int size = 20}) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.teacherExams}?own=true&page=$page&size=$size',
      );
      final data = json.decode(response.body) as Map<String, dynamic>;
      final content = data['content'] as List? ?? [];
      return content.map((e) => TeacherExam.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('API Error (Teacher Exams): $e');
      return [];
    }
  }

  Future<TeacherExam?> getTeacherExamById(int examId) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.teacherExams}/$examId');
      return TeacherExam.fromJson(json.decode(response.body) as Map<String, dynamic>);
    } catch (e) {
      print('API Error (Teacher Exam Detail): $e');
      return null;
    }
  }

  Future<TeacherExam?> createTeacherExam(Map<String, dynamic> body) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.teacherExams, body);
      return TeacherExam.fromJson(json.decode(response.body) as Map<String, dynamic>);
    } catch (e) {
      print('API Error (Create Exam): $e');
      return null;
    }
  }

  Future<TeacherExam?> updateTeacherExam(int examId, Map<String, dynamic> body) async {
    try {
      final response = await _apiClient.put('${ApiEndpoints.teacherExams}/$examId', body);
      return TeacherExam.fromJson(json.decode(response.body) as Map<String, dynamic>);
    } catch (e) {
      print('API Error (Update Exam): $e');
      return null;
    }
  }

  Future<bool> deleteTeacherExam(int examId) async {
    try {
      await _apiClient.delete('${ApiEndpoints.teacherExams}/$examId');
      return true;
    } catch (e) {
      print('API Error (Delete Exam): $e');
      return false;
    }
  }

  Future<bool> updateTeacherExamStatus(int examId, String status) async {
    try {
      await _apiClient.patch('${ApiEndpoints.teacherExams}/$examId/status?status=$status');
      return true;
    } catch (e) {
      print('API Error (Update Exam Status): $e');
      return false;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Teacher — Practices
  // ───────────────────────────────────────────────────────────────────────────

  Future<List<TeacherPractice>> getTeacherPractices({int page = 0, int size = 30}) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.teacherPractices}?own=true&page=$page&size=$size',
      );
      final data = json.decode(response.body) as Map<String, dynamic>;
      final content = data['content'] as List? ?? [];
      return content.map((p) => TeacherPractice.fromJson(p as Map<String, dynamic>)).toList();
    } catch (e) {
      print('API Error (Teacher Practices): $e');
      return [];
    }
  }

  Future<TeacherPractice?> createTeacherPractice(Map<String, dynamic> body) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.teacherPractices, body);
      return TeacherPractice.fromJson(json.decode(response.body) as Map<String, dynamic>);
    } catch (e) {
      print('API Error (Create Practice): $e');
      return null;
    }
  }

  Future<TeacherPractice?> updateTeacherPractice(int id, Map<String, dynamic> body) async {
    try {
      final response = await _apiClient.put('${ApiEndpoints.teacherPractices}/$id', body);
      return TeacherPractice.fromJson(json.decode(response.body) as Map<String, dynamic>);
    } catch (e) {
      print('API Error (Update Practice): $e');
      return null;
    }
  }

  Future<bool> deleteTeacherPractice(int id) async {
    try {
      await _apiClient.delete('${ApiEndpoints.teacherPractices}/$id');
      return true;
    } catch (e) {
      print('API Error (Delete Practice): $e');
      return false;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Teacher — Exam-Practices (варианты в экзамене)
  // ───────────────────────────────────────────────────────────────────────────

  Future<List<TeacherExamPractice>> getTeacherExamPractices(int examId) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.examPracticesTeacher}?examId=$examId&size=50',
      );
      final data = json.decode(response.body) as Map<String, dynamic>;
      final content = data['content'] as List? ?? [];
      return content
          .map((e) => TeacherExamPractice.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('API Error (Exam Practices Teacher): $e');
      return [];
    }
  }

  Future<bool> addPracticeToExam(int examId, int practiceId, int orderIndex) async {
    try {
      await _apiClient.post(ApiEndpoints.examPracticesTeacher, {
        'examId': examId,
        'practiceId': practiceId,
        'orderIndex': orderIndex,
      });
      return true;
    } catch (e) {
      print('API Error (Add Practice to Exam): $e');
      return false;
    }
  }

  Future<bool> removePracticeFromExam(int examPracticeId) async {
    try {
      await _apiClient.delete('${ApiEndpoints.examPracticesTeacher}/$examPracticeId');
      return true;
    } catch (e) {
      print('API Error (Remove Practice from Exam): $e');
      return false;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Teacher — Submissions (сдача работ)
  // ───────────────────────────────────────────────────────────────────────────

  Future<List<TeacherSubmission>> getSubmissionsByExam(int examId,
      {String? status, int page = 0, int size = 30}) async {
    try {
      var url = '${ApiEndpoints.teacherSubmissions}?examId=$examId&page=$page&size=$size';
      if (status != null) url += '&status=$status';
      final response = await _apiClient.get(url);
      final data = json.decode(response.body) as Map<String, dynamic>;
      final content = data['content'] as List? ?? [];
      return content
          .map((s) => TeacherSubmission.fromJson(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('API Error (Submissions by Exam): $e');
      return [];
    }
  }

  Future<bool> gradeSubmission(int submissionId, {String comment = ''}) async {
    try {
      await _apiClient.patch(
        '${ApiEndpoints.teacherSubmissions}/$submissionId/grade',
        body: {'teacherComment': comment},
      );
      return true;
    } catch (e) {
      print('API Error (Grade Submission): $e');
      return false;
    }
  }

  Future<bool> returnSubmission(int submissionId, {String comment = ''}) async {
    try {
      await _apiClient.patch(
        '${ApiEndpoints.teacherSubmissions}/$submissionId/return',
        body: {'teacherComment': comment},
      );
      return true;
    } catch (e) {
      print('API Error (Return Submission): $e');
      return false;
    }
  }
}
