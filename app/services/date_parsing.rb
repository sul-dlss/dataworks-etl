# frozen_string_literal: true

# Date parsing service to extract date ranges and other formats.
class DateParsing
  # Regex for a date range pattern with a slash: 2023-01-02T19:20:30+01:00/2025-01-01
  DATESTR_REGEX = %r/\b(\d{4})\b.*?\/.*?\b(\d{4})\b/im

  # Parses a date range string and returns an array of all years in the range
  #
  # @param date_range_string [String] The date range string to parse.
  # @return [Array<int>, nil] The range from parsed start to end dates or nil if invalid.
  def self.parse_date_range(date_range_string)
    return nil if date_range_string.blank?
    return nil unless date_range_string.match(DATESTR_REGEX)

    # Extract the start and end dates from the matched pattern
    (Regexp.last_match(1).to_i..Regexp.last_match(2).to_i).to_a
  end
end
