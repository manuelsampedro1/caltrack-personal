#!/usr/bin/env ruby
# frozen_string_literal: true

ENV["SSL_CERT_FILE"] ||= "/etc/ssl/cert.pem"

require "spaceship"

ROOT = File.expand_path("../..", __dir__)
BUNDLE_ID = "com.manuelsampedro.caltrack"
VERSION = "1.11"
BUILD_NUMBER = "13"
LOCALE = "es-ES"
DISPLAY_TYPE = "APP_IPHONE_65"
SCREENSHOTS_DIR = File.join(ROOT, "ios", "app_store", "screenshots", LOCALE, DISPLAY_TYPE)

def connect!
  required = %w[ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_PATH]
  missing = required.reject { |name| ENV[name] && !ENV[name].empty? }
  raise "Faltan variables ASC externas: #{missing.join(', ')}" unless missing.empty?

  token = Spaceship::ConnectAPI::Token.create(
    key_id: ENV.fetch("ASC_KEY_ID"),
    issuer_id: ENV.fetch("ASC_ISSUER_ID"),
    filepath: ENV.fetch("ASC_KEY_PATH")
  )
  Spaceship::ConnectAPI.token = token
end

def screenshot_paths
  paths = Dir.glob(File.join(SCREENSHOTS_DIR, "*.png")).sort
  raise "Se esperan entre 3 y 10 capturas" unless (3..10).cover?(paths.length)

  paths.each do |path|
    dimensions = `sips -g pixelWidth -g pixelHeight #{Shellwords.escape(path)} 2>/dev/null`
    next if dimensions.include?("pixelWidth: 1242") && dimensions.include?("pixelHeight: 2688")

    raise "Dimensiones no válidas: #{File.basename(path)}"
  end
  paths
end

def replace_screenshots!(localization, paths)
  set = localization.get_app_screenshot_sets.find { |item| item.screenshot_display_type == DISPLAY_TYPE }
  set ||= localization.create_app_screenshot_set(attributes: { screenshotDisplayType: DISPLAY_TYPE })

  existing = Spaceship::ConnectAPI::AppScreenshotSet.get(app_screenshot_set_id: set.id).app_screenshots || []
  existing.each(&:delete!)

  paths.each_with_index do |path, index|
    puts "  #{index + 1}/#{paths.length} #{File.basename(path)}"
    set.upload_screenshot(path: path, wait_for_processing: true)
  end

  refreshed = Spaceship::ConnectAPI::AppScreenshotSet.get(app_screenshot_set_id: set.id)
  remote_names = refreshed.app_screenshots.map(&:file_name)
  expected_names = paths.map { |path| File.basename(path) }
  raise "El orden remoto de capturas no coincide" unless remote_names == expected_names

  refreshed
end

def attach_build!(app, version)
  builds = app.get_builds(
    filter: {
      "preReleaseVersion.version" => VERSION,
      version: BUILD_NUMBER,
      processingState: "VALID"
    },
    includes: "buildBetaDetail",
    limit: 10
  )
  build = builds.find { |item| item.version == BUILD_NUMBER }
  raise "No se encontró la build válida #{VERSION} (#{BUILD_NUMBER})" unless build

  version.select_build(build_id: build.id)
  attached = version.get_build
  raise "La build no quedó vinculada a la versión" unless attached&.id == build.id

  build
end

begin
  require "shellwords"
  paths = screenshot_paths
  connect!

  app = Spaceship::ConnectAPI::App.find(BUNDLE_ID)
  raise "No existe la ficha de Caltrack" unless app

  version = app.get_edit_app_store_version(platform: "IOS", includes: nil)
  raise "No existe una versión editable" unless version&.version_string == VERSION
  raise "La versión no usa lanzamiento manual" unless version.release_type == "MANUAL"

  localization = version.get_app_store_version_localizations.find { |item| item.locale == LOCALE }
  raise "No existe la localización #{LOCALE}" unless localization

  puts "Reemplazando capturas de App Store"
  screenshot_set = replace_screenshots!(localization, paths)
  puts "Vinculando build #{VERSION} (#{BUILD_NUMBER})"
  build = attach_build!(app, version)

  puts "Ficha finalizada: screenshots=#{screenshot_set.app_screenshots.length} build_id=#{build.id} estado=#{version.app_store_state}"
rescue StandardError => error
  warn "No se pudo finalizar la ficha: #{error.class}: #{error.message}"
  exit 1
end
