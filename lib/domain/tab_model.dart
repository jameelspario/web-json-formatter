class TabModel {

  dynamic id;
  dynamic name;
  dynamic data;
  dynamic txtSize;
  dynamic isBold;
  dynamic isItalic;
  /*
  1=> text;
  2=> json

  */
  dynamic state; 

  TabModel({
     this.id,
     this.name,
     this.data = "",
     this.txtSize = 16.0,
     this.state = 0,
     this.isBold = 0,
     this.isItalic = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'data': data ?? '',
      'txtSize': txtSize,
      'state': state,
      'isBold': isBold,
      'isItalic': isItalic,
    };
  }

  factory TabModel.fromJson(Map<String, dynamic> json) {
    return TabModel(
      id: json['id'],
      name: json['name'],
      data: json['data'] ?? '',
      txtSize: (json['txtSize'] as num?)?.toDouble() ?? 16.0,
      state: json['state'] ?? 0,
      isBold: json['isBold'] ?? 0,
      isItalic: json['isItalic'] ?? 0,
    );
  }
}
