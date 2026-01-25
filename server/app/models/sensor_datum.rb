

class SensorDatum < ApplicationRecord
    validates :sensor_code, presence: true
    validates :value, presence: true

    # Scopes for filtering
    scope :for_sensor, ->(sensor_code) { where(sensor_code: sensor_code) }
    scope :after, ->(time) { where("created_at >= ?", time) if time }
    scope :before, ->(time) { where("created_at <= ?", time) if time }
    scope :in_date_range, ->(after_time, before_time) { after(after_time).before(before_time) }
    scope :recent_first, -> { order(created_at: :desc) }

    # Pagination scope
    scope :paginate, ->(page: 1, per_page: 50, max_per_page: 100) {
        page = page.to_i > 0 ? page.to_i : 1
        per_page = per_page.to_i > 0 ? [per_page.to_i, max_per_page].min : 50
        offset((page - 1) * per_page).limit(per_page)
    }

    # Parse ISO8601 timestamp safely
    def self.parse_iso8601(time_string)
        return nil unless time_string.present?
        Time.iso8601(time_string) rescue nil
    end

    # Returns aggregated summaries grouped by period (daily, weekly, monthly)
    # 
    # @param period_type [String] One of: 'daily', 'weekly', 'monthly'
    # @return [ActiveRecord::Relation] Relation with aggregated data
    def self.summarize_by_period(period_type)
        group_expression = period_group_expression(period_type)
        
        select(
            "#{group_expression} as period_key",
            "MIN(created_at) as first_reading",
            "MAX(created_at) as last_reading",
            "AVG(CAST(value AS FLOAT)) as average",
            "MIN(CAST(value AS FLOAT)) as min_value",
            "MAX(CAST(value AS FLOAT)) as max_value",
            "COUNT(*) as count"
        )
        .group(group_expression)
        .order("period_key DESC")
    end

    # Format summary records into a response-ready array
    #
    # @param summaries [ActiveRecord::Relation] Result from summarize_by_period
    # @param period_type [String] One of: 'daily', 'weekly', 'monthly'
    # @return [Array<Hash>] Array of formatted summary hashes
    def self.format_summaries(summaries, period_type)
        summaries.map do |s|
            period_start, period_end = calculate_period_boundaries(s.period_key, period_type)
            {
                period_start: period_start.iso8601,
                period_end: period_end.iso8601,
                average: s.average&.round(2),
                min: s.min_value&.to_f,
                max: s.max_value&.to_f,
                count: s.count
            }
        end
    end

    # Valid period types for summary aggregation
    VALID_PERIOD_TYPES = %w[daily weekly monthly].freeze

    def self.valid_period_type?(period_type)
        VALID_PERIOD_TYPES.include?(period_type)
    end

    # Valid "last" period types
    VALID_LAST_PERIODS = %w[day week month year all].freeze

    def self.valid_last_period?(period)
        VALID_LAST_PERIODS.include?(period)
    end

    # Returns the time threshold for "last" period queries
    # @param period [String] One of: 'day', 'week', 'month', 'year', 'all'
    # @param reference_time [Time] The reference time (defaults to now)
    # @return [Time, nil] The start time for the query, or nil for 'all'
    def self.last_period_start_time(period, reference_time = Time.current)
        case period
        when 'day'
            reference_time - 24.hours
        when 'week'
            reference_time - 7.days
        when 'month'
            reference_time - 30.days
        when 'year'
            reference_time - 365.days
        when 'all'
            nil
        else
            raise ArgumentError, "Invalid last period: #{period}"
        end
    end

    # Scope for filtering data within a "last" period
    scope :in_last_period, ->(period, reference_time = Time.current) {
        start_time = SensorDatum.last_period_start_time(period, reference_time)
        start_time ? where("created_at >= ?", start_time) : all
    }

    private

    # Returns the SQL group expression for the given period type
    def self.period_group_expression(period_type)
        case period_type
        when 'daily'
            "date(created_at)"
        when 'weekly'
            # SQLite: strftime('%W') gives week number, combine with year
            "strftime('%Y-%W', created_at)"
        when 'monthly'
            "strftime('%Y-%m', created_at)"
        else
            raise ArgumentError, "Invalid period_type: #{period_type}"
        end
    end

    # Calculate the theoretical start and end of a period based on period_key
    #
    # @param period_key [String] The period identifier (e.g., "2025-08-01", "2025-32", "2025-08")
    # @param period_type [String] One of: 'daily', 'weekly', 'monthly'
    # @return [Array<Time>] [period_start, period_end] in UTC
    def self.calculate_period_boundaries(period_key, period_type)
        case period_type
        when 'daily'
            # period_key is "YYYY-MM-DD"
            date = Date.parse(period_key)
            period_start = date.beginning_of_day
            period_end = date.end_of_day
        when 'weekly'
            # period_key is "YYYY-WW"
            year, week = period_key.split('-').map(&:to_i)
            # Find the Monday of that week
            jan_first = Date.new(year, 1, 1)
            # Week 0 or 1 handling
            days_to_add = (week * 7) - jan_first.wday + 1
            monday = jan_first + days_to_add.days
            period_start = monday.beginning_of_day
            period_end = (monday + 6.days).end_of_day
        when 'monthly'
            # period_key is "YYYY-MM"
            date = Date.parse("#{period_key}-01")
            period_start = date.beginning_of_month.beginning_of_day
            period_end = date.end_of_month.end_of_day
        end
        
        [period_start.utc, period_end.utc]
    end
end