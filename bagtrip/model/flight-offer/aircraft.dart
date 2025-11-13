class Aircraft {
  final String code;

  Aircraft({required this.code});

  factory Aircraft.fromJson(Map<String, dynamic> json) =>
      Aircraft(code: json["code"]);

  Map<String, dynamic> toJson() => {"code": code};
}
