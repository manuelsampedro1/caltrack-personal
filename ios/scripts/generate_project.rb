#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'digest'
require 'securerandom'
require 'xcodeproj'

# xcodeproj uses random identifiers by default, which rewrites the whole project
# on every regeneration. Stable identifiers keep reviews and future releases small.
uuid_index = 0
SecureRandom.define_singleton_method(:hex) do |bytes|
  uuid_index += 1
  Digest::SHA256.hexdigest("caltrack-xcodeproj-#{uuid_index}")[0, bytes * 2]
end

root = File.expand_path('..', __dir__)
project_path = File.join(root, 'Caltrack.xcodeproj')
FileUtils.rm_rf(project_path)

project = Xcodeproj::Project.new(project_path)
project.root_object.attributes['LastSwiftUpdateCheck'] = '2600'
project.root_object.attributes['LastUpgradeCheck'] = '2600'

app = project.new_target(:application, 'Caltrack', :ios, '17.0')
widget = project.new_target(:app_extension, 'CaltrackWidgets', :ios, '17.0')
app.add_dependency(widget)
tests = project.new_target(:unit_test_bundle, 'CaltrackTests', :ios, '17.0')
tests.add_dependency(app)
ui_tests = project.new_target(:ui_test_bundle, 'CaltrackUITests', :ios, '17.0')
ui_tests.add_dependency(app)

app_intents = project.frameworks_group.new_file('System/Library/Frameworks/AppIntents.framework')
app_intents.source_tree = 'SDKROOT'
[app, widget, tests, ui_tests].each { |target| target.frameworks_build_phase.add_file_reference(app_intents) }
widget_kit = project.frameworks_group.new_file('System/Library/Frameworks/WidgetKit.framework')
widget_kit.source_tree = 'SDKROOT'
[app, widget].each { |target| target.frameworks_build_phase.add_file_reference(widget_kit) }

app_group = project.main_group.new_group('Caltrack', 'Caltrack')
source_refs = Dir[File.join(root, 'Caltrack', '*.swift')].sort.map { |path| app_group.new_file(File.basename(path)) }
app.add_file_references(source_refs)
assets = app_group.new_file('Assets.xcassets')
app.resources_build_phase.add_file_reference(assets)
app_group.new_file('Caltrack.entitlements')

widget_group = project.main_group.new_group('CaltrackWidgets', 'CaltrackWidgets')
widget_refs = Dir[File.join(root, 'CaltrackWidgets', '*.swift')].sort.map { |path| widget_group.new_file(File.basename(path)) }
widget.add_file_references(widget_refs)
shared_widget_sources = source_refs.select do |ref|
  ['CaltrackWidgetContent.swift', 'QuickActions.swift', 'WidgetSnapshotStore.swift'].include?(ref.path)
end
widget.add_file_references(shared_widget_sources)
widget_group.new_file('Info.plist')
widget_group.new_file('CaltrackWidgets.entitlements')

embed_extensions = app.new_copy_files_build_phase('Embed App Extensions')
embed_extensions.symbol_dst_subfolder_spec = :plug_ins
embed_extensions.add_file_reference(widget.product_reference)

test_group = project.main_group.new_group('CaltrackTests', 'CaltrackTests')
test_refs = Dir[File.join(root, 'CaltrackTests', '*.swift')].sort.map { |path| test_group.new_file(File.basename(path)) }
tests.add_file_references(test_refs)

ui_test_group = project.main_group.new_group('CaltrackUITests', 'CaltrackUITests')
ui_test_refs = Dir[File.join(root, 'CaltrackUITests', '*.swift')].sort.map { |path| ui_test_group.new_file(File.basename(path)) }
ui_tests.add_file_references(ui_test_refs)

app.build_configurations.each do |config|
  settings = config.build_settings
  settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  settings['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
  settings['CODE_SIGN_ENTITLEMENTS'] = 'Caltrack/Caltrack.entitlements'
  settings['CODE_SIGN_STYLE'] = 'Automatic'
  settings['CURRENT_PROJECT_VERSION'] = '12'
  settings['DEVELOPMENT_TEAM'] = '6BG94RDHDG'
  settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  settings['INFOPLIST_KEY_CFBundleDisplayName'] = 'Caltrack'
  settings['INFOPLIST_KEY_NSCameraUsageDescription'] = 'Caltrack usa la cámara para analizar una comida cuando decides fotografiarla.'
  settings['INFOPLIST_KEY_NSHealthShareUsageDescription'] = 'Caltrack lee el peso, la composición corporal, la actividad, la recuperación y los entrenamientos que autorices para reunir tu progreso en un solo lugar.'
  settings['INFOPLIST_KEY_NSHealthUpdateUsageDescription'] = 'Caltrack guarda en Salud las calorías y macros de las comidas que confirmes cuando activas esta opción.'
  settings['INFOPLIST_KEY_UIApplicationSceneManifest_Generation'] = 'YES'
  settings['INFOPLIST_KEY_UILaunchScreen_Generation'] = 'YES'
  settings['INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone'] = 'UIInterfaceOrientationPortrait'
  settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  settings['MARKETING_VERSION'] = '1.11'
  settings['LM_FILTER_WARNINGS'] = 'YES'
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.manuelsampedro.caltrack'
  settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
  settings['SWIFT_EMIT_LOC_STRINGS'] = 'YES'
  settings['SWIFT_VERSION'] = '5.0'
  settings['TARGETED_DEVICE_FAMILY'] = '1'
end

widget.build_configurations.each do |config|
  settings = config.build_settings
  settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  settings['CODE_SIGN_ENTITLEMENTS'] = 'CaltrackWidgets/CaltrackWidgets.entitlements'
  settings['CODE_SIGN_STYLE'] = 'Automatic'
  settings['CURRENT_PROJECT_VERSION'] = '12'
  settings['DEVELOPMENT_TEAM'] = '6BG94RDHDG'
  settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  settings['INFOPLIST_FILE'] = 'CaltrackWidgets/Info.plist'
  settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
  settings['MARKETING_VERSION'] = '1.11'
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.manuelsampedro.caltrack.widgets'
  settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
  settings['SKIP_INSTALL'] = 'YES'
  settings['SWIFT_EMIT_LOC_STRINGS'] = 'YES'
  settings['SWIFT_VERSION'] = '5.0'
  settings['TARGETED_DEVICE_FAMILY'] = '1'
end

tests.build_configurations.each do |config|
  settings = config.build_settings
  settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
  settings['CODE_SIGN_STYLE'] = 'Automatic'
  settings['DEVELOPMENT_TEAM'] = '6BG94RDHDG'
  settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  settings['LM_FILTER_WARNINGS'] = 'YES'
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.manuelsampedro.caltrack.tests'
  settings['SWIFT_VERSION'] = '5.0'
  settings['TARGETED_DEVICE_FAMILY'] = '1'
  settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/Caltrack.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Caltrack'
end

ui_tests.build_configurations.each do |config|
  settings = config.build_settings
  settings['CODE_SIGN_STYLE'] = 'Automatic'
  settings['DEVELOPMENT_TEAM'] = '6BG94RDHDG'
  settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  settings['LM_FILTER_WARNINGS'] = 'YES'
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.manuelsampedro.caltrack.uitests'
  settings['SWIFT_VERSION'] = '5.0'
  settings['TARGETED_DEVICE_FAMILY'] = '1'
  settings['TEST_TARGET_NAME'] = 'Caltrack'
end

project.root_object.attributes['TargetAttributes'] = {
  app.uuid => {
    'CreatedOnToolsVersion' => '26.0',
    'DevelopmentTeam' => '6BG94RDHDG',
    'SystemCapabilities' => {
      'com.apple.ApplicationGroups.iOS' => { 'enabled' => 1 },
      'com.apple.HealthKit' => { 'enabled' => 1 }
    }
  },
  widget.uuid => {
    'CreatedOnToolsVersion' => '26.0',
    'DevelopmentTeam' => '6BG94RDHDG',
    'SystemCapabilities' => { 'com.apple.ApplicationGroups.iOS' => { 'enabled' => 1 } }
  },
  tests.uuid => {
    'CreatedOnToolsVersion' => '26.0',
    'DevelopmentTeam' => '6BG94RDHDG'
  },
  ui_tests.uuid => {
    'CreatedOnToolsVersion' => '26.0',
    'DevelopmentTeam' => '6BG94RDHDG'
  }
}

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.set_launch_target(app)
scheme.add_test_target(tests)
scheme.add_test_target(ui_tests)
scheme.save_as(project_path, 'Caltrack', true)

project.save
puts "Generated #{project_path}"
