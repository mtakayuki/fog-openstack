

module Fog
  module Identity
    class OpenStack < Fog::Service
      requires :openstack_auth_url
      recognizes :openstack_auth_token, :openstack_management_url, :persistent,
                 :openstack_service_type, :openstack_service_name, :openstack_tenant,
                 :openstack_endpoint_type, :openstack_region, :openstack_domain_id,
                 :openstack_project_name, :openstack_domain_name,
                 :openstack_user_domain, :openstack_project_domain,
                 :openstack_user_domain_id, :openstack_project_domain_id,
                 :openstack_api_key, :openstack_current_user_id, :openstack_userid, :openstack_username,
                 :current_user, :current_user_id, :current_tenant,
                 :provider, :openstack_identity_prefix, :openstack_endpoint_path_matches

      # Fog::Identity::OpenStack.new() will return a Fog::Identity::OpenStack::V2 or a Fog::Identity::OpenStack::V3,
      #  depending on whether the auth URL is for an OpenStack Identity V2 or V3 API endpoint
      def self.new(args = {})
        if self.inspect == 'Fog::Identity::OpenStack'
          identity = super
          if identity.v3?
            service = Fog::Identity::OpenStack::V3.new(identity)
          else
            service = Fog::Identity::OpenStack::V2.new(identity)
          end
        else
          service = Fog::Service.new(args)
        end
        service
      end

      module ConfigService
        def config_service?
          true
        end

        private

        def configure(options)
          if options.respond_to?(:config_service?) && options.config_service?
            options.instance_variables.each do |v|
              instance_variable_set(v, options.instance_variable_get(v))
            end
            true
          else
            false
          end
        end
      end

      class Mock
        include ConfigService

        attr_reader :auth_token
        attr_reader :auth_token_expiration
        attr_reader :current_user
        attr_reader :current_tenant
        attr_reader :unscoped_token

        module Data
          def self.data
            @users ||= {}
            @roles ||= {}
            @tenants ||= {}
            @ec2_credentials ||= Hash.new { |hash, key| hash[key] = {} }
            @user_tenant_membership ||= {}

            @data ||= Hash.new do |hash, key|
              hash[key] = {
                :users => @users,
                :roles => @roles,
                :tenants => @tenants,
                :ec2_credentials => @ec2_credentials,
                :user_tenant_membership => @user_tenant_membership
              }
            end
          end

          def self.reset!
            @data = nil
            @users = nil
            @roles = nil
            @tenants = nil
            @ec2_credentials = nil
          end
        end

        def self.data
          Data.data
        end

        def self.reset!
          Data.reset!
        end

        def initialize(options = {})
          configure(options) && return

          @openstack_username = options[:openstack_username] || 'admin'
          @openstack_tenant = options[:openstack_tenant] || 'admin'
          @openstack_auth_uri = URI.parse(options[:openstack_auth_url])
          @openstack_management_url = @openstack_auth_uri.to_s
          @openstack_identity_prefix = options[:openstack_identity_prefix]

          @auth_token = Fog::Mock.random_base64(64)
          @auth_token_expiration = (Time.now.utc + 86400).iso8601

          @admin_tenant = self.data[:tenants].values.find do |u|
            u['name'] == 'admin'
          end

          if @openstack_tenant
            @current_tenant = self.data[:tenants].values.find do |u|
              u['name'] == @openstack_tenant
            end

            unless @current_tenant
              @current_tenant_id = Fog::Mock.random_hex(32)
              @current_tenant = self.data[:tenants][@current_tenant_id] = {
                'id' => @current_tenant_id,
                'name' => @openstack_tenant
              }
            else
              @current_tenant_id = @current_tenant['id']
            end
          else
            @current_tenant = @admin_tenant
          end

          @current_user = self.data[:users].values.find do |u|
            u['name'] == @openstack_username
          end
          @current_tenant_id = Fog::Mock.random_hex(32)

          unless @current_user
            @current_user_id = Fog::Mock.random_hex(32)
            @current_user = self.data[:users][@current_user_id] = {
              'id' => @current_user_id,
              'name' => @openstack_username,
              'email' => "#{@openstack_username}@mock.com",
              'tenantId' => Fog::Mock.random_numbers(6).to_s,
              'enabled' => true
            }
          else
            @current_user_id = @current_user['id']
          end
        end

        def data
          self.class.data[@openstack_username]
        end

        def reset_data
          self.class.data.delete(@openstack_username)
        end

        def credentials
          {:provider => 'openstack',
            :openstack_auth_url => @openstack_auth_uri.to_s,
            :openstack_auth_token => @auth_token,
            :openstack_management_url => @openstack_management_url,
            :openstack_current_user_id => @openstack_current_user_id,
            :current_user => @current_user,
            :current_tenant => @current_tenant}
        end

        def v3?
          if @openstack_identity_prefix
            @openstack_identity_prefix =~ /v3/
          else
            @openstack_auth_uri && @openstack_auth_uri.path =~ %r{/v3}
          end
        end
      end

      class Real
        DEFAULT_SERVICE_TYPE_V3 = %w(identity_v3 identityv3 identity).collect(&:freeze).freeze
        DEFAULT_SERVICE_TYPE    = %w(identity).collect(&:freeze).freeze

        def self.not_found_class
          Fog::Identity::OpenStack::NotFound
        end
        include Fog::OpenStack::Common
        include ConfigService

        def initialize(options = {})
          configure(options) && return

          initialize_identity(options)

          @openstack_service_type   = options[:openstack_service_type] || default_service_type(options)
          @openstack_service_name   = options[:openstack_service_name]

          @connection_options       = options[:connection_options] || {}

          @openstack_endpoint_type  = options[:openstack_endpoint_type] || 'adminURL'
          initialize_endpoint_path_matches(options)

          authenticate

          if options[:openstack_identity_prefix]
            @path = "/#{options[:openstack_identity_prefix]}/#{@path}"
          end

          @persistent = options[:persistent] || false
          @connection = Fog::Core::Connection.new("#{@scheme}://#{@host}:#{@port}", @persistent, @connection_options)
        end

        def v3?
          @path && @path =~ %r{/v3}
        end

        private

        def default_service_type(options)
          unless options[:openstack_identity_prefix]
            if @openstack_auth_uri.path =~ %r{/v3} ||
               (options[:openstack_endpoint_path_matches] && options[:openstack_endpoint_path_matches] =~ '/v3')
              return DEFAULT_SERVICE_TYPE_V3
            end
          end
          DEFAULT_SERVICE_TYPE
        end

        def initialize_endpoint_path_matches(options)
          if options[:openstack_endpoint_path_matches]
            @openstack_endpoint_path_matches = options[:openstack_endpoint_path_matches]
          end
        end
      end
    end
  end
end
