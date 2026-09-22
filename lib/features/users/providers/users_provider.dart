import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';
import '../data/mock_users_repository.dart';

class UsersNotifier extends StateNotifier<List<User>> {
  UsersNotifier() : super(MockUsersRepository.getMockUsers());

  void addUser(User user) {
    state = [user, ...state];
  }

  void updateUser(User updatedUser) {
    state = [
      for (final user in state)
        if (user.id == updatedUser.id) updatedUser else user
    ];
  }

  void toggleStatus(String userId) {
    state = [
      for (final user in state)
        if (user.id == userId)
          user.copyWith(isActive: !user.isActive)
        else
          user
    ];
  }
}

final usersProvider = StateNotifierProvider<UsersNotifier, List<User>>((ref) {
  return UsersNotifier();
});

// Filters state
final userSearchQueryProvider = StateProvider<String>((ref) => '');
final userRoleFilterProvider = StateProvider<String>((ref) => 'Todos');
final userStatusFilterProvider = StateProvider<String>((ref) => 'Todos');

// Filtered Users Provider
final filteredUsersProvider = Provider<List<User>>((ref) {
  final users = ref.watch(usersProvider);
  final query = ref.watch(userSearchQueryProvider).toLowerCase().trim();
  final roleFilter = ref.watch(userRoleFilterProvider);
  final statusFilter = ref.watch(userStatusFilterProvider);

  return users.where((u) {
    // Search match
    final matchesQuery = query.isEmpty ||
        u.name.toLowerCase().contains(query) ||
        u.email.toLowerCase().contains(query) ||
        u.documento.contains(query);

    // Role match
    bool matchesRole = true;
    if (roleFilter != 'Todos') {
      matchesRole = u.roleName.toLowerCase() == roleFilter.toLowerCase();
    }

    // Status match
    bool matchesStatus = true;
    if (statusFilter == 'Activo') {
      matchesStatus = u.isActive;
    } else if (statusFilter == 'Inactivo') {
      matchesStatus = !u.isActive;
    }

    return matchesQuery && matchesRole && matchesStatus;
  }).toList();
});
