module Guesty
  module Reservations
    module Reviews
      # startDate/endDate filter on the review's updatedAt, newest update first.
      class Index
        include Guesty::Operation

        # @rbs (since: ::Time, ?skip: ::Integer, ?take: ::Integer) -> Dry::Monads::Result[::Array[::Hash[::Symbol, untyped]]]
        def call(since:, skip: 0, take: 100)
          argument! take: :invalid if take.blank? || take <= 0

          response = Guesty.do_request(:get, 'reviews', query(since, skip, take))

          return response unless response.success?

          reviews = parse_reviews(response.value!.body[:data])

          Success(reviews)
        end

        private

        # @rbs (::Time since, ::Integer skip, ::Integer take) -> ::Hash[::Symbol, untyped]
        def query(since, skip, take)
          {
            startDate: since.utc.iso8601,
            skip:,
            limit: take
          }
        end

        # @rbs (::Array[::Hash[::Symbol, untyped]] guesty_reviews_data) -> ::Array[::Hash[::Symbol, untyped]]
        def parse_reviews(guesty_reviews_data)
          return [] unless guesty_reviews_data.is_a?(Array)

          guesty_reviews_data.map do |review_data|
            next unless review_data[:rawReview].is_a?(Hash)

            extractor = get_extractor_for_channel(review_data[:channelId]&.downcase)
            result = extractor.new.call(raw_review: review_data[:rawReview])
            next unless result.success?

            result.value!.merge(
              created_at: review_data[:createdAt],
              guesty_review_id: review_data[:_id],
              guesty_reservation_id: review_data[:reservationId]
            )
          end.compact
        end

        # @rbs (::String? channel) -> untyped
        def get_extractor_for_channel(channel)
          case channel.to_s.downcase
          when /airbnb/i
            Extractors::Airbnb
          when /booking/i
            Extractors::BookingCom
          when /vrbo|homeaway/i
            Extractors::Vrbo
          else
            error! "Unsupported channel: #{channel}"
          end
        end
      end
    end
  end
end
