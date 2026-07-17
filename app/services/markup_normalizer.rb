# frozen_string_literal: true

require 'cgi'

# Normalizes source metadata strings that may carry HTML markup — either raw
# (<i>foo</i>) or entity-encoded (&lt;i&gt;foo&lt;/i&gt;) — into one of two
# representations for Solr:
#
#   - #to_text: all markup removed, for searchable/faceted/sortable fields
#   - #to_html: sanitized HTML limited to an allowlist, for display fields
#
# Markup arrives both raw and entity-encoded, so values are HTML-entity-decoded
# first. That turns an intended &lt;i&gt; into a real <i> tag, which
# can then be handled consistently.
class MarkupNormalizer
  SANITIZER = Rails::HTML::SafeListSanitizer.new

  # @param value [String, nil]
  # @return [String, nil] the value with all HTML removed, entities decoded, and
  #   whitespace collapsed. Blank input is returned unchanged.
  def self.to_text(value)
    return value if value.blank?

    Nokogiri::HTML.fragment(prepare(value)).text.squish
  end

  # @param value [String, nil]
  # @param tags [Array<String>] the HTML tags permitted in the output
  # @return [String, nil] sanitized HTML retaining only the allowed tags (with no
  #   attributes) and collapsed whitespace. Blank input is returned unchanged.
  def self.to_html(value, tags:)
    return value if value.blank?

    SANITIZER.sanitize(prepare(value), tags: tags, attributes: []).squish
  end

  # Decode HTML entities so raw and entity-encoded markup are handled the same,
  # then neutralize a stray "<" that would otherwise be misparsed as an unclosed
  # tag and drop the text after it. A "<" is escaped unless a ">" closes it before
  # the next "<" or end of string, so well-formed tags (e.g. <sub>) still flow to
  # the sanitizer while a literal "x<y" is preserved.
  def self.prepare(value)
    CGI.unescapeHTML(value.to_s).gsub(/<(?![^<>]*>)/, '&lt;')
  end
  private_class_method :prepare
end
