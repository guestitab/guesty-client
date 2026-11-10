module Guesty
  module Views
    class Update
      include Guesty::Operation

      # @rbs (id: ::String, ?title: ::String?, ?fields: ::String?, ?filters: ::Array[::Hash[::Symbol, untyped]]?, ?sort: ::String?) -> Dry::Monads::Result[untyped]
      def call(id:, title: nil, fields: nil, filters: nil, sort: nil)
        argument! id: :required if id.blank?
        argument! attributes: :invalid if [title, fields, filters, sort].all?(&:nil?)

        Success(request(:put, "views/#{id}", { _id: id, title:, fields:, filters:, sort: }.compact))
      end
    end
  end
end
