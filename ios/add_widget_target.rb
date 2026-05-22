#!/usr/bin/env ruby
# Adds a WidgetKit extension target (LoopifyWidget) to Runner.xcodeproj.
# Idempotent: safe to re-run.

require 'xcodeproj'

PROJECT_PATH = File.expand_path('Runner.xcodeproj', __dir__)
WIDGET_DIR   = 'LoopifyWidget'
TARGET_NAME  = 'LoopifyWidget'
BUNDLE_ID    = 'com.loopify.loopify.LoopifyWidget'
APP_GROUP    = 'group.com.loopify.loopify'

project = Xcodeproj::Project.open(PROJECT_PATH)
runner  = project.targets.find { |t| t.name == 'Runner' } or abort 'Runner target not found'

# ---- 1. Create / find widget target ---------------------------------------
widget = project.targets.find { |t| t.name == TARGET_NAME }
if widget.nil?
  widget = project.new_target(
    :app_extension,
    TARGET_NAME,
    :ios,
    '14.0',
    nil,
    :swift
  )
  puts "  + created target #{TARGET_NAME}"
else
  puts "  = target #{TARGET_NAME} already exists"
end

# ---- 2. Group for files in the project navigator --------------------------
widget_group = project.main_group[WIDGET_DIR] ||
               project.main_group.new_group(WIDGET_DIR, WIDGET_DIR)

def ensure_ref(group, path)
  group.files.find { |f| f.path == path } || group.new_file(path)
end

swift_ref     = ensure_ref(widget_group, 'LoopifyWidget.swift')
plist_ref     = ensure_ref(widget_group, 'Info.plist')
ents_ref      = ensure_ref(widget_group, 'LoopifyWidget.entitlements')
assets_ref    = ensure_ref(widget_group, 'Assets.xcassets')

# ---- 3. Wire build phases -------------------------------------------------
src_phase = widget.source_build_phase
src_phase.add_file_reference(swift_ref) unless src_phase.files_references.include?(swift_ref)

res_phase = widget.resources_build_phase
res_phase.add_file_reference(assets_ref) unless res_phase.files_references.include?(assets_ref)

# Shared keychain store — added to BOTH Runner and LoopifyWidget targets so the
# app writes and the widget reads through the same code path.
shared_group = project.main_group['Shared'] || project.main_group.new_group('Shared', 'Shared')
shared_ref = shared_group.files.find { |f| f.path == 'WidgetKeychainStore.swift' } ||
             shared_group.new_file('WidgetKeychainStore.swift')

[runner, widget].each do |t|
  phase = t.source_build_phase
  phase.add_file_reference(shared_ref) unless phase.files_references.include?(shared_ref)
end

# ---- 4. Build settings for widget target ----------------------------------
widget.build_configurations.each do |cfg|
  s = cfg.build_settings
  s['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
  s['ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME'] = 'WidgetBackground'
  s['CLANG_ANALYZER_NONNULL'] = 'YES'
  s['CLANG_CXX_LANGUAGE_STANDARD'] = 'gnu++17'
  s['CLANG_ENABLE_OBJC_WEAK'] = 'YES'
  s['CODE_SIGN_ENTITLEMENTS'] = "#{WIDGET_DIR}/LoopifyWidget.entitlements"
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['CURRENT_PROJECT_VERSION'] = '1'
  s['DEBUG_INFORMATION_FORMAT'] = cfg.name == 'Debug' ? 'dwarf' : 'dwarf-with-dsym'
  s['DEVELOPMENT_TEAM'] = ''
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['INFOPLIST_FILE'] = "#{WIDGET_DIR}/Info.plist"
  s['INFOPLIST_KEY_CFBundleDisplayName'] = 'Loopify'
  s['INFOPLIST_KEY_NSHumanReadableCopyright'] = ''
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  s['MARKETING_VERSION'] = '1.0'
  s['MTL_FAST_MATH'] = 'YES'
  s['PRODUCT_BUNDLE_IDENTIFIER'] = BUNDLE_ID
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['SKIP_INSTALL'] = 'YES'
  s['SWIFT_EMIT_LOC_STRINGS'] = 'YES'
  s['SWIFT_VERSION'] = '5.0'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['CODE_SIGNING_ALLOWED'] = 'NO'   # Flutter --no-codesign flow
  s['CODE_SIGNING_REQUIRED'] = 'NO'
end

# ---- 5. Embed widget into Runner ------------------------------------------
embed_phase = runner.copy_files_build_phases.find { |p| p.name == 'Embed App Extensions' }
if embed_phase.nil?
  embed_phase = runner.new_copy_files_build_phase('Embed App Extensions')
  embed_phase.symbol_dst_subfolder_spec = :plug_ins
  puts '  + added Embed App Extensions phase to Runner'
end

# Move Embed App Extensions before any shell script phases to avoid Flutter's
# "Cycle inside Runner" (Thin Binary + Embed Pods Frameworks run after).
first_script_idx = runner.build_phases.index { |p| p.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) }
embed_idx = runner.build_phases.index(embed_phase)
if first_script_idx && embed_idx && embed_idx > first_script_idx
  runner.build_phases.delete(embed_phase)
  runner.build_phases.insert(first_script_idx, embed_phase)
  puts '  + reordered: Embed App Extensions placed before script phases'
end

widget_product = widget.product_reference
unless embed_phase.files_references.include?(widget_product)
  build_file = embed_phase.add_file_reference(widget_product)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end

# Make Runner depend on widget so it builds first
unless runner.dependencies.any? { |d| d.target == widget }
  runner.add_dependency(widget)
  puts '  + Runner now depends on LoopifyWidget'
end

# ---- 6. Wire entitlements on Runner ---------------------------------------
runner.build_configurations.each do |cfg|
  cfg.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

# Make sure Runner.entitlements is in the project tree (cosmetic — Xcode shows it)
runner_group = project.main_group['Runner']
if runner_group && !runner_group.files.any? { |f| f.path == 'Runner.entitlements' }
  runner_group.new_file('Runner.entitlements')
end

project.save
puts "\n  ✔ saved #{PROJECT_PATH}"
