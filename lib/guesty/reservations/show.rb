module Guesty
  module Reservations
    class Show
      include Guesty::Operation

      # @rbs (reservation_id: ::String, fields: ::Array[::String]) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
      def call(reservation_id:, fields: [])
        argument! reservation_id: :required if reservation_id.blank?
        argument! fields: :required if fields.blank?

        attributes = {} #: ::Hash[::Symbol, ::String]
        attributes[:fields] = fields.join(' ') if fields.present?

        response = Guesty.do_request :get, "reservations/#{reservation_id}", attributes

        Success(handle_response(response))
      end

      private

      def handle_response(response)
        raise response.failure unless response.success?

        response.value!.body
      end
    end
  end
end
