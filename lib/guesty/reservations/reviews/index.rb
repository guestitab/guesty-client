module Guesty
  module Reservations
    module Reviews
      # startDate filters on the review's updatedAt.
      class Index
        include Guesty::Operation

        # @rbs (since: ::Time, ?skip: ::Integer, ?take: ::Integer) -> Dry::Monads::Result[::Array[::Hash[::Symbol, untyped]]]
        def call(since:, skip: 0, take: 100)
          argument! take: :invalid if take.blank? || take <= 0

          reviews = request(:get, 'reviews', { startDate: since.utc.iso8601, skip:, limit: take })[:data]
          return Success([]) unless reviews.is_a?(Array)

          Success(reviews.filter_map { |review| parse(review) })
        end

        private

        # @rbs (::Hash[::Symbol, untyped] review) -> ::Hash[::Symbol, untyped]?
        def parse(review)
          return unless review[:rawReview].is_a?(Hash)

          result = extractor_for(review[:channelId]).new.call(raw_review: review[:rawReview])
          return if result.failure?

          result.value!.merge(created_at: review[:createdAt], guesty_review_id: review[:_id], guesty_reservation_id: review[:reservationId])
        end

        # @rbs (::String? channel_id) -> untyped
        def extractor_for(channel_id)
          case (channel = channel_id.to_s.downcase)
          when /airbnb/ then Extractors::Airbnb
          when /booking/ then Extractors::BookingCom
          when /vrbo|homeaway/ then Extractors::Vrbo
          else error! "Unsupported channel: #{channel}"
          end
        end
      end
    end
  end
end
