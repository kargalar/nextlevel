import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Enum/task_status_enum.dart';

class LogDisplayModel {
  final int id;
  final DateTime dateTime;
  final String displayAmount;
  final dynamic amount; // int for Counter, Duration for Timer
  final String status;
  final TaskStatusEnum? rawStatus;
  final Color? statusColor;
  final TaskTypeEnum type;
  final bool isPurchase;
  final bool canEdit;
  final String? datePart; // "Today", "Yesterday", etc.

  LogDisplayModel({
    required this.id,
    required this.dateTime,
    required this.displayAmount,
    required this.amount,
    required this.status,
    this.rawStatus,
    this.statusColor,
    required this.type,
    this.isPurchase = false,
    this.canEdit = true,
    this.datePart,
  });
}
