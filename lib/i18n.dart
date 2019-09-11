import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class I18N {
  I18N(this.locale);

  final Locale locale;

  static I18N of(BuildContext context) {
    return Localizations.of(context, I18N);
  }

  static Map<String, Map<String, String>> _messages = {
    'appTitle': {
      'cs': 'Černoborský mapovč lokací',
      'en': 'Černobor location mapper'
    },
    'drawerPaired': {
      'cs': 'Spárováno se serverem',
      'en': 'Paired to server'
    },
    'drawerServerAvailable': {
      'cs': 'Server dostupný',
      'en': 'Server available'
    },
    'zoomIn': {
      'cs': 'Přiblížit',
      'en': 'Zoom in'
    },
    'zoomOut': {
      'cs': 'Oddálit',
      'en': 'Zoom out'
    },
    'serverAddressLabel': {
      'cs': 'Adresa serveru',
      'en': 'Server address'
    },
    'errorAddressRequired': {
      'cs': 'Adresa je vyžadována',
      'en': 'Address is required'
    },
    'stop': {
      'cs': 'Stop',
      'en': 'Stop'
    },
    'scan': {
      'cs': 'Naskenovat',
      'en': 'Scan'
    },
    'nameLabel': {
      'cs': 'Jméno',
      'en': 'Name'
    },
    'descriptionLabel': {
      'cs': 'Popis',
      'en': 'Description'
    },
    'errorNameRequired': {
      'cs': 'Jméno je vyžadováno',
      'en': 'Name is required'
    },
    'dialogPair': {
      'cs': 'Spárovat',
      'en': 'Pair'
    },
    'dialogCancel': {
      'cs': 'Zrušit',
      'en': 'Cancel'
    },
    'dialogSave': {
      'cs': 'Uložit',
      'en': 'Save'
    },
    'invalidPairFields': {
      'cs': 'Pole mají neplatné hodnoty',
      'en': 'The fields have invalid values'
    },
    'alertErrorTitle': {
      'cs': 'Chyba',
      'en': 'Error'
    },
    'ok': {
      'cs': 'OK',
      'en': 'OK'
    },
    'commErrorNameNotSupplied': {
      'cs': 'Nebylo posláno žádné jméno.',
      'en': 'No name was sent.'
    },
    'commErrorNameAlreadyExists': {
      'cs': 'Poslané jméno již existuje.',
      'en': 'The sent name already exists.'
    },
    'logPoiCurrentLocation': {
      'cs': 'Zanést bod na aktuální poloze',
      'en': 'Log point at current position'
    },
    'logPoiCrosshair': {
      'cs': 'Zanést bod na zaměřovači',
      'en': 'Log point at crosshair'
    },
    'locationContinuousButtonTooltip': {
      'cs': 'Zapnout/vypnout získávání polohy',
      'en': 'Turn location acquisition on/off',
    },
    'toggleLockViewToLocationButtonTooltip': {
      'cs': 'Zaměřit pohled na aktuální polohu',
      'en': 'Center view to current location'
    },
    'addPoiDialogTitle': {
      'cs': 'Vlastnosti bodu',
      'en': 'Point properties'
    },
    'downloadMap': {
      'cs': 'Stáhnout mapu oblasti',
      'en': 'Download area map'
    },
    'downloadingMapSnackBar': {
      'cs': 'Stahuji...',
      'en': 'Downloading...'
    },
    'unpackingMapSnackBar': {
      'cs': 'Rozbaluji...',
      'en': 'Unpacking...'
    },
    'doneMapSnackBar': {
      'cs': 'Hotovo!',
      'en': 'Done!'
    },
    'download': {
      'cs': 'Stáhnout ze serveru',
      'en': 'Download from server'
    },
    'upload': {
      'cs': 'Nahrát na server',
      'en': 'Upload to server'
    },
    'sync': {
      'cs': 'Synchronizovat se serverem',
      'en': 'Synchronize with server'
    }
  };

  String get appTitle => _messages['appTitle'][locale.languageCode];
  String get drawerPaired => _messages['drawerPaired'][locale.languageCode];
  String get drawerServerAvailable => _messages['drawerServerAvailable'][locale.languageCode];
  String get zoomIn => _messages['zoomIn'][locale.languageCode];
  String get zoomOut => _messages['zoomOut'][locale.languageCode];
  String get serverAddressLabel => _messages['serverAddressLabel'][locale.languageCode];
  String get errorAddressRequired => _messages['errorAddressRequired'][locale.languageCode];
  String get stop => _messages['stop'][locale.languageCode];
  String get scan => _messages['scan'][locale.languageCode];
  String get nameLabel => _messages['nameLabel'][locale.languageCode];
  String get descriptionLabel => _messages['descriptionLabel'][locale.languageCode];
  String get errorNameRequired => _messages['errorNameRequired'][locale.languageCode];
  String get dialogPair => _messages['dialogPair'][locale.languageCode];
  String get dialogCancel => _messages['dialogCancel'][locale.languageCode];
  String get dialogSave => _messages['dialogSave'][locale.languageCode];
  String get invalidPairFields => _messages['invalidPairFields'][locale.languageCode];
  String get alertErrorTitle => _messages['alertErrorTitle'][locale.languageCode];
  String get ok => _messages['ok'][locale.languageCode];
  String get commErrorNameNotSupplied => _messages['commErrorNameNotSupplied'][locale.languageCode];
  String get commErrorNameAlreadyExists => _messages['commErrorNameAlreadyExists'][locale.languageCode];
  String get logPoiCurrentLocation => _messages['logPoiCurrentLocation'][locale.languageCode];
  String get logPoiCrosshair => _messages['logPoiCrosshair'][locale.languageCode];
  String get locationContinuousButtonTooltip => _messages['locationContinuousButtonTooltip'][locale.languageCode];
  String get lockViewToLocationButtonTooltip => _messages['toggleLockViewToLocationButtonTooltip'][locale.languageCode];
  String get addPoiDialogTitle => _messages['addPoiDialogTitle'][locale.languageCode];
  String get downloadMap => _messages['downloadMap'][locale.languageCode];
  String get downloadingMapSnackBar => _messages['downloadingMapSnackBar'][locale.languageCode];
  String get unpackingMapSnackBar => _messages['unpackingMapSnackBar'][locale.languageCode];
  String get doneMapSnackBar => _messages['doneMapSnackBar'][locale.languageCode];
  String get download => _messages['download'][locale.languageCode];
  String get upload => _messages['upload'][locale.languageCode];
  String get sync => _messages['sync'][locale.languageCode];
}

class I18NDelegate extends LocalizationsDelegate<I18N> {
  const I18NDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'cs'].contains(locale.languageCode);

  @override
  Future<I18N> load(Locale locale) => SynchronousFuture<I18N>(I18N(locale));

  @override
  bool shouldReload(LocalizationsDelegate<I18N> old) => false;


}