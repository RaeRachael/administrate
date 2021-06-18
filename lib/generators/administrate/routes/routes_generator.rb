if defined?(Zeitwerk)
  Zeitwerk::Loader.eager_load_all
else
  Rails.application.eager_load!
end

require "rails/generators/base"
require "administrate/generator_helpers"
require "administrate/route_tree_constructor"
require "administrate/namespace"

module Administrate
  module Generators
    class RoutesGenerator < Rails::Generators::Base
      include Administrate::GeneratorHelpers
      INVALID_DATABASE_MODELS_LIST = [
        "ActiveRecord::SchemaMigration",
        "ActiveRecord::InternalMetadata",
        "primary::SchemaMigration",
      ]
      source_root File.expand_path("../templates", __FILE__)
      class_option :namespace, type: :string, default: "admin"

      def insert_dashboard_routes
        if valid_dashboard_models.any?
          route(dashboard_routes)
        end
      end

      def warn_about_invalid_models
        invalid_dashboard_models.each do |model|
          puts "WARNING: Unable to generate a dashboard for #{model}."
          if models_without_tables.include?(model)
            puts "       - It is not connected to a database table."
            puts "         Make sure your database migrations are up to date."
          end
        end

        unnamed_constants.each do |invalid_model|
          puts "NOTICE: Skipping dynamically generated model #{invalid_model}."
        end
      end

      private

      def namespace
        options[:namespace]
      end

      def dashboard_resources
        valid_dashboard_models.map do |model|
          model.to_s.pluralize.underscore
        end
      end

      def generate_resource_routes
        resource_tree = RouteTreeConstructor.new(dashboard_resources)
        resource_tree.organise_resource_routes()
      end

      def valid_dashboard_models
        database_models - (invalid_dashboard_models + excluded_models).uniq
      end

      def database_models
        ActiveRecord::Base.descendants.reject(&:abstract_class?)
      end

      def invalid_dashboard_models
        (models_without_tables + unnamed_constants).uniq
      end

      def models_without_tables
        database_models.reject(&:table_exists?)
      end

      def excluded_models
        database_models.select do |model|
          INVALID_DATABASE_MODELS_LIST.include?(model.to_s)
        end
      end

      def unnamed_constants
        ActiveRecord::Base.descendants.reject { |d| d.name == d.to_s }
      end

      def dashboard_routes
        ERB.new(File.read(routes_file_path)).result(binding)
      end

      def routes_file_path
        File.expand_path(find_in_source_paths("routes.rb.erb"))
      end
    end
  end
end
