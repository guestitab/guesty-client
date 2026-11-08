module Guesty
  module Reservations
    module Reviews
      module Extractors
        class Vrbo < Base
          private

          def extract_text(raw_review)
            {
              public: [
                raw_review.dig(:title, :value),
                raw_review.dig(:body, :value)
              ].compact.reject(&:empty?).join(' ').presence
            }
          end

          def extract_scores(raw_review)
            scores = { rating: raw_review[:starRatingOverall].to_f }

            raw_ratings = raw_review[:starRatings]
            return unless raw_ratings.is_a?(Array)

            raw_ratings.each do |rating|
              next unless rating.is_a?(Hash)

              category_key = normalize_category(rating[:category].downcase.to_sym)
              scores[category_key] ||= rating[:value].to_f
            end

            scores.compact
          end

          def normalize_category(category)
            case category
            when :roomcleanliness then :cleanliness
            when :onlinelisting then :accuracy
            when :overall then :rating
            else
              category
            end
          end
        end
      end
    end
  end
end
