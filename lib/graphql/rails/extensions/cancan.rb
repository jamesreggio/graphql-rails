module GraphQL
  module Rails
    if Rails.config.cancan
      Rails.logger.debug 'Loading CanCan extensions'

      # Implement methods from CanCan::ControllerAdditions in Operations.
      # http://www.rubydoc.info/github/ryanb/cancan/CanCan/ControllerAdditions
      Operations.class_eval do
        extend Forwardable
        def_delegators :current_ability, :can?, :cannot?

        def self.check_authorization(options = {})
          self.after_filter(options.slice(:only, :except)) do |instance|
            next if instance.instance_variable_defined?(:@authorized)
            next if options[:if] && !instance.send(options[:if])
            next if options[:unless] && instance.send(options[:unless])
            raise 'This operation failed to perform an authorization check'
          end
        end

        def skip_authorization_check(*args)
          self.before_filter(*args) do |instance|
            instance.instance_variable_set(:@authorized, true)
          end
        end

        def authorize!(*args)
          begin
            @authorized = true
            current_ability.authorize!(*args)
          rescue ::CanCan::AccessDenied
            raise 'You are not authorized to perform this operation'
          end
        end

        def current_ability
          @current_ability ||= ::Ability.new(current_user)
        end

        def current_user
          context[:current_user]
        end
      end

      # Make the current_user available during GraphQL execution via the
      # operation context object.
      ControllerExtensions.add do
        before_filter do
          context[:current_user] = current_user
        end
      end
    end
  end
end
