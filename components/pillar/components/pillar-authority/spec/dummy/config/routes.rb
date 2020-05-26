require "pillar/authority/engine"

Rails.application.routes.draw do
  mount Pillar::Authority::Engine, at: "authority"
end
