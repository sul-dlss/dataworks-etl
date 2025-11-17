# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SdrConsumer do
  subject(:consumer) do
    described_class.new(
      targets: targets,
      cocina_service: cocina_service,
      solr_service: solr_service
    )
  end

  let(:targets) { ['Dataworks'] }
  let(:cocina) { JSON.parse(file_fixture('sdr_affiliations.json').read) }
  let(:record) { CocinaDisplay::CocinaRecord.new(cocina) }
  let(:message) { instance_double(Racecar::Message, key: 'druid:cz537wr8540', value: message_contents.to_json) }
  let(:message_contents) { { druid: 'druid:cz537wr8540', true_targets: ['Dataworks'] } }
  let(:solr_service) { instance_double(SolrService, delete: true, add: true, commit: true) }
  let(:cocina_service) { instance_double(CocinaService, cocina_record: record) }
  let(:sdr_set) { DatasetRecordSet.find_or_create_by!(provider: 'sdr', complete: true) }

  before do
    allow(Settings).to receive_messages(
      indexer_topic: 'testing_topic',
      indexer_group: 'testing_group'
    )
    allow(Honeybadger).to receive(:notify)
    allow(DataworksMappers::Sdr).to receive(:call).and_call_original
    allow(SolrMapper).to receive(:call).and_call_original
    allow(SdrEvents).to receive_messages(
      report_indexing_success: true,
      report_indexing_skipped: true,
      report_indexing_errored: true,
      report_indexing_deleted: true
    )
  end

  describe '#process' do
    context 'when the item is in the database already' do
      before do
        DatasetRecord.create!(
          provider: 'sdr',
          dataset_id: 'cz537wr8540',
          source: {},
          dataset_record_set_ids: [sdr_set.id]
        )
      end

      it 'updates the item in the database' do
        consumer.process(message)
        dataset_record = DatasetRecord.find_by(provider: 'sdr', dataset_id: 'cz537wr8540')
        expect(dataset_record.source).to eq(cocina)
      end
    end

    context 'when the item is not in the database' do
      it 'creates the item in the database' do
        consumer.process(message)
        dataset_record = DatasetRecord.find_by(provider: 'sdr', dataset_id: 'cz537wr8540')
        expect(dataset_record.source).to eq(cocina)
      end
    end

    it 'sends the mapped item to Solr' do
      solr_doc = described_class.map_record(record)
      consumer.process(message)
      expect(solr_service).to have_received(:add).with(solr_doc: solr_doc)
    end

    it 'notifies SDR of successful indexing' do
      consumer.process(message)
      expect(SdrEvents).to have_received(:report_indexing_success).with('cz537wr8540', target: 'Dataworks')
    end

    context 'with multiple required targets when both targets match' do
      let(:targets) { ['PURL Sitemap', 'Searchworks'] }
      let(:message_contents) { { druid: 'druid:cz537wr8540', true_targets: ['purl sitemap', 'SearchWorks'] } }

      it 'sends the mapped item to Solr' do
        solr_doc = described_class.map_record(record)
        consumer.process(message)
        expect(solr_service).to have_received(:add).with(solr_doc: solr_doc)
      end

      it 'notifies SDR of successful indexing' do
        consumer.process(message)
        expect(SdrEvents).to have_received(:report_indexing_success).with('cz537wr8540', target: 'Dataworks')
      end
    end

    context 'with multiple required targets when one target is missing' do
      let(:targets) { ['PURL Sitemap', 'Searchworks'] }
      let(:message_contents) { { druid: 'druid:cz537wr8540', true_targets: ['SearchWorks'] } }

      it 'skips indexing; does nothing' do
        consumer.process(message)
        expect(solr_service).not_to have_received(:add)
      end
    end

    context 'when the kafka message had no content' do
      let(:message_contents) { nil }

      context 'when the item is in the database already' do
        before do
          DatasetRecord.create!(
            provider: 'sdr',
            dataset_id: 'cz537wr8540',
            source: {},
            dataset_record_set_ids: [sdr_set.id]
          )
        end

        it 'removes the item from the database' do
          consumer.process(message)
          expect(DatasetRecord.find_by(provider: 'sdr', dataset_id: 'cz537wr8540')).to be_nil
        end
      end

      context 'when the item is not in the database' do
        it 'does not raise an error' do
          expect { consumer.process(message) }.not_to raise_error
        end
      end

      it 'removes the item from the index' do
        consumer.process(message)
        expect(solr_service).to have_received(:delete).with(id: 'cz537wr8540')
      end

      it 'notifies SDR' do
        consumer.process(message)
        expect(SdrEvents).to have_received(:report_indexing_deleted).with('cz537wr8540', target: 'Dataworks')
      end
    end

    context 'when the item has been unreleased from the target' do
      let(:message_contents) do
        {
          druid: 'druid:cz537wr8540',
          false_targets: ['Dataworks']
        }
      end

      context 'when the item is in the database already' do
        before do
          DatasetRecord.create!(
            provider: 'sdr',
            dataset_id: 'cz537wr8540',
            source: {},
            dataset_record_set_ids: [sdr_set.id]
          )
        end

        it 'removes the item from the database' do
          consumer.process(message)
          expect(DatasetRecord.find_by(provider: 'sdr', dataset_id: 'cz537wr8540')).to be_nil
        end
      end

      context 'when the item is not in the database' do
        it 'does not raise an error' do
          expect { consumer.process(message) }.not_to raise_error
        end
      end

      it 'removes the item from the index' do
        consumer.process(message)
        expect(solr_service).to have_received(:delete).with(id: 'cz537wr8540')
      end

      it 'notifies SDR' do
        consumer.process(message)
        expect(SdrEvents).to have_received(:report_indexing_deleted).with('cz537wr8540', target: 'Dataworks')
      end
    end

    context 'when the item has no public cocina record' do
      before do
        allow(cocina_service).to receive(:cocina_record).and_raise(Faraday::ResourceNotFound)
      end

      it 'skips indexing' do
        consumer.process(message)
        expect(solr_service).not_to have_received(:add)
      end

      it 'notifies SDR' do
        consumer.process(message)
        expect(SdrEvents).to have_received(:report_indexing_skipped).with(
          'cz537wr8540',
          target: 'Dataworks',
          message: 'No public Cocina record'
        )
      end
    end

    context 'when the item is not a self-deposited dataset' do
      before do
        # Remove the self-deposit resource type from the item
        cocina['description']['form'][0] = {}
      end

      it 'skips indexing' do
        consumer.process(message)
        expect(solr_service).not_to have_received(:add)
      end

      it 'notifies SDR' do
        consumer.process(message)
        expect(SdrEvents).to have_received(:report_indexing_skipped).with(
          'cz537wr8540',
          target: 'Dataworks',
          message: 'Not a self-deposit dataset'
        )
      end
    end

    context 'when the item is dark' do
      before do
        # Make the object dark
        cocina['access']['view'] = 'dark'
        cocina['access']['download'] = 'none'
      end

      it 'skips indexing' do
        consumer.process(message)
        expect(solr_service).not_to have_received(:add)
      end

      it 'notifies SDR' do
        consumer.process(message)
        expect(SdrEvents).to have_received(:report_indexing_skipped).with(
          'cz537wr8540',
          target: 'Dataworks',
          message: 'Object rights are dark'
        )
      end
    end

    context 'when processing raises an error' do
      before do
        allow(DataworksMappers::Sdr).to receive(:call).and_raise(DataworksMappers::MappingError)
      end

      it 'notifies Honeybadger and SDR' do
        consumer.process(message)
        expect(Honeybadger).to have_received(:notify)
        expect(SdrEvents).to have_received(:report_indexing_errored)
      end
    end
  end
end
