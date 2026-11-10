module Guesty
  module Reservations
    module Reviews
      module Extractors
        class Airbnb < Base
          POSITIVE_TAG = 'GUEST_REVIEW_HOST_POSITIVE_'.freeze #: ::String
          NEGATIVE_TAG = 'GUEST_REVIEW_HOST_NEGATIVE_'.freeze #: ::String

          private

          # @rbs (::Hash[::Symbol, untyped] raw_review) -> ::Hash[::Symbol, untyped]
          def extract(raw_review)
            codes = tag_codes(raw_review)

            {
              **super,
              positive_tags: tags(codes, POSITIVE_TAG),
              negative_tags: tags(codes, NEGATIVE_TAG),
              other_tags: codes.reject { it.start_with?(POSITIVE_TAG, NEGATIVE_TAG) }.map(&:downcase)
            }
          end

          def extract_text(raw_review)
            {
              public: raw_review[:public_review],
              private: raw_review[:private_feedback]
            }.compact_blank
          end

          def extract_scores(raw_review)
            scores = { rating: raw_review[:overall_rating]&.to_f }

            category_ratings = raw_review[:category_ratings]
            return unless category_ratings.is_a?(Array)

            category_ratings.each do |rating_entry|
              next unless rating_entry.is_a?(Hash)

              category = rating_entry[:category].downcase.to_sym
              rating = rating_entry[:rating]

              scores[category] = rating.to_f if category.present? && rating.present?
            end

            scores.compact
          end

          # @rbs (::Hash[::Symbol, untyped] raw_review) -> ::Array[::String]
          def tag_codes(raw_review)
            category_ratings = raw_review[:category_ratings]

            return [] unless category_ratings.is_a?(Array)

            category_ratings.flat_map { it[:review_category_tags] }
          end

          # @rbs (::Array[::String] codes, ::String prefix) -> ::Array[::String]
          def tags(codes, prefix)
            codes.select { it.start_with?(prefix) }.map { it.delete_prefix(prefix).downcase }
          end
        end
      end
    end
  end
end
