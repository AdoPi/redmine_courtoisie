
Rails.logger.info 'Loading Redmine Courtoisie Plugin'
loader = RedminePluginKit::Loader.new plugin_id: 'redmine_messenger'

Redmine::Plugin.register :redmine_courtoisie do
  name 'Redmine Courtoisie Plugin'
  author 'AdoPi'
  description 'Rewrites issue titles and descriptions to make them more polite'
  version '0.0.1'
  settings partial: 'settings/courtoisie_settings', default: {
    'members_to_courtesy' => [], # ids
    'gemini_api_key' => 'TODO',
    'model' => 'gemini-2.0-flash',
    'max_chars' => 3000
  }
end


RedminePluginKit::Loader.persisting { loader.load_model_hooks! }