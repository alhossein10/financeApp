import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/language_bloc.dart';
import '../../../../core/services/language_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../injection_container.dart' as di;

/// Language settings page for changing app language
class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Language Settings',
        ),
      ),
      body: BlocBuilder<LanguageBloc, LanguageState>(
        builder: (context, state) {
          String currentLanguageCode = 'ar'; // default
          
          if (state is LanguageLoaded) {
            currentLanguageCode = state.locale.languageCode;
          }
          
          final languageService = di.sl<LanguageService>();
          final supportedLanguages = languageService.getSupportedLanguages();
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.language,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'App Language',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select your preferred language',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Language options
              ...supportedLanguages.map((language) {
                final isSelected = currentLanguageCode == language.code;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isSelected ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary 
                          : Colors.grey.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => _changeLanguage(context, language.code),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Flag emoji
                          Text(
                            language.flag,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 16),
                          
                          // Language names
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  language.nativeName,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  language.name,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Selection indicator
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                            )
                          else
                            Icon(
                              Icons.circle_outlined,
                              color: Colors.grey[400],
                              size: 28,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              
              const SizedBox(height: 24),
              
              // Info section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'The app will restart to apply the language change.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _changeLanguage(BuildContext context, String languageCode) {
    final currentState = context.read<LanguageBloc>().state;
    
    // Check if already selected
    if (currentState is LanguageLoaded && currentState.locale.languageCode == languageCode) {
      return;
    }
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Change Language',
        ),
        content: Text(
          'Language changed successfully' ?? 
              'The app will restart to apply the language change. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              AppLocalizations.of(context)?.cancel ?? 'Cancel',
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              
              // Change language
              context.read<LanguageBloc>().add(LanguageChanged(languageCode));
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Language changed successfully' ?? 
                        'Language changed successfully',
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
              
              // Navigate back after a short delay
              Future.delayed(const Duration(milliseconds: 500), () {
                if (context.mounted) {
                  Navigator.pop(context);
                }
              });
            },
            child: Text(
              AppLocalizations.of(context)?.confirm ?? 'Confirm',
            ),
          ),
        ],
      ),
    );
  }
}
