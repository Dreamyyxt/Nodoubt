class CityCoordinates {
  const CityCoordinates({
    required this.longitude,
    required this.latitude,
  });

  final double longitude;
  final double latitude;
}

const Map<String, CityCoordinates> cityCoordinatesByCode = {
  'beijing': CityCoordinates(longitude: 116.4074, latitude: 39.9042),
  'shanghai': CityCoordinates(longitude: 121.4737, latitude: 31.2304),
  'guangzhou': CityCoordinates(longitude: 113.2644, latitude: 23.1291),
  'shenzhen': CityCoordinates(longitude: 114.0579, latitude: 22.5431),
  'hangzhou': CityCoordinates(longitude: 120.1551, latitude: 30.2741),
  'chengdu': CityCoordinates(longitude: 104.0665, latitude: 30.5728),
  'wuhan': CityCoordinates(longitude: 114.3054, latitude: 30.5931),
  'xian': CityCoordinates(longitude: 108.9398, latitude: 34.3416),
  'nanjing': CityCoordinates(longitude: 118.7969, latitude: 32.0603),
  'suzhou': CityCoordinates(longitude: 120.5853, latitude: 31.2989),
  'chongqing': CityCoordinates(longitude: 106.5516, latitude: 29.5630),
  'changsha': CityCoordinates(longitude: 112.9388, latitude: 28.2282),
  'qingdao': CityCoordinates(longitude: 120.3826, latitude: 36.0671),
  'xiamen': CityCoordinates(longitude: 118.0894, latitude: 24.4798),
  'tianjin': CityCoordinates(longitude: 117.2000, latitude: 39.0842),
  'unknown': CityCoordinates(longitude: 104.0, latitude: 35.0),
};

const Map<String, String> cityLabelByCode = {
  'beijing': '北京',
  'shanghai': '上海',
  'guangzhou': '广州',
  'shenzhen': '深圳',
  'hangzhou': '杭州',
  'chengdu': '成都',
  'wuhan': '武汉',
  'xian': '西安',
  'nanjing': '南京',
  'suzhou': '苏州',
  'chongqing': '重庆',
  'changsha': '长沙',
  'qingdao': '青岛',
  'xiamen': '厦门',
  'tianjin': '天津',
  'unknown': '未知区域',
};

CityCoordinates resolveCityCoordinates(String? cityCode) {
  if (cityCode == null || cityCode.isEmpty) {
    return cityCoordinatesByCode['unknown']!;
  }
  return cityCoordinatesByCode[cityCode] ?? cityCoordinatesByCode['unknown']!;
}

String resolveCityLabel(String? cityCode) {
  if (cityCode == null || cityCode.isEmpty) {
    return cityLabelByCode['unknown']!;
  }
  return cityLabelByCode[cityCode] ?? cityCode;
}
