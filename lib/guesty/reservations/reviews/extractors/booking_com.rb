module Guesty
  module Reservations
    module Reviews
      module Extractors
        class BookingCom < Base
          private

          def extract_text(raw_review)
            {
              public: [
                raw_review.dig(:content, :headline),
                raw_review.dig(:content, :positive),
                raw_review.dig(:content, :negative)
              ].compact_blank.join(' ').presence
            }
          end

          def extract_scores(raw_review)
            scores = {} #: ::Hash[::Symbol, untyped]
            category_ratings = raw_review[:scoring]
            return unless category_ratings.is_a?(Hash)

            category_ratings.each do |category, rating|
              scores[category.to_sym] = (rating.to_f / 2).round(2) # Booking.com gives 1-10, we want 0-5
            end

            scores[:rating] = scores[:review_score]
            scores[:cleanliness] = scores[:clean]
            scores.except(:clean, :review_score).compact
          end
        end
      end
    end
  end
end
