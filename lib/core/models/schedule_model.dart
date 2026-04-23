class ScheduleModel {
  final String? id;
  final String practitionerId;
  final Map<int, List<String>> weeklySlots; // Key: 1(Lundi) -> 7(Dimanche), Value: Liste des horaires ex ["09:00", "10:00"]
  final bool isVacation;

  ScheduleModel({
    this.id,
    required this.practitionerId,
    required this.weeklySlots,
    this.isVacation = false,
  });

  factory ScheduleModel.fromMap(Map<String, dynamic> data, String documentId) {
    Map<int, List<String>> parsedSlots = {};
    if (data['weeklySlots'] != null) {
      final Map<String, dynamic> rawSlots = data['weeklySlots'];
      rawSlots.forEach((key, value) {
        parsedSlots[int.parse(key)] = List<String>.from(value);
      });
    }

    return ScheduleModel(
      id: documentId,
      practitionerId: data['practitionerId'] ?? '',
      weeklySlots: parsedSlots,
      isVacation: data['isVacation'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> formattedSlots = {};
    weeklySlots.forEach((key, value) {
      formattedSlots[key.toString()] = value;
    });

    return {
      'practitionerId': practitionerId,
      'weeklySlots': formattedSlots,
      'isVacation': isVacation,
    };
  }
}
