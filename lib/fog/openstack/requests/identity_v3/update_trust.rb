module Fog
  module Identity
    class OpenStack
      class V3
        class Real
          def update_trust(id, trust)
            request(
                :expects => [200],
                :method => 'PATCH',
                :path => "OS-TRUST/trusts/#{id}",
                :body => Fog::JSON.encode(:trust => trust)
            )
          end
        end

        class Mock
          def update_trust(id, trust)

          end
        end
      end
    end
  end
end
