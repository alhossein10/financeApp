import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/language_service.dart';

// Events
abstract class LanguageEvent extends Equatable {
  const LanguageEvent();
  
  @override
  List<Object?> get props => [];
}

class LanguageLoadRequested extends LanguageEvent {}

class LanguageChanged extends LanguageEvent {
  final String languageCode;
  
  const LanguageChanged(this.languageCode);
  
  @override
  List<Object?> get props => [languageCode];
}

// States
abstract class LanguageState extends Equatable {
  const LanguageState();
  
  @override
  List<Object?> get props => [];
}

class LanguageInitial extends LanguageState {}

class LanguageLoaded extends LanguageState {
  final Locale locale;
  
  const LanguageLoaded(this.locale);
  
  @override
  List<Object?> get props => [locale];
}

// BLoC
class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  final LanguageService _languageService;
  
  LanguageBloc(this._languageService) : super(LanguageInitial()) {
    on<LanguageLoadRequested>(_onLanguageLoadRequested);
    on<LanguageChanged>(_onLanguageChanged);
  }
  
  Future<void> _onLanguageLoadRequested(
    LanguageLoadRequested event,
    Emitter<LanguageState> emit,
  ) async {
    final locale = _languageService.getSavedLocale();
    emit(LanguageLoaded(locale));
  }
  
  Future<void> _onLanguageChanged(
    LanguageChanged event,
    Emitter<LanguageState> emit,
  ) async {
    if (_languageService.isLanguageSupported(event.languageCode)) {
      await _languageService.saveLanguage(event.languageCode);
      emit(LanguageLoaded(Locale(event.languageCode)));
    }
  }
}
