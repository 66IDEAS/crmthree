Rails.application.routes.draw do
  resource :session, only: %i[new create destroy]
  get "access/pending", to: "access#pending", as: :access_pending
  get "password/reset", to: "password_resets#new", as: :new_password_reset
  post "password/reset", to: "password_resets#create", as: :password_resets
  get "password/reset/:token", to: "password_resets#edit", as: :edit_password_reset
  patch "password/reset/:token", to: "password_resets#update", as: :password_reset
  resource :profile, only: %i[show update]
  get "profile/:id", to: "profiles#show", as: :member_profile
  get "profile/:id/portfolio", to: "performance_portfolios#show", defaults: {format: :csv}, as: :performance_portfolio
  get "leaderboard", to: "leaderboards#show", as: :leaderboard
  get "my-timeline", to: "timelines#mine", as: :my_timeline
  get "team-timeline", to: "timelines#team", as: :team_timeline
  resource :dashboard_config, only: :update
  resources :deal_rooms, path: "deal-rooms", only: %i[index new create show] do
    member do
      patch :close
      patch :update_stage
    end
  end
  resources :case_rooms, path: "case-rooms", only: %i[index show] do
    member do
      patch :update_status
      post :link_knowledge
    end
  end
  post "workspaces/:workspace_type/:workspace_id/comments", to: "workspace_comments#create", as: :workspace_comments
  get "settings", to: "settings#index", as: :settings
  post "settings/gamification/initialize", to: "gamification_settings#initialize_defaults", as: :initialize_gamification
  patch "settings/gamification/:object_type/:id", to: "gamification_settings#update", as: :gamification_setting
  get "search", to: "search#index", as: :search
  post "assistant", to: "assistant#create", as: :assistant
  resources :briefings, only: :create
  post "briefings/coaching/:opportunity_id", to: "briefings#coaching", as: :coaching_briefing
  post "briefings/performance/:profile_id", to: "briefings#performance", as: :performance_briefing
  resources :intake_drafts, path: "intake", only: %i[index create show] do
    member do
      post :apply
      post :reject
    end
  end
  post "records/Opportunity/:opportunity_id/knowledge-draft", to: "knowledge_drafts#create", as: :opportunity_knowledge_draft
  resources :duplicate_links, path: "duplicates", only: :index do
    collection { post :analyze }
    member do
      post :merge
      post :unlink
      post :revert
    end
  end
  resource :trends, only: :show
  resource :challenge_assignment, only: :create
  resources :notifications, only: %i[index destroy] do
    member { post :open }
    collection { post :mark_all }
  end
  resource :notification_preferences, only: :update
  resources :email_access_rules, only: %i[create destroy]
  resources :roles, only: %i[create update destroy]
  resources :ai_provider_configs, path: "settings/ai-providers", only: %i[create update destroy]
  resources :data_source_configs, path: "settings/data-sources", only: %i[create update destroy]
  resources :replication_configs, path: "settings/replication", only: %i[create destroy] do
    post :run, on: :member
  end
  resources :users, path: "settings/users", only: %i[create update destroy]
  post "data-imports/preview", to: "data_imports#preview", as: :preview_data_import
  post "data-imports/:id", to: "data_imports#create", as: :execute_data_import
  resources :data_imports, only: :show
  resources :translations, only: %i[create edit update destroy] do
    post :ai_translate, on: :member
  end
  resources :configuration_proposals, path: "settings/ai-proposals", only: %i[create destroy] do
    member do
      post :approve
      post :rollback
    end
  end
  patch "settings/list-sorts/:object_type", to: "list_sort_settings#update", as: :list_sort_setting
  post "settings/list-sorts/:object_type/repair", to: "list_sort_settings#repair", as: :repair_list_sort_setting
  post "records/Lead/:lead_id/convert", to: "lead_conversions#create", as: :lead_conversion
  post "records/Ticket/:ticket_id/convert-to-knowledge", to: "ticket_knowledge_conversions#create", as: :ticket_knowledge_conversion
  post "records/KnowledgeArticle/:knowledge_article_id/helpful", to: "knowledge_article_feedback#create", as: :knowledge_article_helpful
  post "records/:object_type/:record_id/lock", to: "record_locks#create", as: :record_lock
  patch "records/:object_type/:record_id/lock", to: "record_locks#update"
  delete "records/:object_type/:record_id/lock", to: "record_locks#destroy"
  get "records/:object_type/export", to: "record_exports#show", as: :record_export
  post "records/:source_type/:source_id/convert/:target_type", to: "document_conversions#create", as: :document_conversion
  post "records/:parent_type/:parent_id/line-items", to: "line_items#create", as: :line_items
  patch "records/:parent_type/:parent_id/line-items/:id", to: "line_items#update", as: :line_item
  delete "records/:parent_type/:parent_id/line-items/:id", to: "line_items#destroy"
  get "records/:object_type", to: "records#index", as: :records
  post "records/:object_type", to: "records#create"
  get "records/:object_type/new", to: "records#new", as: :new_record
  get "records/:object_type/:id", to: "records#show", as: :record
  get "records/:object_type/:id/edit", to: "records#edit", as: :edit_record
  patch "records/:object_type/:id", to: "records#update"
  delete "records/:object_type/:id", to: "records#destroy"
  post "records/:object_type/:id/relationships/:relationship_name", to: "relationship_links#create", as: :record_relationship
  delete "records/:object_type/:id/relationships/:relationship_name/:related_id", to: "relationship_links#destroy", as: :record_relationship_link
  get "records/:object_type/:id/capabilities/:capability", to: "records#capability", as: :record_capability
  namespace :api do
    namespace :v1 do
      get "openapi", to: "openapi#show"
      get "records/:object_type", to: "records#index"
      post "records/:object_type", to: "records#create"
      get "records/:object_type/:id", to: "records#show"
      patch "records/:object_type/:id", to: "records#update"
      delete "records/:object_type/:id", to: "records#destroy"
      post "records/Lead/:id/convert", to: "lead_conversions#create"
      get "records/:object_type/:id/capabilities/:capability", to: "records#capability"
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
end
