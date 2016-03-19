

module Fog
  module Identity
    class OpenStack < Fog::Service
      requires :openstack_auth_url

      # Fog::Identity::OpenStack.new() will return a Fog::Identity::OpenStack::V2 or a Fog::Identity::OpenStack::V3,
      #  depending on whether the auth URL is for an OpenStack Identity V2 or V3 API endpoint
      def self.new(args = {})
        if self.inspect == 'Fog::Identity::OpenStack'
          identity = super(args.select { |key, _value| key == :openstack_auth_url })
          service = identity.v3? ? Fog::Identity::OpenStack::V3.new(args) : Fog::Identity::OpenStack::V2.new(args)
        else
          service = Fog::Service.new(args)
        end
        service
      end

      module Version
        def initialize(options = {})
          @openstack_auth_uri = URI.parse(options[:openstack_auth_url])
        end

        def v3?
          @openstack_auth_uri && @openstack_auth_uri.path =~ /\/v3/
        end
      end

      class Mock
        include Version
      end

      class Real
        include Version
      end
    end
  end
end
