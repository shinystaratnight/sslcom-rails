Pillar::Authority::Engine.routes.draw do
  root to: "application#show"

  namespace :admin do
    resources :blocklist_entries
  end
end
