String? validateTitle(String? value) {
  final title = value?.trim() ?? '';
  if (title.isEmpty) {
    return '请输入事件标题';
  }
  if (title.length > 200) {
    return '标题不能超过 200 个字符';
  }
  return null;
}

String? validateDescription(String? value) {
  if ((value?.length ?? 0) > 5000) {
    return '描述不能超过 5000 个字符';
  }
  return null;
}

String? validateLocation(String? value) {
  if ((value?.length ?? 0) > 200) {
    return '地点不能超过 200 个字符';
  }
  return null;
}

String? validateScheduleRange(DateTime startAt, DateTime endAt) {
  if (endAt.isBefore(startAt)) {
    return '结束时间不得早于开始时间';
  }
  return null;
}
