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
  final DateTime? birthDate;

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
    this.birthDate,
  });

  factory StudentProfileResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] ?? {};
    return StudentProfileResponse(
      id: json['id'] ?? 0,
      userId: userJson['id'] ?? json['userId'] ?? 0,
      firstName: userJson['firstName'] ?? json['firstName'] ?? '',
      lastName: userJson['lastName'] ?? json['lastName'] ?? '',
      email: userJson['email'] ?? json['email'] ?? '',
      course: json['course'] ?? 0,
      studentNumber: json['studentNumber'] ?? userJson['universityId'] ?? '',
      phoneNumber: json['phoneNumber'] ?? userJson['phoneNumber'] ?? '',
      notes: json['notes'] ?? '',
      birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate']) : null,
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
  final String myStatus;
  final int practiceCount;
  final int questionCount;
  final int taskLimit;
  final List<ExamQuestionItem> questions;
  final int? subjectId;
  final String? subjectName;

  StudentExam({
    required this.id,
    required this.title,
    required this.description,
    required this.startAt,
    required this.endAt,
    required this.type,
    required this.status,
    required this.myStatus,
    required this.practiceCount,
    required this.questionCount,
    required this.taskLimit,
    required this.questions,
    this.subjectId,
    this.subjectName,
  });

  factory StudentExam.fromJson(Map<String, dynamic> json) {
    final practices = (json['practices'] as List? ?? []);
    final questions = (json['questions'] as List? ?? []);
    final subject = json['subject'] as Map<String, dynamic>?;
    return StudentExam(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startAt: DateTime.tryParse((json['startAt'] ?? '').toString()),
      endAt: DateTime.tryParse((json['endAt'] ?? '').toString()),
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      myStatus: json['myStatus'] ?? 'NOT_STARTED',
      practiceCount: practices.length,
      questionCount: questions.length,
      taskLimit: (json['taskLimit'] as num?)?.toInt() ?? 0,
      questions: questions
          .map((e) => ExamQuestionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subjectId: subject?['id'] as int?,
      subjectName: subject?['name'] as String?,
    );
  }
}

class ExamQuestionItem {
  final int id;
  final int questionId;
  final String questionText;
  final String questionType;
  final int score;
  final int orderIndex;
  final List<ExamQuestionOptionItem> options;
  final String textAnswer;
  final List<int> selectedOptionIds;

  ExamQuestionItem({
    required this.id,
    required this.questionId,
    required this.questionText,
    required this.questionType,
    required this.score,
    required this.orderIndex,
    required this.options,
    required this.textAnswer,
    required this.selectedOptionIds,
  });

  factory ExamQuestionItem.fromJson(Map<String, dynamic> json) {
    return ExamQuestionItem(
      id: json['id'] ?? 0,
      questionId: json['questionId'] ?? 0,
      questionText: json['questionText'] ?? '',
      questionType: json['questionType'] ?? '',
      score: json['score'] ?? 0,
      orderIndex: json['orderIndex'] ?? 0,
      options: [],
      textAnswer: '',
      selectedOptionIds: const [],
    );
  }

  factory ExamQuestionItem.fromExamQuestionApi(Map<String, dynamic> json) {
    return ExamQuestionItem(
      id: json['examQuestionId'] ?? 0,
      questionId: json['examQuestionId'] ?? 0,
      questionText: json['questionText'] ?? '',
      questionType: json['questionType'] ?? '',
      score: json['score'] ?? 0,
      orderIndex: json['orderIndex'] ?? 0,
      options: (json['options'] as List? ?? [])
          .map((e) => ExamQuestionOptionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      textAnswer: json['textAnswer'] ?? '',
      selectedOptionIds: (json['selectedOptionIds'] as List? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
    );
  }
}

class ExamQuestionOptionItem {
  final int id;
  final String text;
  final int orderIndex;

  ExamQuestionOptionItem({required this.id, required this.text, required this.orderIndex});

  factory ExamQuestionOptionItem.fromJson(Map<String, dynamic> json) {
    return ExamQuestionOptionItem(
      id: json['id'] ?? 0,
      text: json['text'] ?? '',
      orderIndex: json['orderIndex'] ?? 0,
    );
  }
}

class StudentExamAttemptInfo {
  final String status;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final DateTime? attemptDeadlineAt;
  final int? remainingSeconds;
  final int? totalScore;

  StudentExamAttemptInfo({
    required this.status,
    required this.startedAt,
    required this.submittedAt,
    required this.attemptDeadlineAt,
    required this.remainingSeconds,
    this.totalScore,
  });

  factory StudentExamAttemptInfo.fromJson(Map<String, dynamic> json) {
    return StudentExamAttemptInfo(
      status: json['status'] ?? '',
      startedAt: DateTime.tryParse((json['startedAt'] ?? '').toString()),
      submittedAt: DateTime.tryParse((json['submittedAt'] ?? '').toString()),
      attemptDeadlineAt: DateTime.tryParse((json['attemptDeadlineAt'] ?? '').toString()),
      remainingSeconds: (json['remainingSeconds'] as num?)?.toInt(),
      totalScore: (json['totalScore'] as num?)?.toInt(),
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

class StudentGroupMember {
  final int id;
  final String firstName;
  final String lastName;
  final String email;

  StudentGroupMember({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory StudentGroupMember.fromJson(Map<String, dynamic> json) {
    return StudentGroupMember(
      id: json['id'] ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class StudentGroupModel {
  final int id;
  final String name;
  final String description;
  final String language;
  final List<SubjectItem> subjects;
  final List<StudentGroupMember> teachers;

  StudentGroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.language,
    required this.subjects,
    required this.teachers,
  });

  factory StudentGroupModel.fromJson(Map<String, dynamic> json) {
    return StudentGroupModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      language: json['language']?.toString() ?? '',
      subjects: (json['subjects'] as List? ?? [])
          .map((s) => SubjectItem.fromJson(s as Map<String, dynamic>))
          .toList(),
      teachers: (json['teachers'] as List? ?? [])
          .map((t) => StudentGroupMember.fromJson(t as Map<String, dynamic>))
          .toList(),
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
  final int attemptCount;

  PracticeSubmission({
    required this.id,
    required this.participationId,
    required this.textAnswer,
    required this.fileUrl,
    required this.status,
    required this.teacherComment,
    this.attemptCount = 0,
  });

  factory PracticeSubmission.fromJson(Map<String, dynamic> json) {
    return PracticeSubmission(
      id: json['id'] ?? 0,
      participationId: json['participationId'] ?? 0,
      textAnswer: json['textAnswer'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      status: json['status'] ?? '',
      teacherComment: json['teacherComment'] ?? '',
      attemptCount: json['attemptCount'] ?? 0,
    );
  }
}

class PracticeSubmissionAttemptItem {
  final int id;
  final int attemptNumber;
  final String textAnswer;
  final String fileUrl;
  final DateTime submittedAt;
  final String teacherComment;

  PracticeSubmissionAttemptItem({
    required this.id,
    required this.attemptNumber,
    required this.textAnswer,
    required this.fileUrl,
    required this.submittedAt,
    required this.teacherComment,
  });

  factory PracticeSubmissionAttemptItem.fromJson(Map<String, dynamic> json) {
    return PracticeSubmissionAttemptItem(
      id: json['id'] ?? 0,
      attemptNumber: json['attemptNumber'] ?? 0,
      textAnswer: json['textAnswer'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      submittedAt: DateTime.tryParse(json['submittedAt']?.toString() ?? '') ??
          DateTime.now(),
      teacherComment: json['teacherComment'] ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Teacher Models
// ─────────────────────────────────────────────────────────────────────────────

class SubjectSummaryModel {
  final int id;
  final String name;
  final String description;

  SubjectSummaryModel({required this.id, required this.name, required this.description});

  factory SubjectSummaryModel.fromJson(Map<String, dynamic> json) {
    return SubjectSummaryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class GroupSummaryModel {
  final int id;
  final String name;
  final String language;

  GroupSummaryModel({required this.id, required this.name, required this.language});

  factory GroupSummaryModel.fromJson(Map<String, dynamic> json) {
    return GroupSummaryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      language: json['language']?.toString() ?? '',
    );
  }
}

class TeacherProfileModel {
  final int id;
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String academicDegree;
  final List<SubjectSummaryModel> teachingSubjects;
  final DateTime? birthDate;

  TeacherProfileModel({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.academicDegree,
    required this.teachingSubjects,
    this.birthDate,
  });

  factory TeacherProfileModel.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] ?? {}) as Map<String, dynamic>;
    return TeacherProfileModel(
      id: json['id'] ?? 0,
      userId: user['id'] ?? 0,
      firstName: user['firstName'] ?? '',
      lastName: user['lastName'] ?? '',
      email: user['email'] ?? '',
      academicDegree: json['academicDegree'] ?? '',
      teachingSubjects: (json['teachingSubjects'] as List? ?? [])
          .map((s) => SubjectSummaryModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate']) : null,
    );
  }
}

class TeacherGroup {
  final int id;
  final String name;
  final String description;
  final String language;
  final List<StudentSummary> students;

  TeacherGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.language,
    required this.students,
  });

  factory TeacherGroup.fromJson(Map<String, dynamic> json) {
    return TeacherGroup(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      language: json['language']?.toString() ?? '',
      students: (json['students'] as List? ?? [])
          .map((s) => StudentSummary.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TeacherPractice {
  final int id;
  final String name;
  final String description;
  final String? resourceUrl;
  final String? requirements;
  final String workMode; // INDIVIDUAL, TEAM
  final bool calendarRequired;
  final String? subjectName;

  TeacherPractice({
    required this.id,
    required this.name,
    required this.description,
    this.resourceUrl,
    this.requirements,
    required this.workMode,
    required this.calendarRequired,
    this.subjectName,
  });

  factory TeacherPractice.fromJson(Map<String, dynamic> json) {
    final subject = json['subject'] as Map<String, dynamic>?;
    return TeacherPractice(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      resourceUrl: json['resourceUrl'],
      requirements: json['requirements'],
      workMode: json['workMode']?.toString() ?? 'INDIVIDUAL',
      calendarRequired: json['calendarRequired'] ?? json['schedulingRequired'] ?? false,
      subjectName: subject?['name']?.toString(),
    );
  }
}

class TeacherExam {
  final int id;
  final String title;
  final String description;
  final DateTime? startAt;
  final DateTime? endAt;
  final int maxScore;
  final int taskLimit;
  final String type; // PRACTICE, QUESTION
  final String status; // PUBLISHED, COMPLETED, CANCELLED
  final List<GroupSummaryModel> groups;
  final int practiceCount;
  final int questionCount;
  final int? subjectId;
  final String? subjectName;

  TeacherExam({
    required this.id,
    required this.title,
    required this.description,
    required this.startAt,
    required this.endAt,
    required this.maxScore,
    required this.taskLimit,
    required this.type,
    required this.status,
    required this.groups,
    required this.practiceCount,
    required this.questionCount,
    this.subjectId,
    this.subjectName,
  });

  factory TeacherExam.fromJson(Map<String, dynamic> json) {
    final subject = json['subject'] as Map<String, dynamic>?;
    return TeacherExam(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startAt: DateTime.tryParse((json['startAt'] ?? '').toString()),
      endAt: DateTime.tryParse((json['endAt'] ?? '').toString()),
      maxScore: (json['maxScore'] as num?)?.toInt() ?? 0,
      taskLimit: (json['taskLimit'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      groups: (json['groups'] as List? ?? [])
          .map((g) => GroupSummaryModel.fromJson(g as Map<String, dynamic>))
          .toList(),
      practiceCount: (json['practices'] as List? ?? []).length,
      questionCount: (json['questions'] as List? ?? []).length,
      subjectId: (subject?['id'] as num?)?.toInt(),
      subjectName: subject?['name']?.toString(),
    );
  }
}

class TeacherExamPractice {
  final int id;
  final int examId;
  final int practiceId;
  final String practiceName;
  final String workMode;
  final bool calendarRequired;

  TeacherExamPractice({
    required this.id,
    required this.examId,
    required this.practiceId,
    required this.practiceName,
    required this.workMode,
    required this.calendarRequired,
  });

  factory TeacherExamPractice.fromJson(Map<String, dynamic> json) {
    final p = (json['practice'] ?? {}) as Map<String, dynamic>;
    return TeacherExamPractice(
      id: json['id'] ?? 0,
      examId: json['examId'] ?? 0,
      practiceId: p['id'] ?? 0,
      practiceName: p['name'] ?? '',
      workMode: p['workMode']?.toString() ?? 'INDIVIDUAL',
      calendarRequired: p['schedulingRequired'] ?? false,
    );
  }
}

class TeacherSubmission {
  final int id;
  final int participationId;
  final int examId;
  final int examPracticeId;
  final String studentFirstName;
  final String studentLastName;
  final String studentEmail;
  final String textAnswer;
  final String fileUrl;
  final DateTime? submittedAt;
  final String status; // SUBMITTED, GRADED, RETURNED
  final String teacherComment;

  TeacherSubmission({
    required this.id,
    required this.participationId,
    required this.examId,
    required this.examPracticeId,
    required this.studentFirstName,
    required this.studentLastName,
    required this.studentEmail,
    required this.textAnswer,
    required this.fileUrl,
    required this.submittedAt,
    required this.status,
    required this.teacherComment,
  });

  String get studentFullName => '$studentFirstName $studentLastName'.trim();

  factory TeacherSubmission.fromJson(Map<String, dynamic> json) {
    final by = (json['submittedBy'] ?? {}) as Map<String, dynamic>;
    return TeacherSubmission(
      id: json['id'] ?? 0,
      participationId: json['participationId'] ?? 0,
      examId: json['examId'] ?? 0,
      examPracticeId: json['examPracticeId'] ?? 0,
      studentFirstName: by['firstName'] ?? '',
      studentLastName: by['lastName'] ?? '',
      studentEmail: by['email'] ?? '',
      textAnswer: json['textAnswer'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      submittedAt: DateTime.tryParse((json['submittedAt'] ?? '').toString()),
      status: json['status']?.toString() ?? '',
      teacherComment: json['teacherComment'] ?? '',
    );
  }
}

class TeacherQuestionOption {
  final int id;
  final String text;
  final bool correct;

  TeacherQuestionOption({
    required this.id,
    required this.text,
    required this.correct,
  });

  factory TeacherQuestionOption.fromJson(Map<String, dynamic> json) {
    return TeacherQuestionOption(
      id: (json['id'] as num?)?.toInt() ?? 0,
      text: json['text']?.toString() ?? '',
      correct: json['correct'] == true,
    );
  }
}

class TeacherQuestion {
  final int id;
  final String text;
  final String type; // OPEN, CLOSED, MULTIPLE_CHOICE
  final String? subjectName;
  final int? subjectId;
  final List<TeacherQuestionOption> options;

  TeacherQuestion({
    required this.id,
    required this.text,
    required this.type,
    this.subjectName,
    this.subjectId,
    required this.options,
  });

  factory TeacherQuestion.fromJson(Map<String, dynamic> json) {
    final subject = json['subject'] as Map<String, dynamic>?;
    return TeacherQuestion(
      id: (json['id'] as num?)?.toInt() ?? 0,
      text: json['text']?.toString() ?? '',
      type: json['type']?.toString() ?? 'OPEN',
      subjectName: subject?['name']?.toString(),
      subjectId: (subject?['id'] as num?)?.toInt(),
      options: (json['options'] as List? ?? [])
          .map((o) => TeacherQuestionOption.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }
}

class NotificationItem {
  final int id;
  final String title;
  final String body;
  final String type;
  final int? referenceId;
  final bool read;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    required this.read,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? '',
      referenceId: json['referenceId'] as int?,
      read: json['read'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  NotificationItem copyWith({bool? read}) {
    return NotificationItem(
      id: id,
      title: title,
      body: body,
      type: type,
      referenceId: referenceId,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }
}

class ParticipationMember {
  final int id;
  final StudentSummary user;
  final String role;
  final String status;

  ParticipationMember({required this.id, required this.user, required this.role, required this.status});

  bool get isLeader => role == 'LEADER';

  factory ParticipationMember.fromJson(Map<String, dynamic> json) {
    return ParticipationMember(
      id: json['id'] ?? 0,
      user: StudentSummary.fromJson((json['user'] ?? {}) as Map<String, dynamic>),
      role: json['role'] ?? 'MEMBER',
      status: json['status'] ?? '',
    );
  }
}

class MyExamParticipation {
  final int participationId;
  final int examId;
  final int examPracticeId;
  final Practice practice;
  final String status;
  final List<ParticipationMember> members;
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
      members: membersRaw
          .map((m) => ParticipationMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      submission: json['submission'] == null
          ? null
          : PracticeSubmission.fromJson(json['submission'] as Map<String, dynamic>),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Teacher Exam Attempt Models
// ─────────────────────────────────────────────────────────────────────────────

class TeacherAttempt {
  final int attemptId;
  final StudentSummary student;
  final String status; // SUBMITTED, GRADED
  final DateTime? submittedAt;
  final int? totalScore;
  final int openUngradedCount;

  TeacherAttempt({
    required this.attemptId,
    required this.student,
    required this.status,
    required this.submittedAt,
    required this.totalScore,
    required this.openUngradedCount,
  });

  factory TeacherAttempt.fromJson(Map<String, dynamic> json) {
    return TeacherAttempt(
      attemptId: json['attemptId'] ?? 0,
      student: StudentSummary.fromJson(json['student'] as Map<String, dynamic>),
      status: json['status'] ?? '',
      submittedAt: json['submittedAt'] == null
          ? null
          : DateTime.tryParse(json['submittedAt'].toString()),
      totalScore: (json['totalScore'] as num?)?.toInt(),
      openUngradedCount: json['openUngradedCount'] ?? 0,
    );
  }
}

class TeacherAnswerOption {
  final int id;
  final String text;
  final bool correct;
  final int orderIndex;

  TeacherAnswerOption(
      {required this.id,
      required this.text,
      required this.correct,
      required this.orderIndex});

  factory TeacherAnswerOption.fromJson(Map<String, dynamic> json) {
    return TeacherAnswerOption(
      id: json['id'] ?? 0,
      text: json['text'] ?? '',
      correct: json['correct'] ?? false,
      orderIndex: json['orderIndex'] ?? 0,
    );
  }
}

class TeacherAttemptAnswer {
  final int? answerId;
  final int examQuestionId;
  final int orderIndex;
  final String questionText;
  final String questionType; // OPEN, CLOSED, MULTIPLE_CHOICE
  final int maxScore;
  final String? textAnswer;
  final List<int> selectedOptionIds;
  final List<TeacherAnswerOption> options;
  final int? score;
  final bool? correct;

  TeacherAttemptAnswer({
    required this.answerId,
    required this.examQuestionId,
    required this.orderIndex,
    required this.questionText,
    required this.questionType,
    required this.maxScore,
    required this.textAnswer,
    required this.selectedOptionIds,
    required this.options,
    required this.score,
    required this.correct,
  });

  factory TeacherAttemptAnswer.fromJson(Map<String, dynamic> json) {
    return TeacherAttemptAnswer(
      answerId: (json['answerId'] as num?)?.toInt(),
      examQuestionId: json['examQuestionId'] ?? 0,
      orderIndex: json['orderIndex'] ?? 0,
      questionText: json['questionText'] ?? '',
      questionType: json['questionType'] ?? 'OPEN',
      maxScore: json['maxScore'] ?? 0,
      textAnswer: json['textAnswer'] as String?,
      selectedOptionIds: (json['selectedOptionIds'] as List? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      options: (json['options'] as List? ?? [])
          .map((e) => TeacherAnswerOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      score: (json['score'] as num?)?.toInt(),
      correct: json['correct'] as bool?,
    );
  }
}

