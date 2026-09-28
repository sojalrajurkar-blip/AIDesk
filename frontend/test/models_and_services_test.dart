import 'package:flutter_test/flutter_test.dart';
import 'package:ai_office_it_help_desk/models/user_model.dart';
import 'package:ai_office_it_help_desk/models/case_model.dart';
import 'package:ai_office_it_help_desk/models/communication_model.dart';
import 'package:ai_office_it_help_desk/models/task_model.dart';
import 'package:ai_office_it_help_desk/models/ai_analysis_model.dart';
import 'package:ai_office_it_help_desk/models/dashboard_model.dart';
import 'package:ai_office_it_help_desk/models/audit_model.dart';

void main() {
  group('Frontend Models Serialization Tests', () {
    test('UserModel parse and serialize', () {
      final user = UserModel.fromJson({
        'id': 'u-1',
        'email': 'requester@company.com',
        'full_name': 'Alex Rivera',
        'role': 'REQUESTER',
        'team_name': 'Engineering',
        'created_at': '2026-03-27T10:00:00Z',
      });

      expect(user.id, 'u-1');
      expect(user.role, 'REQUESTER');
      expect(user.fullName, 'Alex Rivera');
      expect(user.toJson()['email'], 'requester@company.com');
    });

    test('CaseModel parse and relationships', () {
      final caseItem = CaseModel.fromJson({
        'id': 'c-10482',
        'case_number': 'IT-10482',
        'title': 'Wi-Fi keeps dropping on 4th floor CorpNet-5G',
        'description': 'Laptops lose connection after 10 minutes.',
        'priority': 'P2',
        'status': 'IN_PROGRESS',
        'impact': 'MODERATE',
        'urgency': 'HIGH',
        'sla_tier': 'URGENT',
        'created_by_id': 'u-1',
        'created_at': '2026-03-27T10:00:00Z',
        'category': {
          'id': 'cat-net',
          'name': 'Network Connectivity',
        },
        'assigned_team': {
          'id': 'team-net',
          'name': 'Network Operations',
        },
      });

      expect(caseItem.caseNumber, 'IT-10482');
      expect(caseItem.priority, 'P2');
      expect(caseItem.status, 'IN_PROGRESS');
      expect(caseItem.category?.name, 'Network Connectivity');
      expect(caseItem.assignedTeam?.name, 'Network Operations');
    });

    test('CommunicationModel parse dual-stream', () {
      final pubMsg = CommunicationModel.fromJson({
        'id': 'comm-1',
        'case_id': 'c-1',
        'sender_id': 'u-2',
        'sender_role': 'OPERATOR',
        'message_type': 'PUBLIC_REPLY',
        'visibility': 'PUBLIC',
        'content': 'Please run a traceroute to 10.0.0.1',
        'ai_generated': true,
        'created_at': '2026-03-27T10:05:00Z',
      });

      expect(pubMsg.visibility, 'PUBLIC');
      expect(pubMsg.aiGenerated, true);

      final note = CommunicationModel.fromJson({
        'id': 'comm-2',
        'case_id': 'c-1',
        'sender_id': 'u-2',
        'sender_role': 'OPERATOR',
        'message_type': 'INTERNAL_NOTE',
        'visibility': 'INTERNAL',
        'content': 'RADIUS controller 4th floor CPU at 98%',
        'created_at': '2026-03-27T10:06:00Z',
      });

      expect(note.visibility, 'INTERNAL');
      expect(note.messageType, 'INTERNAL_NOTE');
    });

    test('TaskModel parse and findings', () {
      final task = TaskModel.fromJson({
        'id': 't-1',
        'case_id': 'c-1',
        'title': 'Check AP-04 RSSI signal strength',
        'status': 'COMPLETED',
        'findings': 'Signal strength -54dBm, no packet loss',
        'created_at': '2026-03-27T10:10:00Z',
      });

      expect(task.title, 'Check AP-04 RSSI signal strength');
      expect(task.status, 'COMPLETED');
      expect(task.findings, contains('-54dBm'));
    });

    test('AIAnalysisModel parse and duplicates radar', () {
      final ai = AIAnalysisModel.fromJson({
        'predicted_category': 'Network Connectivity',
        'predicted_priority': 'P2',
        'predicted_team': 'Network Operations',
        'confidence_score': 0.94,
        'sentiment': 'Frustrated / Urgent',
        'suggested_next_steps': ['Restart Wi-Fi interface', 'Flush DNS cache'],
        'duplicates': [
          {
            'case_id': 'c-999',
            'case_number': 'IT-10480',
            'title': '4th floor Wi-Fi unstable',
            'similarity_score': 0.89,
            'status': 'IN_PROGRESS',
          }
        ],
      });

      expect(ai.predictedPriority, 'P2');
      expect(ai.confidenceScore, 0.94);
      expect(ai.suggestedNextSteps.length, 2);
      expect(ai.duplicates.length, 1);
      expect(ai.duplicates.first.caseNumber, 'IT-10480');
    });

    test('AuditLogModel WORM checksum parse', () {
      final audit = AuditLogModel.fromJson({
        'id': 'aud-1',
        'case_id': 'c-10482',
        'user_role': 'OPERATOR',
        'event_type': 'STATUS_CHANGED',
        'action': 'Status transitioned from NEW to IN_PROGRESS',
        'sha256_checksum': '7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069',
        'created_at': '2026-03-27T10:15:00Z',
      });

      expect(audit.userRole, 'OPERATOR');
      expect(audit.sha256Checksum, startsWith('7f83b1657'));
    });

    test('Dashboard Models parse', () {
      final reqDash = RequesterDashboardModel.fromJson({
        'total_cases': 5,
        'open_cases': 2,
        'awaiting_action_cases': 1,
        'resolved_cases': 2,
        'recent_cases': [],
      });
      expect(reqDash.totalCases, 5);
      expect(reqDash.awaitingActionCases, 1);

      final opDash = OperatorDashboardModel.fromJson({
        'unassigned_count': 3,
        'my_assigned_count': 2,
        'high_risk_count': 1,
        'pending_resolution_count': 1,
        'unassigned_cases': [],
        'my_cases': [],
        'high_risk_cases': [],
      });
      expect(opDash.unassignedCount, 3);

      final mgrDash = ManagerDashboardModel.fromJson({
        'sla_compliance_rate': 98.2,
        'mttr_minutes': 35.0,
        'fcr_rate': 82.0,
        'total_active_incidents': 8,
        'squad_workloads': [],
        'problem_clusters': [],
      });
      expect(mgrDash.slaComplianceRate, 98.2);
    });
  });
}
