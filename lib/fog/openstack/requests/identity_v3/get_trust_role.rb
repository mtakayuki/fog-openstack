module Fog
  module Identity
    class OpenStack
      class V3
        class Real
          def get_trust_role(id, role_id)
            request(
                :expects => [200],
                :method => 'GET',
                :path => "OS-TRUST/trusts/#{id}/roles/#{role_id}"
            )
          end
        end

        class Mock
          def get_trust_role(id)

          end
        end
      end
    end
  end
end
