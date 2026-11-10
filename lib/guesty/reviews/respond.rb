module Guesty
  module Reviews
    class Respond
      include Guesty::Operation

      # @rbs (review_id: ::String, text: ::String) -> Dry::Monads::Result[bool]
      def call(review_id:, text:)
        argument! review_id: :required if review_id.blank?
        argument! text: :required if text.blank?

        request(:put, "reviews/#{review_id}/reply", { reviewReply: text })

        Success(true)
      end
    end
  end
end
