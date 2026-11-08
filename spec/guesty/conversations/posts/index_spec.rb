RSpec.describe Guesty::Conversations::Posts::Index do
  include_context 'operations'

  let(:args) { { conversation_id:, cursor: } }

  let(:conversation_id) { '6935776e986f1c0011038b7b' }
  let(:cursor) { nil }

  context 'with valid arguments', vcr: { cassette_name: 'conversations/posts/index/by_conversation' } do
    let(:endpoint) { "https://open-api.guesty.com/v1/communication/conversations/#{conversation_id}/posts" }

    it_behaves_like 'successful call', value: -> {
      {
        results: [
          provider_post(provider_message_id: 'post_1', sender_kind: 'host', body: 'Welcome!', module_type: 'airbnb2',
                        provider_occurred_at: Time.zone.iso8601('2026-01-01T10:00:00.000Z'), author_name: 'Guestit Manual'),
          provider_post(provider_message_id: 'post_2', sender_kind: 'guest', body: 'Thanks!', module_type: 'airbnb2',
                        provider_occurred_at: Time.zone.iso8601('2026-01-01T11:00:00.000Z')),
          provider_post(provider_message_id: 'post_3', sender_kind: 'guest', body: 'What is the check-in code?', module_type: 'airbnb2',
                        provider_occurred_at: Time.zone.iso8601('2026-01-01T12:00:00.000Z'))
        ],
        cursor_after: nil,
        oldest_created_at: Time.zone.iso8601('2026-01-01T10:00:00.000Z')
      }
    }

    context 'with a cursor', vcr: false do
      let(:cursor) { 'page-2' }

      before do
        stub_request(:get, endpoint).with(query: hash_including({})).to_return(
          status: 200,
          body: { status: 200, data: { count: 0, posts: [], cursor: { after: 'page-3' } } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        result
      end

      it_behaves_like 'successful call', value: { results: [], cursor_after: 'page-3', oldest_created_at: nil }

      it 'requests the page after the cursor' do
        expect(WebMock).to have_requested(:get, endpoint).with(query: { 'limit' => described_class::LIMIT.to_s, 'sort' => '-createdAt', 'cursorAfter' => 'page-2' }).once
      end
    end

    context 'when Guesty answers something other than a post list', vcr: false do
      let(:message) { 'Guesty posts response has an unexpected shape.' }

      before do
        stub_request(:get, endpoint).with(query: hash_including({}))
                                    .to_return(status: 200, body: { status: 200, data: {} }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it_behaves_like 'failed call', failure_class: Guesty::Error
    end

    context 'with attachments', vcr: { cassette_name: 'conversations/posts/index/attachment_only' } do
      it_behaves_like 'successful call', value: -> {
        {
          results: [
            provider_post(
              provider_message_id: 'post_photo', sender_kind: 'guest', body: '', module_type: 'airbnb2',
              provider_occurred_at: Time.zone.iso8601('2026-01-01T13:00:00.000Z'),
              attachments: ['image/jpeg'],
              attachment_keys: ['production/67853b83eab5de1fd4c47333/jpeg/60a5fa8262e3a0fea0e6e42528a22ce6_broken-window.jpeg']
            ),
            provider_post(
              provider_message_id: 'post_photos', sender_kind: 'guest', body: '', module_type: 'airbnb2',
              provider_occurred_at: Time.zone.iso8601('2026-01-01T14:00:00.000Z'),
              attachments: %w[image/png image/jpeg],
              attachment_keys: %w[
                production/67853b83eab5de1fd4c47333/png/7c1e0b4f2a9d3e6b8c5a0f1d2e3b4c5d_kitchen-1.png
                production/67853b83eab5de1fd4c47333/jpeg/9d2f1a0c3b8e7d6a5f4c2b1e0d9a8c7b_kitchen-2.jpeg
              ]
            ),
            provider_post(
              provider_message_id: 'post_unnamed', sender_kind: 'guest', body: '', module_type: 'airbnb2',
              provider_occurred_at: Time.zone.iso8601('2026-01-01T15:00:00.000Z'),
              attachments: ['application/pdf'],
              attachment_keys: ['production/67853b83eab5de1fd4c47333/pdf/1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d']
            ),
            provider_post(
              provider_message_id: 'post_captioned', sender_kind: 'guest', body: 'The window is broken', module_type: 'airbnb2',
              provider_occurred_at: Time.zone.iso8601('2026-01-01T16:00:00.000Z'),
              attachments: ['image/jpeg'],
              attachment_keys: ['production/67853b83eab5de1fd4c47333/jpeg/2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e_broken-window.jpeg']
            )
          ],
          cursor_after: nil,
          oldest_created_at: Time.zone.iso8601('2026-01-01T13:00:00.000Z')
        }
      }
    end

    context 'with system, note, automatic and incomplete posts', vcr: false do
      let(:written_at) { '2026-01-01T10:00:00.000Z' }
      let(:posts) do
        [
          { _id: nil, sentBy: 'guest', body: 'Nothing to cite this by', createdAt: written_at },
          { _id: 'post_system', sentBy: 'system', body: 'Reservation confirmed', createdAt: written_at },
          { _id: 'post_silent', sentBy: 'guest', body: '', attachments: [], createdAt: written_at },
          { _id: 'post_untyped_attachment', sentBy: 'guest', body: '', createdAt: written_at,
            attachments: [{ attachmentUrl: 'production/account/file/photo.bin', origFileName: 'photo.bin' }] },
          { _id: 'post_auto', sentBy: 'host', body: 'Your check-in details', isAutomatic: true, createdAt: written_at },
          { _id: 'post_note', sentBy: 'guest', body: 'Internal note', module: { type: 'note' }, createdAt: written_at },
          { _id: 'post_alteration', sentBy: 'log', body: 'Alteration request received', module: { type: 'log', reservationId: 'reservation-1' }, createdAt: written_at },
          { _id: 'post_undated', sentBy: 'guest', body: 'Guesty forgot to date this one' },
          { _id: 'post_kept', sentBy: 'guest', body: 'Still here', createdAt: written_at }
        ]
      end

      before do
        stub_request(:get, endpoint).with(query: hash_including({}))
                                    .to_return(status: 200, body: { status: 200,
                                                                    data: { count: posts.size, posts:,
                                                                            cursor: { after: '' } } }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it_behaves_like 'successful call', value: -> {
        {
          results: [
            provider_post(provider_message_id: 'post_untyped_attachment', sender_kind: 'guest', body: '', provider_occurred_at: Time.zone.iso8601(written_at),
                          attachments: ['application/octet-stream'], attachment_keys: ['production/account/file/photo.bin']),
            provider_post(provider_message_id: 'post_auto', sender_kind: 'system', body: 'Your check-in details', provider_occurred_at: Time.zone.iso8601(written_at)),
            provider_post(provider_message_id: 'post_alteration', sender_kind: 'system', body: 'Alteration request received',
                          provider_reservation_id: 'reservation-1', provider_occurred_at: Time.zone.iso8601(written_at)),
            provider_post(provider_message_id: 'post_kept', sender_kind: 'guest', body: 'Still here', provider_occurred_at: Time.zone.iso8601(written_at))
          ],
          cursor_after: nil,
          oldest_created_at: Time.zone.iso8601(written_at)
        }
      }
    end
  end
end
