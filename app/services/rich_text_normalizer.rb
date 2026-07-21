# frozen_string_literal: true

require 'cgi'

# Normalizes rich, multi-paragraph text (dataset descriptions) into two Solr
# representations:
#   - #to_text: plain text for search — block structure flattened to spaces
#   - #to_html: sanitized semantic HTML for display (presentational wrapping such
#     as simple_format is applied at render time, not here)
#
# Unlike MarkupNormalizer (single-line values like titles/subjects), this
# preserves block structure and does NOT collapse all whitespace, so paragraphs
# and lists survive in the display HTML and read as word boundaries in the text.
class RichTextNormalizer
  ALLOWED_TAGS = %w[a b i em strong sub sup p br ul ol li table thead tbody tr th td colgroup col].freeze
  ALLOWED_ATTRIBUTES = %w[href].freeze
  SANITIZER = Rails::HTML::SafeListSanitizer.new
  # Block-level tag ends (and <br>) that should read as a word boundary in text.
  BLOCK_BOUNDARY = %r{</(?:p|div|li|h[1-6]|tr|blockquote|ul|ol|table|thead|tbody)>|<br\s*/?>}i

  # @return [String, nil] plain text with tags removed and block boundaries
  #   preserved as single spaces. Blank input is returned unchanged.
  def self.to_text(value)
    return value if value.blank?

    boundaried = CGI.unescapeHTML(value.to_s).gsub(BLOCK_BOUNDARY, ' ')
    Nokogiri::HTML.fragment(boundaried).text.gsub(/\s+/, ' ').strip
  end

  # @return [String, nil] sanitized semantic HTML: allowlisted tags only, no
  #   attributes but href, presentational cruft (e.g. <span style=...>) dropped.
  #   Presentational wrapping (simple_format, the display div) happens at render time.
  def self.to_html(value)
    return value if value.blank?

    SANITIZER.sanitize(CGI.unescapeHTML(value.to_s), tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES).strip
  end
end
