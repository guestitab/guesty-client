module Guesty
  module Webhooks
    # Subscribes the urls to the events: creates the missing, updates the
    # drifted, leaves the rest. Returns the urls grouped by :created, :updated,
    # :unchanged.
    class Sync
      include Guesty::Operation

      # @rbs (urls: ::Array[::String], events: ::Array[::String]) -> Dry::Monads::Result[::Hash[::Symbol, ::Array[::String]]]
      def call(urls:, events:)
        argument! urls: :required if urls.blank?
        argument! events: :required if events.blank?

        webhooks = Index.new.call!.value!
        existing = webhooks.index_by { |webhook| webhook[:url].strip }

        Success(urls.group_by { |url| reconcile(url, events, existing[url]) })
      end

      private

      # @rbs (::String url, ::Array[::String] events, ::Hash[::Symbol, untyped]? current) -> ::Symbol
      def reconcile(url, events, current)
        if current.nil?
          Create.new.call!(url:, events:)
          :created
        elsif current[:events].to_set != events.to_set
          Update.new.call!(id: current[:_id], url:, events:)
          :updated
        else
          :unchanged
        end
      end
    end
  end
end
