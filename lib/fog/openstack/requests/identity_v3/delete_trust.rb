module Fog
  module Identity
    class OpenStack
      class V3
        class Real
          def delete_trust(id)
            request(
              :expects => [204],
              :method  => 'DELETE',
              :path    => "OS-TRUST/trusts/#{id}"
            )
          end
        end

        class Mock
          def delete_trust(id)
            if list_trusts.body['trusts'].any? { |t| t['id'] == id }
              data[:trusts].delete(id)
              response = Excon::Response.new
              response.status = 204
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
