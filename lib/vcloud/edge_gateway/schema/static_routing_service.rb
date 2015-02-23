module Vcloud
  module EdgeGateway
    module Schema
      STATIC_ROUTE = {
        type: Hash,
        internals: {
          enabled:  { type: 'boolean', required: false },
          name:     { type: 'string', required: true },
          network:  { type: 'ip_address_range', required: true },
          next_hop: { type: 'ip_address', required: true },
          apply_on: { type: 'string', required: true }
        }
      }


      STATIC_ROUTING_SERVICE = {
        type: Hash,
        allowed_empty: true,
        required: false,
        internals: {
          enabled: { type: 'boolean', required: false },
          static_routes: {
            type: Array,
            required: false,
            allowed_empty: true,
            each_element_is: STATIC_ROUTE
          }
        }
      }

    end
  end
end
