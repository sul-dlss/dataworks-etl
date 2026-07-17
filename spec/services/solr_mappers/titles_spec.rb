# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrMappers::Titles do
  subject(:fields) { described_class.call(metadata:) }

  context 'when a title contains entity-encoded markup' do
    let(:metadata) { { titles: [{ title: '&lt;i&gt;Asclepias&lt;/i&gt; in California' }] } }

    it 'stores plain text in the searchable field' do
      expect(fields[:title_tsim]).to eq(['Asclepias in California'])
    end

    it 'stores sanitized HTML retaining italics in the display field' do
      expect(fields[:title_html_tsm]).to eq(['<i>Asclepias</i> in California'])
    end
  end

  context 'when a title contains raw allowed and disallowed tags' do
    let(:metadata) { { titles: [{ title: 'H<sub>2</sub>O and <b>bold</b> notes' }] } }

    it 'keeps sub/sup but drops other tags in the display field' do
      expect(fields[:title_html_tsm]).to eq(['H<sub>2</sub>O and bold notes'])
    end

    it 'strips all tags in the searchable field' do
      expect(fields[:title_tsim]).to eq(['H2O and bold notes'])
    end
  end

  context 'when a title has no markup' do
    let(:metadata) { { titles: [{ title: 'Plain title' }] } }

    it 'populates both fields with the same text' do
      expect(fields[:title_tsim]).to eq(['Plain title'])
      expect(fields[:title_html_tsm]).to eq(['Plain title'])
    end
  end
end
