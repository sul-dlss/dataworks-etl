# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RichTextNormalizer do
  describe '.to_text' do
    it 'flattens block boundaries to single spaces' do
      expect(described_class.to_text('<p>Para one</p><p>Para two</p>')).to eq('Para one Para two')
    end

    it 'treats <br> as a word boundary' do
      expect(described_class.to_text('Line one<br>Line two')).to eq('Line one Line two')
    end

    it 'treats list items as word boundaries' do
      expect(described_class.to_text('<ul><li>one</li><li>two</li></ul>')).to eq('one two')
    end

    it 'removes inline markup while keeping the text' do
      expect(described_class.to_text('H<sub>2</sub>O and <em>italics</em>')).to eq('H2O and italics')
    end

    it 'decodes HTML entities' do
      expect(described_class.to_text('R&amp;D budget')).to eq('R&D budget')
    end

    it 'collapses runs of whitespace' do
      expect(described_class.to_text("lots   of\n\n  space")).to eq('lots of space')
    end

    it 'returns a blank string unchanged' do
      expect(described_class.to_text('')).to eq('')
    end

    it 'returns nil unchanged' do
      expect(described_class.to_text(nil)).to be_nil
    end
  end

  describe '.to_html' do
    it 'keeps allowlisted inline tags' do
      expect(described_class.to_html('<em>italic</em> and H<sub>2</sub>O')).to eq('<em>italic</em> and H<sub>2</sub>O')
    end

    it 'keeps block structure such as paragraphs' do
      expect(described_class.to_html('<p>One</p><p>Two</p>')).to eq('<p>One</p><p>Two</p>')
    end

    it 'drops presentational cruft while keeping the inner text' do
      expect(described_class.to_html('<p><span style="color:red">styled</span> text</p>')).to eq('<p>styled text</p>')
    end

    it 'keeps only the href attribute' do
      expect(described_class.to_html('<a href="http://x" onclick="evil()">link</a>')).to eq('<a href="http://x">link</a>')
    end

    it 'removes script tags, leaving the surrounding text' do
      expect(described_class.to_html('<script>alert(1)</script>Safe')).to eq('alert(1)Safe')
    end

    it 'unwraps a non-allowlisted inline tag, keeping its text' do
      expect(described_class.to_html('Before <mark>highlighted</mark> after')).to eq('Before highlighted after')
    end

    it 'strips a non-allowlisted block tag while keeping an allowlisted sibling' do
      expect(described_class.to_html('<h2>Heading</h2><p>Body</p>')).to eq('Heading<p>Body</p>')
    end

    it 'returns a blank string unchanged' do
      expect(described_class.to_html('')).to eq('')
    end

    it 'returns nil unchanged' do
      expect(described_class.to_html(nil)).to be_nil
    end
  end
end
