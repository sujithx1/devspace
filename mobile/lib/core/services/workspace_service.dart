import '../errors/app_exception.dart';
import '../models/enums.dart';
import '../models/workspace.dart';
import '../repositories/preferences_repository.dart';
import '../repositories/workspace_repository.dart';

/// Workspace business rules that span repositories: which workspace is active,
/// and that there is always at least one.
class WorkspaceService {
  WorkspaceService(this._workspaces, this._preferences);

  final WorkspaceRepository _workspaces;
  final PreferencesRepository _preferences;

  /// Creates a workspace and makes it the active one.
  Future<Workspace> create({required String name, String? icon}) async {
    final workspace = await _workspaces.create(name: name, icon: icon, type: WorkspaceType.personal);
    await switchTo(workspace.id);
    return workspace;
  }

  Future<Workspace> update(String id, {String? name, String? icon}) => _workspaces.update(id, name: name, icon: icon);

  Future<void> switchTo(String id) => _preferences.set(PreferenceKey.activeWorkspaceId, id);

  /// Deletes a workspace and everything in it. The last workspace can't be
  /// deleted; if the active one is removed, the oldest remaining becomes active.
  Future<void> delete(String id) async {
    final all = await _workspaces.getAll();
    if (all.length <= 1) {
      throw const ValidationException('You need at least one workspace. Create another before deleting this one.');
    }
    final activeId = await _preferences.get(PreferenceKey.activeWorkspaceId);
    await _workspaces.delete(id);
    if (activeId == id || activeId == null) {
      await switchTo(all.firstWhere((w) => w.id != id).id);
    }
  }
}
