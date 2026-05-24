
class User {
  final String id;
  final String name;
  final String studentId;
  final String avatarUrl;

  User({required this.id, required this.name, required this.studentId, required this.avatarUrl});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      studentId: json['studentNumber'] ?? '',
      avatarUrl: '', // Backend doesn't seem to provide this yet
    );
  }
}

// Student Dashboard Models
class DashboardSubject {
  final int id;
  final String name;
  final String description;
  final List<TeacherSummary> teachers;

  DashboardSubject({required this.id, required this.name, required this.description, required this.teachers});

  factory DashboardSubject.fromJson(Map<String, dynamic> json) {
    return DashboardSubject(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      teachers: (json['teachers'] as List? ?? []).map((t) => TeacherSummary.fromJson(t)).toList(),
    );
  }
}

class DashboardItem {
  final int id;
  final String title;
  final DateTime deadline;
  final String type;

  DashboardItem({required this.id, required this.title, required this.deadline, required this.type});

  factory DashboardItem.fromJson(Map<String, dynamic> json) {
    return DashboardItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      deadline: DateTime.tryParse(json['deadline'] ?? '') ?? DateTime.now(),
      type: json['type'] ?? '',
    );
  }
}

class StudentDashboardResponse {
  final List<DashboardSubject> subjects;
  final List<DashboardItem> practices;
  final List<DashboardItem> exams;

  StudentDashboardResponse({required this.subjects, required this.practices, required this.exams});

  factory StudentDashboardResponse.fromJson(Map<String, dynamic> json) {
    return StudentDashboardResponse(
      subjects: (json['subjects'] as List? ?? []).map((s) => DashboardSubject.fromJson(s)).toList(),
      practices: (json['practices'] as List? ?? []).map((p) => DashboardItem.fromJson(p)).toList(),
      exams: (json['exams'] as List? ?? []).map((e) => DashboardItem.fromJson(e)).toList(),
    );
  }
}

// Profile Models
class StudentProfileResponse {
  final int id;
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final int course;
  final String studentNumber;
  final String phoneNumber;
  final String notes;

  StudentProfileResponse({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.course,
    required this.studentNumber,
    required this.phoneNumber,
    required this.notes,
  });

  factory StudentProfileResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] ?? {};
    return StudentProfileResponse(
      id: json['id'] ?? 0,
      userId: userJson['id'] ?? 0,
      firstName: userJson['firstName'] ?? '',
      lastName: userJson['lastName'] ?? '',
      email: userJson['email'] ?? '',
      course: json['course'] ?? 0,
      studentNumber: json['studentNumber'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      notes: json['notes'] ?? '',
    );
  }
}

// Practice Models
class Practice {
  final int id;
  final String title;
  final String description;
  final String? resourceUrl;
  final String? requirements;
  final DateTime deadline;
  final String workMode; // INDIVIDUAL, TEAM
  final int teamSize;
  final bool calendarRequired;

  Practice({
    required this.id,
    required this.title,
    required this.description,
    this.resourceUrl,
    this.requirements,
    required this.deadline,
    required this.workMode,
    required this.teamSize,
    required this.calendarRequired,
  });

  factory Practice.fromJson(Map<String, dynamic> json) {
    final deadlineRaw = json['deadline'] ?? json['endAt'] ?? json['dueDate'];
    return Practice(
      id: json['id'] ?? 0,
      title: json['name'] ?? '',
      description: json['description'] ?? '',
      resourceUrl: json['resourceUrl'],
      requirements: json['requirements'],
      deadline: DateTime.tryParse(deadlineRaw?.toString() ?? '') ?? DateTime.now(),
      workMode: json['workMode'] ?? 'INDIVIDUAL',
      teamSize: json['teamSize'] ?? 1,
      calendarRequired: json['calendarRequired'] ?? false,
    );
  }
}

// Team Models
class PracticeTeamResponse {
  final int id;
  final String name;
  final List<StudentSummary> members;

  PracticeTeamResponse({required this.id, required this.name, required this.members});

  factory PracticeTeamResponse.fromJson(Map<String, dynamic> json) {
    return PracticeTeamResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      members: (json['members'] as List? ?? []).map((m) => StudentSummary.fromJson(m)).toList(),
    );
  }
}

// Helper Summaries
class TeacherSummary {
  final int id;
  final String firstName;
  final String lastName;
  final String email;

  TeacherSummary({required this.id, required this.firstName, required this.lastName, required this.email});

  factory TeacherSummary.fromJson(Map<String, dynamic> json) {
    return TeacherSummary(
      id: json['id'] ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class StudentSummary {
  final int id;
  final String firstName;
  final String lastName;
  final String email;

  StudentSummary({required this.id, required this.firstName, required this.lastName, required this.email});

  factory StudentSummary.fromJson(Map<String, dynamic> json) {
    return StudentSummary(
      id: json['id'] ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class PracticeJournal {
  final int id;
  final String content;
  final String? filePath;
  final String? calendarText;
  final String? calendarFilePath;
  final DateTime submittedAt;
  final int practiceId;

  PracticeJournal({
    required this.id, 
    required this.content, 
    this.filePath,
    this.calendarText,
    this.calendarFilePath,
    required this.submittedAt, 
    required this.practiceId
  });

  factory PracticeJournal.fromJson(Map<String, dynamic> json) {
    return PracticeJournal(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      filePath: json['filePath'],
      calendarText: json['calendarText'],
      calendarFilePath: json['calendarFilePath'],
      submittedAt: DateTime.tryParse(json['submittedAt'] ?? '') ?? DateTime.now(),
      practiceId: json['practiceId'] ?? 0,
    );
  }
}

class StudentExam {
  final int id;
  final String title;
  final String description;
  final DateTime? startAt;
  final DateTime? endAt;
  final String type;
  final String status;

  StudentExam({
    required this.id,
    required this.title,
    required this.description,
    required this.startAt,
    required this.endAt,
    required this.type,
    required this.status,
  });

  factory StudentExam.fromJson(Map<String, dynamic> json) {
    return StudentExam(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startAt: DateTime.tryParse((json['startAt'] ?? '').toString()),
      endAt: DateTime.tryParse((json['endAt'] ?? '').toString()),
      type: json['type'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class TeamInvitation {
  final int participationId;
  final int examId;
  final int examPracticeId;
  final String examTitle;
  final String practiceName;
  final String invitedByName;

  TeamInvitation({
    required this.participationId,
    required this.examId,
    required this.examPracticeId,
    required this.examTitle,
    required this.practiceName,
    required this.invitedByName,
  });

  factory TeamInvitation.fromJson(Map<String, dynamic> json) {
    final practice = (json['practice'] ?? {}) as Map<String, dynamic>;
    final invitedBy = (json['invitedBy'] ?? {}) as Map<String, dynamic>;
    return TeamInvitation(
      participationId: json['participationId'] ?? 0,
      examId: json['examId'] ?? 0,
      examPracticeId: json['examPracticeId'] ?? 0,
      examTitle: json['examTitle'] ?? '',
      practiceName: practice['name'] ?? '',
      invitedByName: '${invitedBy['firstName'] ?? ''} ${invitedBy['lastName'] ?? ''}'.trim(),
    );
  }
}

class SubjectItem {
  final int id;
  final String name;
  final String description;

  SubjectItem({
    required this.id,
    required this.name,
    required this.description,
  });

  factory SubjectItem.fromJson(Map<String, dynamic> json) {
    return SubjectItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class ExamPracticeOption {
  final int id;
  final int examId;
  final Practice practice;

  ExamPracticeOption({
    required this.id,
    required this.examId,
    required this.practice,
  });

  factory ExamPracticeOption.fromJson(Map<String, dynamic> json) {
    return ExamPracticeOption(
      id: json['id'] ?? 0,
      examId: json['examId'] ?? 0,
      practice: Practice.fromJson((json['practice'] ?? {}) as Map<String, dynamic>),
    );
  }
}

class PracticeSubmission {
  final int id;
  final int participationId;
  final String textAnswer;
  final String fileUrl;
  final String status;
  final String teacherComment;

  PracticeSubmission({
    required this.id,
    required this.participationId,
    required this.textAnswer,
    required this.fileUrl,
    required this.status,
    required this.teacherComment,
  });

  factory PracticeSubmission.fromJson(Map<String, dynamic> json) {
    return PracticeSubmission(
      id: json['id'] ?? 0,
      participationId: json['participationId'] ?? 0,
      textAnswer: json['textAnswer'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      status: json['status'] ?? '',
      teacherComment: json['teacherComment'] ?? '',
    );
  }
}

class MyExamParticipation {
  final int participationId;
  final int examId;
  final int examPracticeId;
  final Practice practice;
  final String status;
  final List<StudentSummary> members;
  final PracticeSubmission? submission;

  MyExamParticipation({
    required this.participationId,
    required this.examId,
    required this.examPracticeId,
    required this.practice,
    required this.status,
    required this.members,
    required this.submission,
  });

  factory MyExamParticipation.fromJson(Map<String, dynamic> json) {
    final membersRaw = (json['members'] as List? ?? []);
    return MyExamParticipation(
      participationId: json['participationId'] ?? 0,
      examId: json['examId'] ?? 0,
      examPracticeId: json['examPracticeId'] ?? 0,
      practice: Practice.fromJson((json['practice'] ?? {}) as Map<String, dynamic>),
      status: json['status'] ?? '',
      members: membersRaw.map((m) {
        final user = ((m as Map<String, dynamic>)['user'] ?? {}) as Map<String, dynamic>;
        return StudentSummary.fromJson(user);
      }).toList(),
      submission: json['submission'] == null
          ? null
          : PracticeSubmission.fromJson(json['submission'] as Map<String, dynamic>),
    );
  }
}
