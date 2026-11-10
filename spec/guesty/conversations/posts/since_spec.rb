RSpec.describe Guesty::Conversations::Posts::Since do
  include_context 'operations'

  let(:args) { { conversation_id:, since: } }

  let(:conversation_id) { 'guesty-conversation-1' }
  let(:since) { nil }

  context 'with valid arguments' do
    let(:posts_index) { operation_stub(Guesty::Conversations::Posts::Index) }
    let(:newest_post) do
      provider_post(provider_message_id: 'newest-post', sender_kind: 'guest', body: 'And the wifi code?', module_type: 'airbnb2',
                    provider_occurred_at: Time.zone.local(2026, 1, 3, 10))
    end
    let(:older_post) { newest_post.merge(provider_message_id: 'older-post', body: 'What is the check-in code?', provider_occurred_at: Time.zone.local(2026, 1, 2, 10)) }

    before { allow(posts_index).to receive(:call).and_return(*pages) }

    def page(posts, cursor_after: nil, oldest_created_at: posts.pluck(:provider_occurred_at).min)
      Success({ results: posts, cursor_after:, oldest_created_at: })
    end

    context 'when the first page has no cursor_after' do
      let(:pages) { [page([newest_post, older_post])] }

      it_behaves_like 'successful call', value: -> { [newest_post, older_post] }
    end

    context 'when a page has a cursor_after' do
      let(:pages) { [page([newest_post], cursor_after: 'older-page'), page([older_post])] }

      before { result }

      it_behaves_like 'successful call', value: -> { [newest_post, older_post] }

      it 'calls Guesty::Conversations::Posts::Index with the cursor_after' do
        expect(posts_index).to have_received(:call).with(conversation_id:, cursor: 'older-page')
      end
    end

    context 'with since' do
      context 'when a page reaches it exactly' do
        let(:since) { older_post[:provider_occurred_at] }
        let(:pages) { [page([newest_post], cursor_after: 'older-page'), page([older_post], cursor_after: 'oldest-page')] }

        it_behaves_like 'successful call', value: -> { [newest_post, older_post] }
      end

      context 'when a page stops a second short of it' do
        let(:since) { older_post[:provider_occurred_at] - 1.second }
        let(:pages) { [page([newest_post], cursor_after: 'older-page'), page([older_post], cursor_after: 'oldest-page'), page([])] }

        it_behaves_like 'successful call', value: -> { [newest_post, older_post] }
      end

      context 'when the first page reaches back past it' do
        let(:since) { Time.zone.local(2026, 1, 2, 12) }
        let(:pages) { [page([newest_post, older_post], cursor_after: 'older-page')] }

        it_behaves_like 'successful call', value: -> { [newest_post, older_post] }
      end

      context 'when a page that reaches it holds no post' do
        let(:since) { Time.zone.local(2026, 1, 2, 12) }
        let(:pages) { [page([], cursor_after: 'older-page', oldest_created_at: since - 1.second)] }

        it_behaves_like 'successful call', value: []
      end
    end

    context 'when the pages exceed MAX_PAGES' do
      let(:pages) { [page([newest_post], cursor_after: 'older-page'), page([older_post], cursor_after: 'oldest-page')] }
      let(:message) { "Guesty conversation #{conversation_id} pagination exceeded 2 pages" }
      let(:fatal) { true }

      before { stub_const("#{described_class}::MAX_PAGES", 2) }

      it_behaves_like 'failed call', failure_class: Guesty::Error

      context 'when the pages end at MAX_PAGES' do
        let(:pages) { [page([newest_post], cursor_after: 'older-page'), page([older_post])] }

        it_behaves_like 'successful call', value: -> { [newest_post, older_post] }
      end
    end
  end
end
