# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DatasetConsolidator do
  let(:dataset_consolidator) { described_class.new(solr_docs:) }

  describe '#removal_dois_set' do
    let(:solr_docs) do
      [
        { 'doi_ssi' => '10.18112/a.ds001',
          'related_identifiers_struct_ss' =>
          '[{"related_identifier":"10.18112/b.ds001","relation_type":"IsPreviousVersionOf"}]' },
        { 'doi_ssi' => '10.18112/b.ds001' },
        { 'doi_ssi' => '10.18112/c.ds001.v1' },
        { 'doi_ssi' => '10.18112/c.ds001.v2' },
        { 'doi_ssi' => '10.18112/d.ds001',
          'related_identifiers_struct_ss' =>
          '[{"related_identifier":"10.18112/e.ds001","relation_type":"IsPartOf"}]' },
        { 'doi_ssi' => '10.18112/e.ds001' }
      ]
    end

    it 'list DOIs to remove based on a combination of relationships and version numbering' do
      remove_dois = dataset_consolidator.removal_dois_set
      expect(remove_dois).to contain_exactly('10.18112/a.ds001', '10.18112/c.ds001.v1', '10.18112/d.ds001')
    end
  end

  describe '#remove_by_relation_types' do
    context 'when IsPreviousVersionOf connects DOI to a previous existing DOI' do
      let(:solr_docs) do
        [
          { 'doi_ssi' => '10.18112/a.ds001',
            'related_identifiers_struct_ss' =>
            '[{"related_identifier":"10.18112/b.ds001","relation_type":"IsPreviousVersionOf"}]' },
          { 'doi_ssi' => '10.18112/b.ds001',
            'related_identifiers_struct_ss' =>
            '[{"related_identifier":"10.18112/c.ds001","relation_type":"IsPreviousVersionOf"}]' },
          { 'doi_ssi' => '10.18112/c.ds001' }
        ]
      end

      it 'adds all previous versions to the removal list when current version is in our set' do
        remove_dois = dataset_consolidator.remove_by_relation_types
        expect(remove_dois).to contain_exactly('10.18112/a.ds001', '10.18112/b.ds001')
      end
    end

    context 'when IsNewVersionOf connects DOI to a new existing DOI' do
      let(:solr_docs) do
        [
          { 'doi_ssi' => '10.18112/a.ds001',
            'related_identifiers_struct_ss' =>
            '[{"related_identifier":"10.18112/b.ds001","relation_type":"IsNewVersionOf"}]' },
          { 'doi_ssi' => '10.18112/b.ds001',
            'related_identifiers_struct_ss' =>
            '[{"related_identifier":"10.18112/c.ds001","relation_type":"IsNewVersionOf"}]' },
          { 'doi_ssi' => '10.18112/c.ds001' }
        ]
      end

      it 'adds all previous versions to the removal list when current version is in our set' do
        remove_dois = dataset_consolidator.remove_by_relation_types
        expect(remove_dois).to contain_exactly('10.18112/b.ds001', '10.18112/c.ds001')
      end
    end

    context 'when HasVersion and IsNewVersionOf connect DOIs to existing DOI' do
      let(:solr_docs) do
        [
          { 'doi_ssi' => '10.18112/a.ds001',
            'related_identifiers_struct_ss' =>
            '[{"related_identifier":"10.18112/b.ds001","relation_type":"HasVersion"}]' },
          { 'doi_ssi' => '10.18112/b.ds001' },
          { 'doi_ssi' => '10.18112/c.ds001',
            'related_identifiers_struct_ss' =>
            '[{"related_identifier":"10.18112/d.ds001","relation_type":"IsVersionOf"}]' },
          { 'doi_ssi' => '10.18112/d.ds001' }
        ]
      end

      it 'adds object of HasVersion and subject of IsVersionOf to removal list' do
        remove_dois = dataset_consolidator.remove_by_relation_types
        expect(remove_dois).to contain_exactly('10.18112/b.ds001', '10.18112/c.ds001')
      end
    end

    context 'when HasPart and IsPartOf connect DOIs to existing DOI' do
      let(:solr_docs) do
        [
          { 'doi_ssi' => '10.18112/a.ds001',
            'related_identifiers_struct_ss' =>
            '[{"related_identifier":"10.18112/b.ds001","relation_type":"HasPart"}]' },
          { 'doi_ssi' => '10.18112/b.ds001' },
          { 'doi_ssi' => '10.18112/c.ds001',
            'related_identifiers_struct_ss' =>
            '[{"related_identifier":"10.18112/d.ds001","relation_type":"IsPartOf"}]' },
          { 'doi_ssi' => '10.18112/d.ds001' }
        ]
      end

      it 'adds object of HasPart and subject of IsPartOf to removal list' do
        remove_dois = dataset_consolidator.remove_by_relation_types
        expect(remove_dois).to contain_exactly('10.18112/b.ds001', '10.18112/c.ds001')
      end
    end

    context 'when the relation type connects DOI to a DOI we do not have' do
      let(:solr_docs) do
        [
          { 'doi_ssi' => '10.18112/a.ds001',
            'related_identifiers_struct_ss' =>
            '[{"related_identifier":"10.18112/x.ds001","relation_type":"IsPreviousVersionOf"}]' },
          { 'doi_ssi' => '10.18112/b.ds001',
            'related_identifiers_struct_ss' =>
            '[{"related_identifier":"10.18112/y.ds001","relation_type":"HasNewVersion"}]' }
        ]
      end

      it 'does not choose DOIs for removal if related DOIs are not in our DOI set' do
        remove_dois = dataset_consolidator.remove_by_relation_types
        expect(remove_dois.length).to eq(0)
      end
    end
  end

  describe '#remove_by_version_number' do
    context 'when only multiple numbered versions exist' do
      let(:solr_docs) do
        [
          { 'doi_ssi' => '10.18112/a.ds001.v1.01.01' },
          { 'doi_ssi' => '10.18112/a.ds001.v1.02' },
          { 'doi_ssi' => '10.18112/a.ds001.v1.03' },
          { 'doi_ssi' => '10.18112/b.ds001.v1' },
          { 'doi_ssi' => '10.18112/b.ds001.v2' },
          { 'doi_ssi' => '10.18112/b.ds001.v3' },
          { 'doi_ssi' => '10.18112/b.ds001.v11' }
        ]
      end

      it 'lists all lower version numbers for removal' do
        remove_dois = dataset_consolidator.remove_by_version_number([
                                                                      '10.18112/a.ds001.v1.01.01',
                                                                      '10.18112/a.ds001.v1.02',
                                                                      '10.18112/a.ds001.v1.03', '10.18112/b.ds001.v1',
                                                                      '10.18112/b.ds001.v2', '10.18112/b.ds001.v3',
                                                                      '10.18112/b.ds001.v11'
                                                                    ])
        expect(remove_dois).to contain_exactly('10.18112/a.ds001.v1.01.01', '10.18112/a.ds001.v1.02',
                                               '10.18112/b.ds001.v1', '10.18112/b.ds001.v2', '10.18112/b.ds001.v3')
      end
    end

    context 'when a non-numbered base version exists' do
      let(:solr_docs) do
        [
          { 'doi_ssi' => '10.18112/a.ds001' },
          { 'doi_ssi' => '10.18112/a.ds001.v1.02' },
          { 'doi_ssi' => '10.18112/a.ds001.v1.03' }
        ]
      end

      it 'lists all lower version numbers for removal' do
        remove_dois = dataset_consolidator.remove_by_version_number([
                                                                      '10.18112/a.ds001', '10.18112/a.ds001.v1.02',
                                                                      '10.18112/a.ds001.v1.03'
                                                                    ])
        expect(remove_dois).to contain_exactly('10.18112/a.ds001.v1.02', '10.18112/a.ds001.v1.03')
      end
    end

    context 'with ICSPR DOIs' do
      let(:solr_docs) do
        [
          { 'doi_ssi' => '10.3886/ICPSR07803.v1' },
          { 'doi_ssi' => '10.3886/ICPSR07803.v2' },
          { 'doi_ssi' => '10.3886/ICPSR07803.v10' }
        ]
      end

      it 'lists all lower version numbers for removal' do
        remove_dois = dataset_consolidator.remove_by_version_number([
                                                                      '10.3886/ICPSR07803.v1', '10.3886/ICPSR07803.v2',
                                                                      '10.3886/ICPSR07803.v10'
                                                                    ])
        expect(remove_dois).to contain_exactly('10.3886/ICPSR07803.v1', '10.3886/ICPSR07803.v2')
      end
    end
  end
end
