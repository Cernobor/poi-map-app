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
    'centerButtonTooltip': {
      'cs': 'Zaměřit polohu a vycentrovat',
      'en': 'Acquire and center on current position',
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
    }
  };

  String get appTitle => _messages['appTitle'][locale.languageCode];
  String get drawerPaired => _messages['drawerPaired'][locale.languageCode];
  String get drawerServerAvailable => _messages['drawerServerAvailable'][locale.languageCode];
  String get centerButtonTooltip => _messages['centerButtonTooltip'][locale.languageCode];
  String get zoomIn => _messages['zoomIn'][locale.languageCode];
  String get zoomOut => _messages['zoomOut'][locale.languageCode];
  String get serverAddressLabel => _messages['serverAddressLabel'][locale.languageCode];
  String get errorAddressRequired => _messages['errorAddressRequired'][locale.languageCode];
  String get stop => _messages['stop'][locale.languageCode];
  String get scan => _messages['scan'][locale.languageCode];
  String get nameLabel => _messages['nameLabel'][locale.languageCode];
  String get errorNameRequired => _messages['errorNameRequired'][locale.languageCode];
  String get dialogPair => _messages['dialogPair'][locale.languageCode];
  String get dialogCancel => _messages['dialogCancel'][locale.languageCode];
  String get invalidPairFields => _messages['invalidPairFields'][locale.languageCode];
  String get alertErrorTitle => _messages['alertErrorTitle'][locale.languageCode];
  String get ok => _messages['ok'][locale.languageCode];
  String get commErrorNameNotSupplied => _messages['commErrorNameNotSupplied'][locale.languageCode];
  String get commErrorNameAlreadyExists => _messages['commErrorNameAlreadyExists'][locale.languageCode];
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