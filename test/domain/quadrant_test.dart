import 'package:flutter_test/flutter_test.dart';
import 'package:todolist/domain/quadrant.dart';

void main() {
  group('quadrantFor', () {
    test('maps importance and urgency to the correct quadrant', () {
      expect(quadrantFor(important: true, urgent: true), Quadrant.q1);
      expect(quadrantFor(important: false, urgent: true), Quadrant.q2);
      expect(quadrantFor(important: false, urgent: false), Quadrant.q3);
      expect(quadrantFor(important: true, urgent: false), Quadrant.q4);
    });

    test('axis flags describe each quadrant', () {
      expect(Quadrant.q1.isImportant, isTrue);
      expect(Quadrant.q1.isUrgent, isTrue);
      expect(Quadrant.q2.isImportant, isFalse);
      expect(Quadrant.q2.isUrgent, isTrue);
      expect(Quadrant.q3.isImportant, isFalse);
      expect(Quadrant.q3.isUrgent, isFalse);
      expect(Quadrant.q4.isImportant, isTrue);
      expect(Quadrant.q4.isUrgent, isFalse);
    });
  });
}
