module Fog
  module Identity
    class OpenStack
      class V3
        class Real
          def create_trust(trustee_user_id, impersonation, options = {})
            data = {
              'trust' => {
                'trustee_user_id' => trustee_user_id,
                'impersonation'   => impersonation
              }
            }
            data['trust']['trustor_user_id'] = self.current_user_id unless options[:trustor_user_id]

            vanilla_options = [:project_id, :remaining_uses, :expires_at,
                               :allow_redelegation, :redelegation_count,
                               :roles, :trustor_user_id]
            vanilla_options.reject { |o| options[o].nil? }.each do |key|
              data['trust'][key] = options[key]
            end

            request(
              :expects => [201],
              :method  => 'POST',
              :path    => "OS-TRUST/trusts",
              :body    => Fog::JSON.encode(Fog::JSON.sanitize(data))
            )
          end
        end

        class Mock
          def create_trust(trustee_user_id, impersonation, options = {})
            trust_id = Fog::UUID.uuid

            response = Excon::Response.new
            response.status = 201
            data = {
              'id'                 => trust_id,
              'deleted_at'         => nil,
              'expires_at'         => options[:expires_at] && options[:expires_at].utc.strftime('%Y-%m-%dT%H:%M:%S.00000Z'),
              'impersonation'      => impersonation,
              'project_id'         => options[:project_id],
              'redelegation_count' => options[:allow_redelegation] ? options[:redelegation_count] || 3 : 0,
              'remaining_uses'     => options[:remaining_uses],
              'roles_links'        => { 'self' => "http://localhost:5000/v3/OS-TRUST/trusts/#{trust_id}/roles",
                                        'previous' => nil, 'next' => nil },
              'trustor_user_id'    => options[:trustor_user_id] || self.current_user_id,
              'trustee_user_id'    => trustee_user_id
            }
            data['roles'] = (options[:roles] || []).map do |r|
              role_id = r[:id] || Fog::UUID.uuid
              {
                'id'    => role_id,
                'name'  => r[:name] || Fog::Mock.random_letters(6),
                'links' => "http://localhost:5000/v3/roles/#{role_id}"
              }
            end
            self.data[:trusts][trust_id] = data
            response.body = { 'trust' => data }
            response
          end
        end
      end
    end
  end
end
