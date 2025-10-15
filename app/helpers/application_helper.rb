# frozen_string_literal: true

module ApplicationHelper
  BYTES_REGEX = /^([\d.]+)\s*(bytes|kilobytes|megabytes|gigabytes|terabytes|b|kb|mb|gb|tb)?$/i

  # Given a string like "5 MB" or "1.2 GB", return the number of bytes as an integer
  # rubocop:disable Metrics/CyclomaticComplexity
  def number_from_human_size(size)
    return unless size.is_a?(String)

    match = size.match(BYTES_REGEX)
    return unless match

    number = match[1].to_f
    unit = match[2]&.downcase

    multiplier = case unit
                 when 'kilobytes', 'kb' then 1024
                 when 'megabytes', 'mb' then 1024**2
                 when 'gigabytes', 'gb' then 1024**3
                 when 'terabytes', 'tb' then 1024**4
                 else 1
                 end

    (number * multiplier).to_i
  rescue StandardError
    nil
  end
  # rubocop:enable Metrics/CyclomaticComplexity
end
