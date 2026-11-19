/// The four important/urgent quadrants.
///
/// Q1 is top-right, Q2 top-left, Q3 bottom-left and Q4 bottom-right.
enum Quadrant {
  q1,
  q2,
  q3,
  q4;

  bool get isImportant => this == Quadrant.q1 || this == Quadrant.q4;

  bool get isUrgent => this == Quadrant.q1 || this == Quadrant.q2;
}

Quadrant quadrantFor({required bool important, required bool urgent}) {
  if (important) {
    return urgent ? Quadrant.q1 : Quadrant.q4;
  }
  return urgent ? Quadrant.q2 : Quadrant.q3;
}
