module ProviderPostHelpers
  # One normalized channel-manager post as the provider emits it, with the quiet members defaulted. The provider parses
  # `createdAt` with `Time.iso8601`, so the time is a UTC `::Time`.
  def provider_post(provider_occurred_at:, **attributes)
    { attachments: [], attachment_keys: [], module_type: nil, provider_reservation_id: nil, author_name: nil, **attributes, provider_occurred_at: provider_occurred_at.utc }
  end
end

RSpec.configure do |config|
  config.include ProviderPostHelpers
end
