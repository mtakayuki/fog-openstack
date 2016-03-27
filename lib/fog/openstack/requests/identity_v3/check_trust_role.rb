module Fog
  module Identity
    class OpenStack
      class V3
        class Real
          def check_trust_role(id, role_id)
            request(
                :expects => [200],
                :method => 'HEAD',
                :path => "OS-TRUST/trusts/#{id}/roles/#{role_id}"
            )
          end
        end

        class Mock
          def check_trust_role(id, role_id)

          end
        end
      end
    end
  end
end
