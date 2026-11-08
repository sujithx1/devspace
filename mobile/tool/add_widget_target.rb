# Adds the DevSpaceWidgets WidgetKit extension to ios/Runner.xcodeproj and
# wires the shared App Group code into both targets. Safe to re-run.
#
#   GEM_HOME=$(brew --prefix cocoapods)/libexec ruby tool/add_widget_target.rb
require 'xcodeproj'

ios = File.expand_path('../ios', __dir__)
project = Xcodeproj::Project.open(File.join(ios, 'Runner.xcodeproj'))
runner = project.targets.find { |t| t.name == 'Runner' }
team = runner.build_configurations.map { |c| c.build_settings['DEVELOPMENT_TEAM'] }.compact.first

def group_for(project, name)
  project.main_group.groups.find { |g| g.display_name == name } || project.main_group.new_group(name, name)
end

def add_files(group, target_list, names)
  names.map do |name|
    ref = group.files.find { |f| f.path == name } || group.new_reference(name)
    target_list.each do |t|
      t.source_build_phase.add_file_reference(ref, true) if name.end_with?('.swift')
    end
    ref
  end
end

widget = project.targets.find { |t| t.name == 'DevSpaceWidgets' }
unless widget
  widget = project.new_target(:app_extension, 'DevSpaceWidgets', :ios, '17.0', nil, :swift)
end

# Flutter's xcconfigs give the extension the same version numbers as the app.
flutter_group = project.main_group.groups.find { |g| g.display_name == 'Flutter' }
widget.build_configurations.each do |config|
  xcconfig = config.name == 'Debug' ? 'Debug.xcconfig' : 'Release.xcconfig'
  config.base_configuration_reference = flutter_group.files.find { |f| File.basename(f.path) == xcconfig }
  s = config.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'tech.magadh.devspace.DevSpaceWidgets'
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['INFOPLIST_FILE'] = 'DevSpaceWidgets/Info.plist'
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['CODE_SIGN_ENTITLEMENTS'] = 'DevSpaceWidgets/DevSpaceWidgets.entitlements'
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['DEVELOPMENT_TEAM'] = team if team
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  s['TARGETED_DEVICE_FAMILY'] = '1'
  s['SWIFT_VERSION'] = '5.0'
  s['SKIP_INSTALL'] = 'YES'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  s['SWIFT_EMIT_LOC_STRINGS'] = 'YES'
end

runner.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

widget_group = group_for(project, 'DevSpaceWidgets')
add_files(widget_group, [widget], %w[
  DevSpaceWidgets.swift DevSpaceProvider.swift DayModel.swift WidgetStyle.swift WidgetConfiguration.swift
  TodayTasksWidget.swift ProjectWidget.swift ProductivityWidget.swift QuickCaptureWidget.swift
  UpcomingDeadlinesWidget.swift DevSpaceControls.swift
  Info.plist DevSpaceWidgets.entitlements
])

shared_group = group_for(project, 'Shared')
add_files(shared_group, [runner, widget], %w[DevSpaceShared.swift WidgetModels.swift DevSpaceIntents.swift])

runner_group = project.main_group.groups.find { |g| g.display_name == 'Runner' }
add_files(runner_group, [runner], %w[WidgetBridge.swift AppShortcuts.swift])
runner_group.files.find { |f| f.path == 'Runner.entitlements' } || runner_group.new_reference('Runner.entitlements')

%w[WidgetKit SwiftUI].each do |fw|
  path = "System/Library/Frameworks/#{fw}.framework"
  ref = project.frameworks_group.files.find { |f| f.path == path } ||
        project.frameworks_group.new_reference(path).tap { |r| r.source_tree = 'SDKROOT' }
  widget.frameworks_build_phase.add_file_reference(ref, true)
end

runner.add_dependency(widget) unless runner.dependencies.any? { |d| d.target == widget }

# Embed the extension. It must come before Flutter's "Thin Binary" script,
# or Xcode reports a dependency cycle.
embed = runner.copy_files_build_phases.find { |p| p.name == 'Embed Foundation Extensions' }
unless embed
  embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
  embed.symbol_dst_subfolder_spec = :plug_ins
end
unless embed.files_references.include?(widget.product_reference)
  build_file = embed.add_file_reference(widget.product_reference, true)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end
thin = runner.build_phases.find { |p| p.respond_to?(:name) && p.name == 'Thin Binary' }
if thin
  runner.build_phases.delete(embed)
  runner.build_phases.insert(runner.build_phases.index(thin), embed)
end

project.save
puts "DevSpaceWidgets target ready (team: #{team || 'none'})"
