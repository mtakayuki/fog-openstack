require 'fog/openstack/models/collection'
require 'fog/openstack/models/identity_v3/trust'

module Fog
  module Identity
    class OpenStack
      class V3
        class Trusts < Fog::OpenStack::Collection
          model Fog::Identity::OpenStack::V3::Trust

          def all(options = {})
            load_response(service.list_trusts(options), 'trusts')
          end

          def find_by_id(id)
            trust = service.get_trust(id).body['trust']
            Fog::Identity::OpenStack::V3::Trust.new(
                trust.merge(:service => service))
          end

          def destroy(id)
            trust = self.find_by_id(id)
            trust.destroy
          end
        end
      end
    end
  end
end
