RSpec.describe Guesty::Reservations::Reviews::Extractors::Airbnb do
  include_context 'operations'

  let(:args) { { raw_review: } }

  let(:raw_review) do
    {
      public_review: 'A lovely stay',
      overall_rating: 4,
      category_ratings: [
        { category: 'cleanliness', rating: 5, review_category_tags: %w[GUEST_REVIEW_HOST_POSITIVE_SPOTLESS_FURNITURE_AND_LINENS] },
        { category: 'checkin', rating: 2, review_category_tags: %w[GUEST_REVIEW_HOST_NEGATIVE_HAD_TO_WAIT] },
        { category: 'location', rating: 4, review_category_tags: %w[LOCATION_OTHER] }
      ]
    }
  end

  context 'with valid arguments' do
    it_behaves_like 'successful call', value: {
      text: { public: 'A lovely stay' },
      scores: {
        rating: 4.0,
        cleanliness: 5.0,
        checkin: 2.0,
        location: 4.0
      },
      positive_tags: %w[spotless_furniture_and_linens],
      negative_tags: %w[had_to_wait],
      other_tags: %w[location_other]
    }

    context 'without category ratings' do
      let(:raw_review) { { public_review: 'A lovely stay', overall_rating: 4 } }

      it_behaves_like 'successful call', value: {
        text: { public: 'A lovely stay' },
        scores: nil,
        positive_tags: [],
        negative_tags: [],
        other_tags: []
      }
    end
  end
end
