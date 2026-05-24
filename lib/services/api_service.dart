import 'dart:convert';
import '../models/models.dart';
import '../models/auth_models.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

class ApiService {
  final ApiClient _apiClient = ApiClient();

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

  // --- Fake Functions for Messaging (No Swagger equivalent yet) ---
  
  Future<List<Map<String, dynamic>>> getChats() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {'id': '1', 'name': 'Student A', 'lastMessage': 'See you at the practice!'},
      {'id': '2', 'name': 'Teacher B', 'lastMessage': 'Report received.'},
    ];
  }

  Future<bool> sendMessage(String chatId, String message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    print('Message sent to $chatId: $message');
    return true;
  }
}
