Pillar::Pages::Engine.routes.draw do
  root to: "application#show"

  namespace :admin do
    root to: "dashboard#index"
  end
end
