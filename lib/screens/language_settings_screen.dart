import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'Site Surveyor Compass',
      'home': 'Home',
      'settings': 'Settings',
      'waypoints': 'Waypoints',
      'tracks': 'Tracks',
      'map': 'Map',
      'compass': 'Compass',
      'tools': 'Tools',
      'export': 'Export',
      'import': 'Import',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'search': 'Search',
      'latitude': 'Latitude',
      'longitude': 'Longitude',
      'altitude': 'Altitude',
      'accuracy': 'Accuracy',
      'speed': 'Speed',
      'bearing': 'Bearing',
      'distance': 'Distance',
      'area': 'Area',
      'perimeter': 'Perimeter',
      'offline_maps': 'Offline Maps',
      'data_sync': 'Data Sync',
      'survey_forms': 'Survey Forms',
      'geofencing': 'Geofencing',
      'export_formats': 'Export Formats',
      'bluetooth_gps': 'Bluetooth GPS',
      'language': 'Language',
      'theme': 'Theme',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'units': 'Units',
      'metric': 'Metric',
      'imperial': 'Imperial',
      'about': 'About',
      'version': 'Version',
    },
    'hi': {
      'app_name': 'साइट सर्वेयर कम्पास',
      'home': 'होम',
      'settings': 'सेटिंग्स',
      'waypoints': 'वेपॉइंट्स',
      'tracks': 'ट्रैक्स',
      'map': 'मानचित्र',
      'compass': 'कम्पास',
      'tools': 'टूल्स',
      'export': 'निर्यात',
      'import': 'आयात',
      'save': 'सहेजें',
      'cancel': 'रद्द करें',
      'delete': 'हटाएं',
      'edit': 'संपादित करें',
      'add': 'जोड़ें',
      'search': 'खोजें',
      'latitude': 'अक्षांश',
      'longitude': 'देशांतर',
      'altitude': 'ऊंचाई',
      'accuracy': 'सटीकता',
      'speed': 'गति',
      'bearing': 'दिशा',
      'distance': 'दूरी',
      'area': 'क्षेत्र',
      'perimeter': 'परिधि',
      'offline_maps': 'ऑफ़लाइन मानचित्र',
      'data_sync': 'डेटा सिंक',
      'survey_forms': 'सर्वे फॉर्म',
      'geofencing': 'जियोफेंसिंग',
      'export_formats': 'निर्यात प्रारूप',
      'bluetooth_gps': 'ब्लूटूथ GPS',
      'language': 'भाषा',
      'theme': 'थीम',
      'dark_mode': 'डार्क मोड',
      'light_mode': 'लाइट मोड',
      'units': 'इकाइयां',
      'metric': 'मीट्रिक',
      'imperial': 'इम्पीरियल',
      'about': 'जानकारी',
      'version': 'संस्करण',
    },
    'es': {
      'app_name': 'Brújula de Agrimensor',
      'home': 'Inicio',
      'settings': 'Ajustes',
      'waypoints': 'Puntos',
      'tracks': 'Rutas',
      'map': 'Mapa',
      'compass': 'Brújula',
      'tools': 'Herramientas',
      'export': 'Exportar',
      'import': 'Importar',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'delete': 'Eliminar',
      'edit': 'Editar',
      'add': 'Añadir',
      'search': 'Buscar',
      'latitude': 'Latitud',
      'longitude': 'Longitud',
      'altitude': 'Altitud',
      'accuracy': 'Precisión',
      'speed': 'Velocidad',
      'bearing': 'Rumbo',
      'distance': 'Distancia',
      'area': 'Área',
      'perimeter': 'Perímetro',
      'offline_maps': 'Mapas Sin Conexión',
      'data_sync': 'Sincronización',
      'survey_forms': 'Formularios',
      'geofencing': 'Geovalla',
      'export_formats': 'Formatos de Exportación',
      'bluetooth_gps': 'GPS Bluetooth',
      'language': 'Idioma',
      'theme': 'Tema',
      'dark_mode': 'Modo Oscuro',
      'light_mode': 'Modo Claro',
      'units': 'Unidades',
      'metric': 'Métrico',
      'imperial': 'Imperial',
      'about': 'Acerca de',
      'version': 'Versión',
    },
    'fr': {
      'app_name': 'Compas d\'Arpentage',
      'home': 'Accueil',
      'settings': 'Paramètres',
      'waypoints': 'Points',
      'tracks': 'Trajets',
      'map': 'Carte',
      'compass': 'Boussole',
      'tools': 'Outils',
      'export': 'Exporter',
      'import': 'Importer',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'add': 'Ajouter',
      'search': 'Rechercher',
      'latitude': 'Latitude',
      'longitude': 'Longitude',
      'altitude': 'Altitude',
      'accuracy': 'Précision',
      'speed': 'Vitesse',
      'bearing': 'Azimut',
      'distance': 'Distance',
      'area': 'Surface',
      'perimeter': 'Périmètre',
      'offline_maps': 'Cartes Hors Ligne',
      'data_sync': 'Synchronisation',
      'survey_forms': 'Formulaires',
      'geofencing': 'Géofence',
      'export_formats': 'Formats d\'Export',
      'bluetooth_gps': 'GPS Bluetooth',
      'language': 'Langue',
      'theme': 'Thème',
      'dark_mode': 'Mode Sombre',
      'light_mode': 'Mode Clair',
      'units': 'Unités',
      'metric': 'Métrique',
      'imperial': 'Impérial',
      'about': 'À propos',
      'version': 'Version',
    },
    'de': {
      'app_name': 'Vermesser Kompass',
      'home': 'Startseite',
      'settings': 'Einstellungen',
      'waypoints': 'Wegpunkte',
      'tracks': 'Tracks',
      'map': 'Karte',
      'compass': 'Kompass',
      'tools': 'Werkzeuge',
      'export': 'Exportieren',
      'import': 'Importieren',
      'save': 'Speichern',
      'cancel': 'Abbrechen',
      'delete': 'Löschen',
      'edit': 'Bearbeiten',
      'add': 'Hinzufügen',
      'search': 'Suchen',
      'latitude': 'Breitengrad',
      'longitude': 'Längengrad',
      'altitude': 'Höhe',
      'accuracy': 'Genauigkeit',
      'speed': 'Geschwindigkeit',
      'bearing': 'Peilung',
      'distance': 'Entfernung',
      'area': 'Fläche',
      'perimeter': 'Umfang',
      'offline_maps': 'Offline Karten',
      'data_sync': 'Datensync',
      'survey_forms': 'Umfrageformulare',
      'geofencing': 'Geofencing',
      'export_formats': 'Exportformate',
      'bluetooth_gps': 'Bluetooth GPS',
      'language': 'Sprache',
      'theme': 'Design',
      'dark_mode': 'Dunkelmodus',
      'light_mode': 'Hellmodus',
      'units': 'Einheiten',
      'metric': 'Metrisch',
      'imperial': 'Imperial',
      'about': 'Über',
      'version': 'Version',
    },
    'zh': {
      'app_name': '现场测量指南针',
      'home': '首页',
      'settings': '设置',
      'waypoints': '航点',
      'tracks': '轨迹',
      'map': '地图',
      'compass': '指南针',
      'tools': '工具',
      'export': '导出',
      'import': '导入',
      'save': '保存',
      'cancel': '取消',
      'delete': '删除',
      'edit': '编辑',
      'add': '添加',
      'search': '搜索',
      'latitude': '纬度',
      'longitude': '经度',
      'altitude': '海拔',
      'accuracy': '精度',
      'speed': '速度',
      'bearing': '方向',
      'distance': '距离',
      'area': '面积',
      'perimeter': '周长',
      'offline_maps': '离线地图',
      'data_sync': '数据同步',
      'survey_forms': '调查表',
      'geofencing': '地理围栏',
      'export_formats': '导出格式',
      'bluetooth_gps': '蓝牙GPS',
      'language': '语言',
      'theme': '主题',
      'dark_mode': '深色模式',
      'light_mode': '浅色模式',
      'units': '单位',
      'metric': '公制',
      'imperial': '英制',
      'about': '关于',
      'version': '版本',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']![key] ?? key;
  }

  String operator [](String key) => translate(key);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'es', 'fr', 'de', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedLanguage = 'en';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'hi', 'name': 'हिंदी (Hindi)'},
    {'code': 'es', 'name': 'Español (Spanish)'},
    {'code': 'fr', 'name': 'Français (French)'},
    {'code': 'de', 'name': 'Deutsch (German)'},
    {'code': 'zh', 'name': '中文 (Chinese)'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language'),
        backgroundColor: const Color(0xFF1a1a2e),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: ListView.builder(
          itemCount: _languages.length,
          itemBuilder: (context, index) {
            final lang = _languages[index];
            final isSelected = _selectedLanguage == lang['code'];
            return ListTile(
              leading: Icon(
                Icons.language,
                color: isSelected ? Colors.cyanAccent : Colors.white54,
              ),
              title: Text(
                lang['name']!,
                style: TextStyle(
                  color: isSelected ? Colors.cyanAccent : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.cyanAccent)
                  : null,
              onTap: () {
                setState(() => _selectedLanguage = lang['code']!);
              },
            );
          },
        ),
      ),
    );
  }
}