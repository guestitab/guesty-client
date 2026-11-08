module Guesty
  module Homes
    module Calendars
      class Show
        include Guesty::Operation

        BLOCK_TYPE_MAPPING = {
          m: :manual_block,
          r: :reserved_date,
          b: :booked_reservation,
          bd: :blocked_by_default,
          sr: :smart_calendar_rule,
          abl: :annual_booking_limit,
          a: :allotment_block,
          bw: :booking_window,
          o: :owner_reservation,
          pt: :preparation_time,
          ic: :ical_import,
          an: :advance_notice,
          cio: :check_in_out
        }.freeze

        # @rbs (home_id: ::String, start_date: ::Date, end_date: ::Date) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
        def call(home_id:, start_date:, end_date:)
          argument! home_id: :required if home_id.blank?
          argument! end_date: :invalid if end_date <= start_date

          response = fetch_calendar_data(home_id, start_date, end_date)

          raise response.failure if response.failure?

          Success(normalize_calendar(response.value!.body))
        end

        private

        def fetch_calendar_data(home_id, start_date, end_date)
          params = {
            startDate: start_date,
            endDate: end_date,
            view: 'full'
          }

          Guesty.do_request :get, "availability-pricing/api/calendar/listings/minified/#{home_id}", params
        end

        def normalize_calendar(body)
          calendar = body.dig(:data, :days) || {}
          @blocks = calendar[:blocks] || {}
          @days = calendar[:calendar] || []
          available, unavailable = @days.partition { |day| available_day?(day) }

          validate_currency(calendar[:currency], @days)

          {
            available: attrs_for_available(available),
            unavailable: attrs_for_unavailable(unavailable),
            blocks: attrs_for_blocks
          }
        end

        # The host prices in one currency; a listing in another would silently
        # misprice. Skipped when the host has not configured one.
        # @rbs (::String? currency, ::Array[::Hash[::Symbol, untyped]] days) -> void
        def validate_currency(currency, days)
          return nil if days.empty? || Guesty.config.default_currency.nil?
          return nil if currency.to_s.upcase == Guesty.config.default_currency

          error! "unsupported currency #{currency}"
        end

        # @rbs (::Hash[::Symbol, untyped] day) -> bool
        def available_day?(day)
          day[:blocks].empty? || day_is_available_for_checkout?(day)
        end

        # @rbs (::Hash[::Symbol, untyped] day) -> bool
        def day_is_available_for_checkout?(day)
          return false if day[:blocks].except(:b).any?
          return false if previous_night_blocked?(day)

          day[:blockIds].any? { |id| @blocks.dig(id.to_sym, :reservation, :checkInDateLocalized) == day[:date] }
        end

        # @rbs (::Hash[::Symbol, untyped] day) -> bool
        def previous_night_blocked?(day)
          blocked_dates.include?(day[:date].to_date.prev_day.iso8601)
        end

        # @rbs () -> ::Set[::String]
        def blocked_dates
          @blocked_dates ||= @days.reject { |day| day[:blocks].empty? }.to_set { |day| day[:date] }
        end

        # @rbs (::Array[::Hash[::Symbol, untyped]] days) -> ::Array[::Hash[::Symbol, untyped]]
        def attrs_for_available(days)
          days.map do |day|
            {
              date: day[:date],
              price: day[:price],
              min_nights: day[:minNights],
              check_in: day[:blocks].empty?
            }
          end
        end

        # @rbs (::Array[::Hash[::Symbol, untyped]] days) -> ::Array[::Hash[::Symbol, untyped]]
        def attrs_for_unavailable(days)
          days.map do |day|
            {
              date: day[:date],
              price: day[:price],
              min_nights: day[:minNights],
              check_in: false,
              blocked_as: day[:blocks].keys.filter_map { |key| BLOCK_TYPE_MAPPING[key] }
            }
          end
        end

        # @rbs () -> ::Array[::Hash[::Symbol, untyped]]
        def attrs_for_blocks
          @blocks.values.map do |block|
            {
              kind: BLOCK_TYPE_MAPPING[block[:type].to_sym],
              start_date: block[:startDate].to_date,
              end_date: block[:endDate].to_date,
              comment: block[:note].presence
            }
          end
        end
      end
    end
  end
end
