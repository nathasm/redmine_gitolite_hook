require 'redmine'

Redmine::Plugin.register :redmine_gitolite_hook do
  name 'Redmine Gitolite Hook plugin'
  author 'Phlegx Systems'
  description 'This plugin allows your Redmine installation to receive Gitolite post-receive notifications'
  version '0.0.1'
  url 'https://github.com/phlegx/redmine_gitolite_hook'
  author_url 'https://github.com/phlegx'
  
  settings :default => { :all_branches => "yes" }, :partial => 'settings/gitolite_settings'
end
