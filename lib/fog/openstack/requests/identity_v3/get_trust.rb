module Fog
  module Identity
    class OpenStack
      class V3
        class Real
          def get_trust(id)
            request(
              :expects => [200],
              :method  => 'GET',
              :path    => "OS-TRUST/trusts/#{id}"
            )
          end
        end

        class Mock
          def get_trust(id)
            if data = self.data[:trusts][id]
              response = Excon::Response.new
              response.status = 200
              response.body = { 'trust' => data }
              response
            else
              raise Fog::Network::OpenStack::NotFound
            end
          end
        end
      end
    end
  end
end
