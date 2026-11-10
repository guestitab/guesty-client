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

          body = request(:get, "availability-pricing/api/calendar/listings/minified/#{home_id}", { startDate: start_date, endDate: end_date, view: 'full' })

          Success(normalize_calendar(body.dig(:data, :days) || {}))
        end

        private

        # @rbs (::Hash[::Symbol, untyped] calendar) -> ::Hash[::Symbol, untyped]
        def normalize_calendar(calendar)
          @blocks = calendar[:blocks] || {}
          @days = calendar[:calendar] || []
          validate_currency(calendar[:currency])

          available, unavailable = @days.partition { |day| available_day?(day) }

          {
            available: available.map { |day| day_attributes(day, check_in: day[:blocks].empty?) },
            unavailable: unavailable.map { |day| day_attributes(day, check_in: false, blocked_as: day[:blocks].keys.filter_map { BLOCK_TYPE_MAPPING[it] }) },
            blocks: @blocks.values.map { |block| block_attributes(block) }
          }
        end

        # The host prices in one currency; a listing in another would silently
        # misprice. Skipped when the host has not configured one.
        # @rbs (::String? currency) -> void
        def validate_currency(currency)
          return if @days.empty? || Guesty.config.default_currency.nil?
          return if currency.to_s.upcase == Guesty.config.default_currency

          error! "unsupported currency #{currency}"
        end

        # @rbs (::Hash[::Symbol, untyped] day) -> bool
        def available_day?(day)
          day[:blocks].empty? || available_for_checkout?(day)
        end

        # A day booked only by a reservation checking in that day still takes a
        # check-out, unless the night before is blocked too.
        # @rbs (::Hash[::Symbol, untyped] day) -> bool
        def available_for_checkout?(day)
          return false if day[:blocks].except(:b).any?
          return false if blocked_dates.include?(day[:date].to_date.prev_day.iso8601)

          day[:blockIds].any? { |id| @blocks.dig(id.to_sym, :reservation, :checkInDateLocalized) == day[:date] }
        end

        # @rbs () -> ::Set[::String]
        def blocked_dates
          @blocked_dates ||= @days.reject { |day| day[:blocks].empty? }.to_set { |day| day[:date] }
        end

        # @rbs (::Hash[::Symbol, untyped] day, **untyped) -> ::Hash[::Symbol, untyped]
        def day_attributes(day, **attributes)
          { date: day[:date], price: day[:price], min_nights: day[:minNights], **attributes }
        end

        # @rbs (::Hash[::Symbol, untyped] block) -> ::Hash[::Symbol, untyped]
        def block_attributes(block)
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
