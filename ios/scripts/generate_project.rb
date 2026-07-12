#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'xcodeproj'

root = File.expand_path('..', __dir__)
project_path = File.join(root, 'Caltrack.xcodeproj')
FileUtils.rm_rf(project_path)

project = Xcodeproj::Project.new(project_path)
project.root_object.attributes['LastSwiftUpdateCheck'] = '2600'
project.root_object.attributes['LastUpgradeCheck'] = '2600'

app = project.new_target(:application, 'Caltrack', :ios, '17.0')
tests = project.new_target(:unit_test_bundle, 'CaltrackTests', :ios, '17.0')
tests.add_dependency(app)
ui_tests = project.new_target(:ui_test_bundle, 'CaltrackUITests', :ios, '17.0')
ui_tests.add_dependency(app)

app_intents = project.frameworks_group.new_file('System/Library/Frameworks/AppIntents.framework')
app_intents.source_tree = 'SDKROOT'
[app, tests, ui_tests].each { |target| target.frameworks_build_phase.add_file_reference(app_intents) }

app_group = project.main_group.new_group('Caltrack', 'Caltrack')
source_refs = Dir[File.join(root, 'Caltrack', '*.swift')].sort.map { |path| app_group.new_file(File.basename(path)) }
app.add_file_references(source_refs)
assets = app_group.new_file('Assets.xcassets')
app.resources_build_phase.add_file_reference(assets)
app_group.new_file('Caltrack.entitlements')

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
  settings['CURRENT_PROJECT_VERSION'] = '3'
  settings['DEVELOPMENT_TEAM'] = '6BG94RDHDG'
  settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  settings['INFOPLIST_KEY_CFBundleDisplayName'] = 'Caltrack'
  settings['INFOPLIST_KEY_NSCameraUsageDescription'] = 'Caltrack usa la cámara para analizar una comida cuando decides fotografiarla.'
  settings['INFOPLIST_KEY_NSHealthShareUsageDescription'] = 'Caltrack lee el peso, la composición corporal, la actividad y los entrenamientos que autorices para reunir tu progreso en un solo lugar.'
  settings['INFOPLIST_KEY_NSHealthUpdateUsageDescription'] = 'Caltrack guarda en Salud las calorías y macros de las comidas que confirmes cuando activas esta opción.'
  settings['INFOPLIST_KEY_UIApplicationSceneManifest_Generation'] = 'YES'
  settings['INFOPLIST_KEY_UILaunchScreen_Generation'] = 'YES'
  settings['INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone'] = 'UIInterfaceOrientationPortrait'
  settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  settings['MARKETING_VERSION'] = '1.2'
  settings['LM_FILTER_WARNINGS'] = 'YES'
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.manuelsampedro.caltrack'
  settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
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
    'SystemCapabilities' => { 'com.apple.HealthKit' => { 'enabled' => 1 } }
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
