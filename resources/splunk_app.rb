# frozen_string_literal: true
# Cookbook Name:: cerner_splunk_ingredient
# Resource:: splunk_app
#
# Resource for installing and configuring Splunk apps

class SplunkApp < Chef::Resource
  include CernerSplunk::PlatformHelpers, CernerSplunk::PathHelpers, CernerSplunk::ResourceHelpers

  property :name, String, name_property: true, identity: true
  property :install_dir, String, required: true, desired_state: false
  property :package, [:splunk, :universal_forwarder], required: true, desired_state: false
  property :app_root, [String, :shcluster, :master_apps], default: 'apps', desired_state: false
  property :version, [String, CernerSplunk::SplunkVersion]
  property :configs, Proc
  property :files, Proc
  property :metadata, Hash, default: {}

  resource_name :splunk_app

  default_action :install

  def after_created
    version CernerSplunk::SplunkVersion.from_string(version) if version && version.is_a?(String)
  end

  def install_state
    unless @install_exists
      raise 'Attempted to reference service for Splunk installation that does not exist' unless load_installation_state
      @install_exists = true
    end

    node.run_state['splunk_ingredient']['installations'][install_dir]
  end

  def absolute_app_root
    root_path = case app_root
                when :master_apps then 'master-apps/apps'
                when :shcluster then 'shcluster/apps'
                else app_root
                end

    # Joining pathnames acts like `cd`, so if root_path is absolute, that becomes the new path.
    Pathname.new(install_dir) + 'etc' + root_path
  end

  def app_path
    @app_path ||= Pathname.new(absolute_app_root) + name
  end

  def config_scope
    @config_scope ||= (resource_name == :splunk_app_custom ? 'default' : 'local')
  end

  def parse_meta_access(access)
    return access unless access.is_a? Hash
    access_read = Array(access[:read] || access['read']).join(', ')
    access_write = Array(access[:write] || access['write']).join(', ')
    "read : [ #{access_read} ], write : [ #{access_write} ]"
  end

  load_current_value do |desired|
    if property_is_set? :install_dir
      install_dir desired.install_dir
      package desired.package = install_state['package']
    else
      current_state = node.run_state['splunk_ingredient']['current_installation'] || {}
      desired.package = current_state['package'] unless property_is_set? :package
      package desired.package
      install_dir desired.install_dir = (current_state['path'] || default_install_dir)
      install_state
    end

    app_conf = CernerSplunk::ConfHelpers.read_config(app_path + 'default/app.conf')
    app_version = (app_conf['launcher'] ||= {})['version']
    if app_version
      raise 'Version to install must be specified when app has a version.' unless desired.version
      version CernerSplunk::SplunkVersion.from_string(app_version)

      # Check that a pre-release version isn't being installed over a similar release version.
      raise "Attempted to install pre-release version over release version (#{desired.version} vs. #{version})" if desired.version.prerelease? && !version.prerelease?
    end
  end

  # Provider exclusive methods

  action_class do
    require 'fileutils'
    include CernerSplunk::ProviderHelpers
    include CernerSplunk::ProviderHelpers::AppUpgrade

    def apply_config
      node.run_state['splunk_ingredient']['conf_override'] = {
        conf_path: (Pathname.new('apps') + name + config_scope).to_s,
        install_dir: install_dir,
        scope: :none
      }

      instance_eval(&configs) if property_is_set?(:configs)
      node.run_state['splunk_ingredient']['conf_override'] = {}

      instance_exec(app_path.to_s, &files) if property_is_set?(:files)

      metadata.each do |_, props|
        access = props.delete(:access) || props.delete('access')
        props['access'] = parse_meta_access(access) unless access.to_s.empty?
      end if property_is_set?(:metadata)

      splunk_conf((Pathname.new('apps') + "#{name}/metadata/#{config_scope}.meta").to_s) do
        scope :none
        config metadata
        reset true
      end
    end
  end

  ### Inherited Actions

  action :uninstall do
    directory app_path.to_s do
      recursive true
      action :delete
    end
  end
end

###################################
### Platform Specific Resources ###
###################################

class CustomApp < SplunkApp
  resource_name :splunk_app_custom

  action :install do
    return unless !version || changed?(:version)

    directory app_path.to_s do
      user current_owner
      group current_owner
      action :create
    end

    %w(default local lookups metadata).each do |subdir|
      directory((app_path + subdir).to_s) do
        user current_owner
        group current_owner
        action :create
      end
    end

    apply_config
  end
end

class PackagedApp < SplunkApp
  property :source_url, String, required: true

  resource_name :splunk_app_package

  action :install do
    return unless !version || changed?(:version)

    package_path = app_cache_path + CernerSplunk::PathHelpers.filename_from_url(source_url).gsub(/.spl$/, '.tgz')

    remote_file package_path.to_s do
      source source_url
      show_progress true if defined? show_progress # Chef 12.9 feature
    end

    directory app_path.to_s do
      action :create
    end

    backup_app if changed? :version

    poise_archive package_path.to_s do
      destination((app_cache_path + 'new').to_s)
      user current_owner
      group current_owner
    end

    converge_by 'validating the extracted app' do
      validate_extracted_app
    end

    ruby_block 'upgrade app' do
      block { upgrade_keep_existing }
      only_if { validate_versions }
    end

    apply_config
  end
end