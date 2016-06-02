# Inflections must be added before the namespace is isolated, because the
# namespace's route prefix is calculated and cached at that time.
ActiveSupport::Inflector.inflections do |inflect|
  inflect.acronym 'GraphQL'
end

module GraphQL
  module Rails
    mattr_accessor :logger

    class Engine < ::Rails::Engine
      isolate_namespace GraphQL::Rails

      initializer 'graphql-rails' do |app|
        @graph_path = app.root.join('app', 'graph')

        # Initialize logger.
        # TODO: Fix tagging issues.
        logger = ActiveSupport::TaggedLogging.new(::Rails.logger.clone)
        logger.push_tags 'graphql'
        Rails.logger = logger
        Rails.logger.debug 'Initialized logger'

        # Load extensions.
        extensions = File.join(File.dirname(__FILE__), 'extensions', '*.rb')
        Dir[extensions].each do |file|
          require file
        end

        # Watch for changes to the /app/graph directory.
        if Rails.config.autoload
          dirs = {@graph_path.to_s => [:rb]}
          checker = ActiveSupport::FileUpdateChecker.new([], dirs) do
            Rails.logger.debug 'Detected changes to /app/graph directory'
            reload!
          end
          ActionDispatch::Reloader.to_prepare do
            checker.execute_if_updated
          end
        end

        # Perform initial load of files under the /app/graph directory.
        reload!
      end

      # TODO: Assess whether changes to a model class requires Types to be invalidated.
      def reload!
        Schema.clear
        Dir[@graph_path.join('**', '*.rb')].each do |file|
          Rails.logger.debug "Loading file: #{file}"
          load file
        end
      end
    end
  end
end
