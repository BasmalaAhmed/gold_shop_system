String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year;

  return '$day/$month/$year';
}

String formatDueDate(DateTime? dueDate) {
  if (dueDate == null) {
    return 'موعد الاستحقاق غير محدد';
  }

  const months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  final date = dueDate.toLocal();
  final today = DateTime.now();

  final dueDay = DateTime(date.year, date.month, date.day);
  final todayDate = DateTime(today.year, today.month, today.day);

  final formattedDate = '${date.day} ${months[date.month - 1]}';

  if (dueDay.isBefore(todayDate)) {
    return 'مستحقة منذ $formattedDate';
  }

  if (dueDay.isAtSameMomentAs(todayDate)) {
    return 'مستحقة اليوم';
  }

  return 'مستحقة $formattedDate';
}

String formatClock(DateTime time) {
  final t = time.toLocal();
  final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final minute = t.minute.toString().padLeft(2, '0');
  return '$hour12:$minute ${t.hour < 12 ? 'ص' : 'م'}';
}

bool isSameLocalDay(DateTime a, DateTime b) {
  final x = a.toLocal();
  final y = b.toLocal();
  return x.year == y.year && x.month == y.month && x.day == y.day;
}
