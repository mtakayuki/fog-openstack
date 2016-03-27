module Fog
  module Identity
    class OpenStack
      class V3
        class Real
          def list_trusts(options = {})
            request(
              :expects => [200],
              :method  => 'GET',
              :path    => "OS-TRUST/trusts",
              :query   => options
            )
          end
        end

        class Mock
          def list_trusts(options = {})
            Excon::Response.new(
              :body   => { 'trusts' => data[:trusts].values },
              :status => 200
            )
          end
        end
      end
    end
  end
end
