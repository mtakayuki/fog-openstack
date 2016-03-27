module Fog
  module Identity
    class OpenStack
      class V3
        class Real
          def list_trust_roles(id)
            request(
                :expects => [200],
                :method => 'GET',
                :path => "OS-TRUST/trusts/#{id}/roles"
            )
          end
        end

        class Mock
          def list_trust_roles(id, user_id)

          end
        end
      end
    end
  end
end
