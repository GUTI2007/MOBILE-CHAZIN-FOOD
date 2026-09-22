import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/api/api_client.dart';
import '../../../shared/models/event_model.dart';
import '../data/events_repository.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EventsRepository(apiClient);
});

class EventsState {
  final List<Event> events;
  final bool isLoading;
  final String? error;

  const EventsState({
    this.events = const [],
    this.isLoading = false,
    this.error,
  });

  EventsState copyWith({
    List<Event>? events,
    bool? isLoading,
    String? error,
  }) {
    return EventsState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class EventsNotifier extends StateNotifier<EventsState> {
  final EventsRepository _repository;

  EventsNotifier(this._repository) : super(const EventsState()) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final events = await _repository.getEvents();
      state = state.copyWith(events: events, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createEvent(Event event) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final created = await _repository.createEvent(event);
      state = state.copyWith(
        events: [...state.events, created],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteEvent(int id) async {
    try {
      final ok = await _repository.deleteEvent(id);
      if (ok) {
        state = state.copyWith(
          events: state.events.where((e) => e.id != id).toList(),
        );
      }
      return ok;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final eventsProvider = StateNotifierProvider<EventsNotifier, EventsState>((ref) {
  final repository = ref.watch(eventsRepositoryProvider);
  return EventsNotifier(repository);
});
