import 'package:freezed_annotation/freezed_annotation.dart';

part 'completion_status.freezed.dart';
part 'completion_status.g.dart';

@freezed
class CompletionStatus with _$CompletionStatus {
  const factory CompletionStatus({
    required int id,
    required String code,
    required String label,
  }) = _CompletionStatus;

  factory CompletionStatus.fromJson(Map<String, dynamic> json) =>
      _$CompletionStatusFromJson(json);
}
