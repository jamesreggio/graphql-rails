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

      # Even though we aren't using symbolic autoloading of operations, they
      # must be included in autoload_paths in order to be unloaded during
      # reload operations.
      initializer 'graphql-rails.autoload', :before => :set_autoload_paths do |app|
        @graph_path = app.root.join('app', 'graph')
        app.config.autoload_paths += [
          @graph_path.join('types'),
          @graph_path.join('operations'),
        ]
      end

      # Extend the Rails logger with a facility for logging exceptions.
      initializer 'graphql-rails.logger', :after => :initialize_logger do |app|
        logger = ::Rails.logger.clone
        logger.class_eval do
          def exception(e)
            begin
              error "#{e.class.name} (#{e.message}):"
              error "  #{e.backtrace.join("\n  ")}"
            rescue
            end
          end
        end
        Rails.logger = logger
        Rails.logger.debug 'Initialized logger'
      end

      # Extensions depend upon a loaded Rails app, so we load them dynamically.
      initializer 'graphql-rails.extensions', :after => :load_config_initializers do |app|
        extensions = File.join(File.dirname(__FILE__), 'extensions', '*.rb')
        Dir[extensions].each do |file|
          require file
        end
      end

      # Hook into Rails reloading in order to clear state from internal
      # stateful modules and reload operations from the Rails app.
      initializer 'graphql-rails.prepare', :before => :add_to_prepare_blocks do
        # The block executes in the context of the reloader, so we have to
        # preserve a reference to the engine instance.
        engine = self
        config.to_prepare_blocks.push -> do
          engine.reload!
        end
      end

      # Clear state and load operations from the Rails app.
      def reload!
        Types.clear
        Schema.clear
        Rails.logger.debug 'Loading operations'
        Dir[@graph_path.join('operations', '**', '*.rb')].each do |file|
          Rails.logger.debug "Loading file: #{file}"
          require_dependency file
        end
      end
    end
  end
end
