# frozen_string_literal: true

require "kaminari"
require "social-share-button"
require "ransack"

module Decidim
  module Proposals
    # This is the engine that runs on the public interface of `decidim-proposals`.
    # It mostly handles rendering the created page associated to a participatory
    # process.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::Proposals

      routes do
        resources :proposals, except: [:destroy] do
          resource :proposal_endorsement, only: [:create, :destroy] do
            get :identities, on: :collection
          end
          member do
            get :compare
            get :edit_draft
            patch :update_draft
            get :preview
            post :publish
            put :withdraw
          end
          resource :proposal_vote, only: [:create, :destroy]
          resource :proposal_widget, only: :show, path: "embed"
        end
        root to: "proposals#index"
      end

      initializer "decidim_proposals.assets" do |app|
        app.config.assets.precompile += %w(decidim_proposals_manifest.js
                                           decidim_proposals_manifest.css
                                           decidim/proposals/identity_selector_dialog.js)
      end

      initializer "decidim_proposals.inject_abilities_to_user" do |_app|
        Decidim.configure do |config|
          config.abilities += ["Decidim::Proposals::Abilities::CurrentUserAbility"]
        end
      end

      initializer "decidim_changes" do
        Decidim::SettingsChange.subscribe "surveys" do |changes|
          Decidim::Proposals::SettingsChangeJob.perform_later(
            changes[:feature_id],
            changes[:previous_settings],
            changes[:current_settings]
          )
        end
      end
    end
  end
end
