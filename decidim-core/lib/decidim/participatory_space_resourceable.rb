# frozen_string_literal: true

require "active_support/concern"

module Decidim
  # A concern with the features needed when you want a model to be able to create
  # links from it to another resource.
  module ParticipatorySpaceResourceable
    extend ActiveSupport::Concern

    included do
      # An association with all the links that point to this model.
      has_many :participatory_space_resource_links_to, as: :to, class_name: "Decidim::ParticipatorySpaceLink"

      # An association with all the links that are originated from this model.
      has_many :participatory_space_resource_links_from, as: :from, class_name: "Decidim::ParticipatorySpaceLink"

      # Finds all the linked resources to or from this model for a given resource
      # name and link name.
      #
      # resource_name - The String name of the resource manifest exposed by a feature.
      # link_name     - The String name of the link between this model and the target resource.

      def linked_participatory_space_resources(resource_name, link_name)
        klass = "Decidim::#{resource_name.to_s.classify}"
        klass = klass.constantize
        from = klass
               .joins(:participatory_space_resource_links_from)
               .where(decidim_participatory_space_links: { name: link_name, to_id: id, to_type: self.class.name })

        to = klass
             .joins(:participatory_space_resource_links_to)
             .where(decidim_participatory_space_links: { name: link_name, from_id: id, from_type: self.class.name })

        klass.where(id: from).or(klass.where(id: to))
      end

      def participatory_space_sibling_scope(participatory_space_name)
        manifest = Decidim.find_participatory_space_manifest(participatory_space_name)
        return self.class.none unless manifest

        scope = manifest.participatory_spaces
        raise
        scope = scope.where("#{self.class.table_name}.id != ?", id) if manifest.model_class_name.constantize == self.class

        scope
      end

      # Links the given resources to this model, replaces any previous links with the same name.
      #
      # resources - An Array or ActiveRecord::Base object to link to.
      # link_name - The String name to use as the name between the resources.
      # data      - An optional Hash to add to the link.
      #
      # Returns nothing.
      def link_participatory_spaces_resources(resources, link_name, data = {})
        transaction do
          participatory_space_resource_links_from.where(name: link_name).delete_all
          Array.wrap(resources).each do |resource|
            Decidim::ParticipatorySpaceLink.create!(
              from: self,
              to: resource,
              name: link_name,
              data: data
            )
          end
        end
      end
    end
  end
end