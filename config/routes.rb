RedmineApp::Application.routes.draw do
  match 'gitolite_hook' => 'gitolite_hook#index', :via => [:post]
end
