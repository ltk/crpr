Rails.application.routes.draw do
  root 'creeps#new'

  resources 'creeps', only: [:new, :create]
end
