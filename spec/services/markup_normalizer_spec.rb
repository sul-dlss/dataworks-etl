# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarkupNormalizer do
  describe '.to_text' do
    it 'decodes entity-encoded markup and strips the tags' do
      expect(described_class.to_text('&lt;i&gt;Genus&lt;/i&gt; species')).to eq('Genus species')
    end

    it 'strips raw tags and collapses whitespace' do
      expect(described_class.to_text("<p>Line one</p>\n<p>Line two</p>")).to eq('Line one Line two')
    end

    it 'returns plain input unchanged' do
      expect(described_class.to_text('Just text')).to eq('Just text')
    end

    it 'returns blank input unchanged' do
      expect(described_class.to_text(nil)).to be_nil
    end

    it 'normalizes literal and entity-encoded ampersands to the same plain "&"' do
      expect(described_class.to_text('Salt & Pepper')).to eq('Salt & Pepper')
      expect(described_class.to_text('Salt &amp; Pepper')).to eq('Salt & Pepper')
    end

    it 'decodes numeric character references, including double-encoded' do
      expect(described_class.to_text('Darwin&#39;s finches')).to eq("Darwin's finches")
      expect(described_class.to_text('Darwin&amp;#39;s finches')).to eq("Darwin's finches")
    end

    it 'converges named and numeric forms of the same character' do
      expect(described_class.to_text('the &quot;big&quot; one')).to eq('the "big" one')
      expect(described_class.to_text('the &#34;big&#34; one')).to eq('the "big" one')
    end
  end

  describe '.to_html' do
    let(:tags) { %w[i em sub sup] }

    it 'retains allowed tags from entity-encoded markup' do
      expect(described_class.to_html('&lt;i&gt;Genus&lt;/i&gt;', tags:)).to eq('<i>Genus</i>')
    end

    it 'keeps sub and sup tags' do
      expect(described_class.to_html('H<sub>2</sub>O and x<sup>2</sup>',
                                     tags:)).to eq('H<sub>2</sub>O and x<sup>2</sup>')
    end

    it 'drops disallowed tags but keeps their text' do
      expect(described_class.to_html('<b>bold</b> and <span>span</span>', tags:)).to eq('bold and span')
    end

    it 'removes dangerous tags, leaving only their inert text' do
      expect(described_class.to_html('safe<script>alert(1)</script>', tags:)).to eq('safealert(1)')
    end

    it 'strips attributes from allowed tags' do
      expect(described_class.to_html('<i class="x" onclick="y()">t</i>', tags:)).to eq('<i>t</i>')
    end

    it 'renders literal and encoded ampersands identically as a safe "&amp;"' do
      encoded = described_class.to_html('Salt &amp; Pepper', tags:)
      expect(described_class.to_html('Salt & Pepper', tags:)).to eq(encoded)
      expect(encoded).to eq('Salt &amp; Pepper')
    end

    it 'decodes numeric references without re-encoding ordinary characters' do
      expect(described_class.to_html('Darwin&#39;s finches', tags:)).to eq("Darwin's finches")
    end
  end

  # A stray "<" (one that does not close with a ">") is kept literal rather than
  # being misparsed as an unclosed tag that truncates the trailing text. Tags
  # that do close (well-formed) still flow to the stripper/sanitizer as usual.
  describe 'stray "<" handling' do
    let(:tags) { %w[i em sub sup] }

    it 'keeps an unclosed "<letter" literal instead of truncating' do
      expect(described_class.to_text('x<y interaction')).to eq('x<y interaction')
      expect(described_class.to_html('x<y interaction', tags:)).to eq('x&lt;y interaction')
    end

    it 'still drops well-formed non-allowlisted tags, keeping their text' do
      expect(described_class.to_text('<b>bold</b> text')).to eq('bold text')
      expect(described_class.to_html('<b>bold</b> text', tags:)).to eq('bold text')
    end
  end
end
