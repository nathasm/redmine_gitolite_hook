ActionController::Routing::Routes.draw do |map|
  map.connect 'gitolite_hook', :controller => 'gitolite_hook', :action => 'index',
              :conditions => {:method => :post}
end
