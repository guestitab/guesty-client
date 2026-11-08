RSpec.describe Guesty::Reservations::Reviews::Index do
  include_context 'operations'

  let(:args) { { since: } }

  let(:since) { Time.zone.local(2025, 3, 26) }

  context 'with valid arguments' do
    context 'with an Airbnb review', vcr: { cassette_name: 'reservations/reviews/index/airbnb' } do
      it_behaves_like 'successful call', value_containing: [
        {
          text: { public: /Fin lägenhet med gott om utrymme./ },
          scores: {
            rating: 5.0,
            cleanliness: 5.0,
            accuracy: 5.0,
            checkin: 5.0,
            communication: 5.0,
            location: 5.0,
            value: 5.0
          },
          positive_tags: %w[free_of_clutter looked_like_photos responsive_host clear_instructions easy_to_get_inside flexible_check_in walkable],
          negative_tags: [],
          other_tags: [],
          created_at: '2025-03-12T15:21:53.368Z',
          guesty_review_id: /\A[a-f0-9]+\z/,
          guesty_reservation_id: '67e1e816ac7b8b00129fcefe'
        }
      ]
    end

    context 'with a Booking.com review', vcr: { cassette_name: 'reservations/reviews/index/booking_com' } do
      it_behaves_like 'successful call', value_containing: [
        {
          text: { public: /Not impressed.*The bed frame literally broke in half/ },
          scores: {
            rating: 0.5,
            facilities: 3.75,
            comfort: 1.25,
            staff: 2.5,
            value: 2.5,
            cleanliness: 3.75,
            location: 3.75
          },
          created_at: '2025-03-12T15:21:53.368Z',
          guesty_review_id: /\A[a-f0-9]+\z/,
          guesty_reservation_id: '67e1e816ac7b8b00129fcefe'
        }
      ]
    end

    context 'with a Vrbo review', vcr: { cassette_name: 'reservations/reviews/index/vrbo_com' } do
      it_behaves_like 'successful call', value_containing: [
        {
          text: { public: /Nice but not accurate/ },
          scores: {
            rating: 3.0,
            checkin: 2.0,
            location: 2.0,
            communication: 2.0,
            cleanliness: 4.0,
            accuracy: 1.0
          },
          created_at: '2025-03-12T15:21:53.368Z',
          guesty_review_id: /\A[a-f0-9]+\z/,
          guesty_reservation_id: '67e1e816ac7b8b00129fcefe'
        }
      ]
    end

    context 'with a review from an unsupported channel', vcr: { cassette_name: 'reservations/reviews/index/unsupported' } do
      let(:message) { 'Unsupported channel: unsupported' }

      it_behaves_like 'failed call', failure_class: Guesty::Error
    end
  end
end
