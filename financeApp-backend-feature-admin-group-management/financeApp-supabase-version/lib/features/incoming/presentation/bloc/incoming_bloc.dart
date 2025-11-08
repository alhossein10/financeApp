import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_incoming_usecase.dart';
import '../../domain/usecases/delete_incoming_usecase.dart';
import '../../domain/usecases/get_incoming_usecase.dart';
import '../../domain/usecases/update_incoming_usecase.dart';
import 'incoming_event.dart';
import 'incoming_state.dart';

class IncomingBloc extends Bloc<IncomingEvent, IncomingState> {
  final CreateIncomingUseCase createIncomingUseCase;
  final GetIncomingUseCase getIncomingUseCase;
  final UpdateIncomingUseCase updateIncomingUseCase;
  final DeleteIncomingUseCase deleteIncomingUseCase;

  IncomingBloc({
    required this.createIncomingUseCase,
    required this.getIncomingUseCase,
    required this.updateIncomingUseCase,
    required this.deleteIncomingUseCase,
  }) : super(const IncomingInitial()) {
    on<LoadIncoming>(_onLoadIncoming);
    on<CreateIncoming>(_onCreateIncoming);
    on<UpdateIncoming>(_onUpdateIncoming);
    on<DeleteIncoming>(_onDeleteIncoming);
  }

  Future<void> _onLoadIncoming(
    LoadIncoming event,
    Emitter<IncomingState> emit,
  ) async {
    emit(const IncomingLoading());

    final result = await getIncomingUseCase();

    result.fold(
      (failure) => emit(IncomingError(failure.message)),
      (incomingList) => emit(IncomingLoaded(incomingList)),
    );
  }

  Future<void> _onCreateIncoming(
    CreateIncoming event,
    Emitter<IncomingState> emit,
  ) async {
    emit(const IncomingLoading());

    final result = await createIncomingUseCase(
      CreateIncomingParams(
        description: event.description,
        amountUsd: event.amountUsd,
        transactionDate: event.transactionDate,
      ),
    );

    await result.fold(
      (failure) async => emit(IncomingError(failure.message)),
      (incoming) async {
        emit(const IncomingOperationSuccess('Incoming transaction created successfully'));
        // Reload the list
        add(const LoadIncoming());
      },
    );
  }

  Future<void> _onUpdateIncoming(
    UpdateIncoming event,
    Emitter<IncomingState> emit,
  ) async {
    emit(const IncomingLoading());

    final result = await updateIncomingUseCase(event.incoming);

    await result.fold(
      (failure) async => emit(IncomingError(failure.message)),
      (_) async {
        emit(const IncomingOperationSuccess('Incoming transaction updated successfully'));
        // Reload the list
        add(const LoadIncoming());
      },
    );
  }

  Future<void> _onDeleteIncoming(
    DeleteIncoming event,
    Emitter<IncomingState> emit,
  ) async {
    emit(const IncomingLoading());

    final result = await deleteIncomingUseCase(
      DeleteIncomingParams(
        id: event.id,
        refund: event.refund,
      ),
    );

    await result.fold(
      (failure) async => emit(IncomingError(failure.message)),
      (_) async {
        emit(const IncomingOperationSuccess('Incoming transaction deleted successfully'));
        // Reload the list
        add(const LoadIncoming());
      },
    );
  }
}
