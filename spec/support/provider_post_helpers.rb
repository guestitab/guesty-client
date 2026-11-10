module ProviderPostHelpers
  def provider_post(provider_occurred_at:, **attributes)
    { attachments: [], attachment_keys: [], module_type: nil, provider_reservation_id: nil, author_name: nil, **attributes, provider_occurred_at: provider_occurred_at.utc }
  end
end

RSpec.configure do |config|
  config.include ProviderPostHelpers
end
