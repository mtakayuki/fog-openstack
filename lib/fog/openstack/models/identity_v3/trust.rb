require 'fog/openstack/models/model'

module Fog
  module Identity
    class OpenStack
      class V3
        class Trust < Fog::OpenStack::Model
          identity :id

          attribute :trustor_user_id
          attribute :trustee_user_id
          attribute :impersonation
          attribute :project_id
          attribute :remaining_uses
          attribute :expires_at, :type => :time
          attribute :allow_redelegation
          attribute :redelegation_count
          attribute :links

          def to_s
            self.id
          end

          def destroy
            requires :id
            service.delete_trust(self.id)
            true
          end

          def update(attr = nil)
            requires :id
            merge_attributes(
                service.update_trust(self.id, attr || attributes).body['trust'])
            self
          end

          def create
            requires :trustee_user_id, :impersonation
            self.trustor_user_id = service.current_user_id unless trustor_user_id
            merge_attributes(
                service.create_trust(attributes).body['trust'])
            self
          end

          def roles
            requires :id
            service.list_trust_roles(self.id).body['roles']
          end

          def check_role(role_id)
            requires :id
            begin
              service.check_trust_role(self.id, role_id)
            rescue Fog::Identity::OpenStack::NotFound
              return false
            end
            return true
          end

        end
      end
    end
  end
end
