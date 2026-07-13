#!/usr/bin/env ruby
# frozen_string_literal: true

ENV["SSL_CERT_FILE"] ||= "/etc/ssl/cert.pem"

require "json"
require "spaceship"

ROOT = File.expand_path("../..", __dir__)
BUNDLE_ID = "com.manuelsampedro.caltrack"
VERSION = "1.11"
LOCALE = "es-ES"
METADATA_DIR = File.join(ROOT, "ios", "app_store", "metadata", LOCALE)

def read_metadata(name)
  File.read(File.join(METADATA_DIR, name), encoding: "UTF-8").strip
end

def validate_metadata!
  limits = {
    "name.txt" => 30,
    "subtitle.txt" => 30,
    "promotional_text.txt" => 170,
    "keywords.txt" => 100,
    "description.txt" => 4_000,
    "release_notes.txt" => 4_000
  }

  limits.each do |name, limit|
    value = read_metadata(name)
    raise "#{name} está vacío" if value.empty?
    raise "#{name} supera #{limit} caracteres" if value.length > limit
    raise "#{name} contiene un guion no permitido" if value.match?(/[\u2013\u2014]/)
  end
end

def connect!
  required = %w[ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_PATH]
  missing = required.reject { |name| ENV[name] && !ENV[name].empty? }
  raise "Faltan variables ASC externas" unless missing.empty?

  token = Spaceship::ConnectAPI::Token.create(
    key_id: ENV.fetch("ASC_KEY_ID"),
    issuer_id: ENV.fetch("ASC_ISSUER_ID"),
    filepath: ENV.fetch("ASC_KEY_PATH")
  )
  Spaceship::ConnectAPI.token = token
end

def review_contact_for(caltrack)
  Spaceship::ConnectAPI::App.all(includes: nil, limit: 50).each do |candidate|
    next if candidate.id == caltrack.id

    begin
      version = candidate.get_latest_app_store_version(platform: "IOS", includes: "appStoreReviewDetail")
      detail = version&.fetch_app_store_review_detail(includes: nil)
      values = [detail&.contact_first_name, detail&.contact_last_name, detail&.contact_phone, detail&.contact_email]
      return detail if values.all? { |value| value && !value.empty? }
    rescue StandardError
      next
    end
  end

  raise "No hay un contacto de revisión completo en las apps existentes"
end

def configure_store_metadata!(app, contact)
  app.ensure_version!(VERSION, platform: "IOS")
  version = app.get_edit_app_store_version(platform: "IOS", includes: nil)
  info = app.fetch_edit_app_info
  raise "No existe una versión editable" unless version
  raise "No existe información editable" unless info

  version.update(attributes: {
    copyright: File.read(File.join(ROOT, "ios", "app_store", "metadata", "copyright.txt"), encoding: "UTF-8").strip,
    release_type: Spaceship::ConnectAPI::AppStoreVersion::ReleaseType::MANUAL
  })

  info_localization = info.get_app_info_localizations.find { |item| item.locale == LOCALE }
  raise "No existe la localización #{LOCALE} de información" unless info_localization

  info_localization.update(attributes: {
    name: read_metadata("name.txt"),
    subtitle: read_metadata("subtitle.txt"),
    privacy_policy_url: read_metadata("privacy_url.txt"),
    privacy_choices_url: read_metadata("privacy_url.txt")
  })

  info.update_categories(category_id_map: {
    primary_category_id: "HEALTH_AND_FITNESS",
    secondary_category_id: "FOOD_AND_DRINK"
  })

  app.update(attributes: {
    content_rights_declaration: Spaceship::ConnectAPI::App::ContentRightsDeclaration::USES_THIRD_PARTY_CONTENT
  })

  localization = version.get_app_store_version_localizations.find { |item| item.locale == LOCALE }
  localization ||= version.create_app_store_version_localization(attributes: { locale: LOCALE })
  localization.update(attributes: {
    description: read_metadata("description.txt"),
    keywords: read_metadata("keywords.txt"),
    marketing_url: read_metadata("marketing_url.txt"),
    promotional_text: read_metadata("promotional_text.txt"),
    support_url: read_metadata("support_url.txt"),
    whats_new: read_metadata("release_notes.txt")
  })

  rating = info.fetch_age_rating_declaration
  rating.update(attributes: {
    alcohol_tobacco_or_drug_use_or_references: "NONE",
    contests: "NONE",
    gambling_simulated: "NONE",
    guns_or_other_weapons: "NONE",
    horror_or_fear_themes: "NONE",
    mature_or_suggestive_themes: "NONE",
    medical_or_treatment_information: "NONE",
    profanity_or_crude_humor: "NONE",
    sexual_content_graphic_and_nudity: "NONE",
    sexual_content_or_nudity: "NONE",
    violence_cartoon_or_fantasy: "NONE",
    violence_realistic_prolonged_graphic_or_sadistic: "NONE",
    violence_realistic: "NONE",
    advertising: false,
    age_assurance: false,
    gambling: false,
    health_or_wellness_topics: true,
    loot_box: false,
    messaging_and_chat: true,
    parental_controls: false,
    unrestricted_web_access: false,
    user_generated_content: false,
    age_rating_override_v2: "NONE",
    korea_age_rating_override: "NONE"
  })

  review_attributes = {
    contact_first_name: contact.contact_first_name,
    contact_last_name: contact.contact_last_name,
    contact_phone: contact.contact_phone,
    contact_email: contact.contact_email,
    demo_account_required: false,
    notes: File.read(File.join(ROOT, "ios", "app_store", "review_notes.txt"), encoding: "UTF-8").strip
  }
  review = version.fetch_app_store_review_detail(includes: nil)
  review ? review.update(attributes: review_attributes) : version.create_app_store_review_detail(attributes: review_attributes)

  [version, info]
end

def configure_testflight_metadata!(app, contact)
  attributes = {
    feedbackEmail: contact.contact_email,
    marketingUrl: read_metadata("marketing_url.txt"),
    privacyPolicyUrl: read_metadata("privacy_url.txt"),
    description: read_metadata("description.txt"),
    locale: LOCALE
  }

  localization = app.get_beta_app_localizations.find { |item| item.locale == LOCALE }
  if localization
    Spaceship::ConnectAPI.patch_beta_app_localizations(localization_id: localization.id, attributes: attributes.reject { |key, _| key == :locale })
  else
    Spaceship::ConnectAPI.post_beta_app_localizations(app_id: app.id, attributes: attributes)
  end

  Spaceship::ConnectAPI.patch_beta_app_review_detail(app_id: app.id, attributes: {
    contactFirstName: contact.contact_first_name,
    contactLastName: contact.contact_last_name,
    contactPhone: contact.contact_phone,
    contactEmail: contact.contact_email,
    demoAccountRequired: false,
    notes: File.read(File.join(ROOT, "ios", "app_store", "review_notes.txt"), encoding: "UTF-8").strip
  })
end

def configure_privacy!(app)
  config_path = File.join(ROOT, "ios", "app_store", "app_privacy_details.json")
  config = JSON.parse(File.read(config_path, encoding: "UTF-8"))

  Spaceship::ConnectAPI::AppDataUsage.all(
    app_id: app.id,
    includes: "category,grouping,purpose,dataProtection",
    limit: 500
  ).each(&:delete!)

  config.each do |usage|
    usage.fetch("purposes").each do |purpose|
      usage.fetch("data_protections").each do |protection|
        Spaceship::ConnectAPI::AppDataUsage.create(
          app_id: app.id,
          app_data_usage_category_id: usage.fetch("category"),
          app_data_usage_protection_id: protection,
          app_data_usage_purpose_id: purpose
        )
      end
    end
  end

  publish_state = Spaceship::ConnectAPI::AppDataUsagesPublishState.get(app_id: app.id)
  publish_state.publish! unless publish_state.published
end

def verify!(app)
  version = app.get_edit_app_store_version(platform: "IOS", includes: nil)
  info = app.fetch_edit_app_info
  info_localization = info.get_app_info_localizations.find { |item| item.locale == LOCALE }
  version_localization = version.get_app_store_version_localizations.find { |item| item.locale == LOCALE }
  privacy_usages = Spaceship::ConnectAPI::AppDataUsage.all(
    app_id: app.id,
    includes: "category,grouping,purpose,dataProtection",
    limit: 500
  )

  checks = {
    version: version.version_string == VERSION,
    release_manual: version.release_type == Spaceship::ConnectAPI::AppStoreVersion::ReleaseType::MANUAL,
    name: info_localization.name == read_metadata("name.txt"),
    subtitle: info_localization.subtitle == read_metadata("subtitle.txt"),
    privacy_url: info_localization.privacy_policy_url == read_metadata("privacy_url.txt"),
    description: version_localization.description == read_metadata("description.txt"),
    keywords: version_localization.keywords == read_metadata("keywords.txt"),
    support_url: version_localization.support_url == read_metadata("support_url.txt"),
    privacy_answers: privacy_usages.any?
  }

  failed = checks.reject { |_, value| value }.keys
  raise "Falló la verificación: #{failed.join(', ')}" unless failed.empty?

  puts "App Store configurado: app_id=#{app.id} version=#{version.version_string} locale=#{LOCALE}"
  puts "Metadatos, categoría, edad, revisión, TestFlight y privacidad verificados"
end

begin
  validate_metadata!
  connect!
  app = Spaceship::ConnectAPI::App.find(BUNDLE_ID)
  raise "No existe la ficha de Caltrack" unless app

  contact = review_contact_for(app)
  configure_store_metadata!(app, contact)
  configure_testflight_metadata!(app, contact)
  configure_privacy!(app)
  verify!(app)
rescue StandardError => error
  warn "No se pudo configurar App Store Connect: #{error.class}"
  exit 1
end
