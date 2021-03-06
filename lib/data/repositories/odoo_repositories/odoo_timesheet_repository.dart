import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:hsc_timesheet/core/base/base_response.dart';
import 'package:hsc_timesheet/core/logger.dart';
import 'package:hsc_timesheet/data/models/index.dart';
import 'package:hsc_timesheet/data/repositories/index.dart';
import 'package:hsc_timesheet/data/transform/odoo_to_timesheet.dart';
import 'package:odoo_rpc/odoo_rpc.dart';

import 'odoo_connect.dart';

class OdooTimeSheetRepository extends TimeSheetRepository with OdooConnect {
  final OdooClient client;

  OdooTimeSheetRepository(this.client);

  @override
  Future<BaseResponse<List<TimeSheet>>> getAllTimeSheet(int employeeId) async {
    try {
      var data = await client.callKw({
        'model': 'account.analytic.line',
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'context': {'bin_size': true},
          'domain': [
            ['employee_id', '=', employeeId],
            // ["date", ">=", "2022-06-01"],
            // ["date", "<=", "2022-06-30"],
          ],
          'fields': [
            'user_id',
            'unit_amount',
            'project_id',
            'employee_id',
            'task_id',
            'date',
            'display_name',
            'id',
          ],
        },
      });
      // logger.d('getAllTimeSheet: $data');
      final odooTimesheetList = await data
          .map<OdooTimeSheetRow>((item) => OdooTimeSheetRow.fromJson(item))
          .toList();

      final List<TimeSheet> timeSheets =
          TimeSheetTransform().transform(odooTimesheetList);

      return BaseResponse.success(timeSheets);
    } on OdooException catch (e) {
      await handleError(e);
      return BaseResponse.fail([e.message]);
    } on Exception catch (e) {
      await handleError(e);
      return BaseResponse.fail([tr('message.server_error')]);
    }
  }

  @override
  Future<BaseResponse<List<TimeSheet>>> getTimeSheetUnApproved() async {
    // getProjectId('Over Time');
    try {
      var data = await client.callKw({
        'model': 'account.analytic.line',
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'context': {'bin_size': true},
          'domain': [
            ['user_id', '!=', 1]
          ],
          'fields': [
            'user_id',
            'unit_amount',
            'project_id',
            'employee_id',
            'task_id',
            'date',
            'display_name',
            'id',
          ],
        },
      });
      // logger.d('getAllTimeSheet: $data');
      final odooTimesheetList = await data
          .map<OdooTimeSheetRow>((item) => OdooTimeSheetRow.fromJson(item))
          .toList();

      final List<TimeSheet> timeSheets =
          TimeSheetTransform().transform(odooTimesheetList);

      return BaseResponse.success(timeSheets);
    } on OdooException catch (e) {
      await handleError(e);
      return BaseResponse.fail([e.message]);
    } on Exception catch (e) {
      await handleError(e);
      return BaseResponse.fail([tr('message.server_error')]);
    }
  }

  @override
  Future<BaseResponse<List<TimeSheet>>> getTimeSheetApproved(
      int employeeId) async {
    // getProjectId('Over Time');
    try {
      var data = await client.callKw({
        'model': 'account.analytic.line',
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'context': {'bin_size': true},
          'domain': [
            ['employee_id', '=', employeeId],
            ['user_id', '=', 1]
          ],
          'fields': [
            'user_id',
            'unit_amount',
            'project_id',
            'employee_id',
            'task_id',
            'date',
            'display_name',
            'id',
          ],
        },
      });
      // logger.d('getAllTimeSheet: $data');
      final odooTimesheetList = await data
          .map<OdooTimeSheetRow>((item) => OdooTimeSheetRow.fromJson(item))
          .toList();

      final List<TimeSheet> timeSheets =
          TimeSheetTransform().transform(odooTimesheetList);

      return BaseResponse.success(timeSheets);
    } on OdooException catch (e) {
      await handleError(e);
      return BaseResponse.fail([e.message]);
    } on Exception catch (e) {
      await handleError(e);
      return BaseResponse.fail([tr('message.server_error')]);
    }
  }

  @override
  Future<BaseResponse<int>> getProjectId(String name) async {
    try {
      var res = await client.callKw({
        'model': 'project.project',
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'context': {'bin_size': true},
          'domain': [
            ['name', '=', name]
          ],
          'fields': [
            'id',
          ],
        },
      });
      // logger.d('id from Odoo: ${res[0]['id']}');
      print("======================");
      print(res);
      var id = res[0]['id'];

      return BaseResponse.success(id);
    } on OdooException catch (e) {
      handleError(e,
          additionalMessage: 'UserRepository.GetProjectId($name) error');
      return BaseResponse.fail([e.message]);
    } on Exception catch (e) {
      await handleError(e);
      return BaseResponse.fail([tr('message.server_error')]);
    }
  }

  @override
  Future<BaseResponse<int>> getTaskId(String name) async {
    try {
      var res = await client.callKw({
        'model': 'project.task',
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'context': {'bin_size': true},
          'domain': [
            ['name', '=', name]
          ],
          'fields': [
            'id',
          ],
        },
      });
      var id = res[0]['id'];

      return BaseResponse.success(id);
    } on OdooException catch (e) {
      handleError(e,
          additionalMessage: 'UserRepository.getTaskId($name) error');
      return BaseResponse.fail([e.message]);
    } on Exception catch (e) {
      await handleError(e);
      return BaseResponse.fail([tr('message.server_error')]);
    }
  }

  @override
  Future<BaseResponse<int?>> getRowId(
      int projectId, DateTime date, int employeeId) async {
    try {
      var res = await client.callKw({
        'model': 'account.analytic.line',
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'context': {'bin_size': true},
          'domain': [
            ['project_id', '=', projectId],
            ["date", "=", (DateFormat("yyyy-MM-dd").format(date))],
            ["employee_id", "=", employeeId],
          ],
          'fields': ['id'],
        },
      });
      var id;
      (res.isEmpty) ? (id = null) : (id = res[0]['id']);
      return BaseResponse.success(id);
    } on OdooException catch (e) {
      handleError(e, additionalMessage: 'UserRepository.getRowId error');
      return BaseResponse.fail([e.message]);
    } on Exception catch (e) {
      await handleError(e);
      return BaseResponse.fail([tr('message.server_error')]);
    }
  }

  @override
  Future<BaseResponse<int>> createOdooTimeSheet(OdooTimeSheetRow row) async {
    try {
      var data = await client.callKw({
        'model': 'account.analytic.line',
        'method': 'create',
        'args': [
          {
            'unit_amount': row.unitAmount,
            'date': row.date.toString(),
            'project_id': row.projectIdOdoo == null ? false : row.projectId,
            'employee_id': row.employeeIdOdoo == null ? false : row.employeeId,
            'task_id': row.taskIdOdoo,
            'user_id': row.userIdOdoo,
            'name': row.name
          },
        ],
        'kwargs': {},
      });
      // logger.d('getAllTimeSheetPosted: $data');

      return BaseResponse.success(data);
    } on OdooException catch (e) {
      await handleError(e);
      return BaseResponse.fail([e.message]);
    } on Exception catch (e) {
      await handleError(e);
      return BaseResponse.fail([tr('message.server_error')]);
    }
  }

  @override
  Future<BaseResponse<bool>> editOdooRow(OdooTimeSheetRow row) async {
    try {
      var res = await client.callKw({
        'model': 'account.analytic.line',
        'method': 'write',
        'args': [
          [row.id],
          {
            'task_id': row.taskId,
            'unit_amount': row.unitAmount,
            "name": row.name,
          }
        ],
        'kwargs': {},
      });
      return BaseResponse.success(res);
    } on OdooException catch (e) {
      handleError(e, additionalMessage: 'Update $row error');
      return BaseResponse.fail([e.message]);
    } on Exception catch (e) {
      await handleError(e);
      return BaseResponse.fail([tr('message.server_error')]);
    }
  }
  @override
  Future<BaseResponse<bool>> approveOdooRow(OdooTimeSheetRow row) async {
    try {
      var res = await client.callKw({
        'model': 'account.analytic.line',
        'method': 'write',
        'args': [
          [row.id],
          {
            'user_id': 1,
          }
        ],
        'kwargs': {},
      });
      return BaseResponse.success(res);
    } on OdooException catch (e) {
      handleError(e, additionalMessage: 'Approve $row error');
      return BaseResponse.fail([e.message]);
    } on Exception catch (e) {
      await handleError(e);
      return BaseResponse.fail([tr('message.server_error')]);
    }
  }

  @override
  Future<BaseResponse<bool>> deleteOdooRow(OdooTimeSheetRow row) async {
    try {
      var res = await client.callKw({
        'model': 'account.analytic.line',
        'method': 'unlink',
        'args': [
          [row.id],
        ],
        'kwargs': {},
      });
      return BaseResponse.success(res);
    } on OdooException catch (e) {
      handleError(e, additionalMessage: 'Unlink $row error');
      return BaseResponse.fail([e.message]);
    } on Exception catch (e) {
      await handleError(e);
      return BaseResponse.fail([tr('message.server_error')]);
    }
  }
}
