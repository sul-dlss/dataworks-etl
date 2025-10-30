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
  let(:solr_service) { instance_double(SolrService, delete: true, add: true) }
  let(:cocina_service) { instance_double(CocinaService, cocina_record: record) }

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
    it 'sends the mapped item to Solr' do
      solr_doc = described_class.map_record(record)
      consumer.process(message)
      expect(solr_service).to have_received(:add).with(solr_doc: solr_doc)
      expect(SdrEvents).to have_received(:report_indexing_success).with('cz537wr8540', target: 'Dataworks')
    end

    context 'with multiple required targets when both targets match' do
      let(:targets) { ['PURL Sitemap', 'Searchworks'] }
      let(:message_contents) { { druid: 'druid:cz537wr8540', true_targets: ['purl sitemap', 'SearchWorks'] } }

      it 'sends the mapped item to Solr and notifies SDR' do
        solr_doc = described_class.map_record(record)
        consumer.process(message)
        expect(solr_service).to have_received(:add).with(solr_doc: solr_doc)
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

      it 'executes a delete and notifies SDR' do
        consumer.process(message)
        expect(solr_service).to have_received(:delete).with(id: 'cz537wr8540')
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

      it 'executes a delete and notifies SDR' do
        consumer.process(message)
        expect(solr_service).to have_received(:delete).with(id: 'cz537wr8540')
        expect(SdrEvents).to have_received(:report_indexing_deleted).with('cz537wr8540', target: 'Dataworks')
      end
    end

    context 'when the item has no public cocina record' do
      before do
        allow(cocina_service).to receive(:cocina_record).and_raise(Faraday::ResourceNotFound)
      end

      it 'skips indexing and notifies SDR' do
        consumer.process(message)
        expect(solr_service).not_to have_received(:add)
        expect(SdrEvents).to have_received(:report_indexing_skipped).with(
          'cz537wr8540',
          target: 'Dataworks',
          message: 'No public Cocina record'
        )
      end
    end

    context 'when the item is not a self-deposited dataset' do
      before do
        # Remove the self-deposit resource type
        cocina['description']['form'][0] = {}
      end

      it 'skips indexing and notifies SDR' do
        consumer.process(message)
        expect(solr_service).not_to have_received(:add)
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

      it 'skips indexing and notifies SDR' do
        consumer.process(message)
        expect(solr_service).not_to have_received(:add)
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
