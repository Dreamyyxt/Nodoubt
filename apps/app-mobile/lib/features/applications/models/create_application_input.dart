class CreateApplicationInput {
  const CreateApplicationInput({
    required this.message,
    this.quotedPrice,
  });

  final String message;
  final double? quotedPrice;
}
