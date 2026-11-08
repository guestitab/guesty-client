module Guesty
  module Reservations
    module Reviews
      module Extractors
        class Base
          include Guesty::Operation

          # @rbs (raw_review: ::Hash[::Symbol, untyped]) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
          def call(raw_review:)
            argument! raw_review: :required, fatal: true if raw_review.blank?

            Success(extract(raw_review))
          end

          private

          # @rbs (::Hash[::Symbol, untyped] raw_review) -> ::Hash[::Symbol, untyped]
          def extract(raw_review)
            {
              text: extract_text(raw_review),
              scores: extract_scores(raw_review)
            }
          end

          def extract_text(raw_review)
            raise NotImplementedError, "#{self.class} must implement #extract_text"
          end

          def extract_scores(raw_review)
            raise NotImplementedError, "#{self.class} must implement #extract_scores"
          end
        end
      end
    end
  end
end
