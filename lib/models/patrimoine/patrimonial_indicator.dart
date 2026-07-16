class PatrimonialIndicator {
  final String name;
  final double currentValue;
  final double targetValue;
  final double progression;
  final bool isReached;
  final bool isCalculable;

  PatrimonialIndicator({
    required this.name,
    required this.currentValue,
    required this.targetValue,
    required this.progression,
    required this.isReached,
    required this.isCalculable,
  });
}
