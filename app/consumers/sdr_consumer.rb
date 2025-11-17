# frozen_string_literal: true

# Incrementally harvest, store, and index datasets published from SDR
# rubocop:disable Metrics/ClassLength
class SdrConsumer < Racecar::Consumer
  subscribes_to Settings.indexer_topic
  self.group_id = Settings.indexer_group

  attr_reader :targets, :skip_collections

  # If the object doesn't have one of these self-deposit resource types, skip it
  DATASET_RESOURCE_TYPES = [
    'Data',
    'Database',
    'Tabular data',
    'Geospatial data',
    'Remote sensing imagery'
  ].freeze

  # Map a single Cocina record to a Solr document
  # @param cocina_record [CocinaDisplay::CocinaRecord]
  # @return [Hash] Solr document
  def self.map_record(cocina_record)
    dataworks_record = DataworksMappers::Sdr.call(source: cocina_record.cocina_doc)
    SolrMapper.call(
      metadata: dataworks_record,
      doi: cocina_record.doi,
      id: cocina_record.druid
    )
  end

  def initialize(
    targets: Settings.purl_fetcher.targets,
    skip_collections: Settings.purl_fetcher.skip_collections,
    cocina_service: CocinaService.new,
    solr_service: SolrService.new
  )
    super()
    @targets = targets.map(&:downcase)
    @skip_collections = skip_collections.map { |druid| "druid:#{druid}" }
    @cocina_service = cocina_service
    @solr_service = solr_service
  end

  # Process a single message from the Kafka queue; key is the druid
  def process(message)
    @change = JSON.parse(message.value) if message.value.present?
    @druid = message.key.delete_prefix('druid:')
    return process_delete if should_delete?
    return unless true_target?

    update_item
  rescue DataworksMappers::MappingError => e
    context = { druid: @druid, record: cocina_record&.cocina_doc }
    Honeybadger.notify(e, context: context)
    SdrEvents.report_indexing_errored(@druid, target: 'Dataworks', message: e.message, context: context)
  end

  # Add or update the item in the index, if possible
  # NOTE: You can use this in development to manually update an item by running:
  # SdrConsumer.new.update_item('xx123yy4567')
  def update_item(druid = nil)
    @druid ||= druid
    should_skip? ? process_skip : process_update
  end

  private

  # Should we delete the item from the index?
  def should_delete?
    return true if @change.blank?
    return true if false_target?

    false
  end

  # Should we skip indexing the item?
  def should_skip?
    skip_reason.present?
  end

  # Message indicating why we cannot index/update the item, if any
  def skip_reason
    return 'In skipped collection' if in_skipped_collection?
    return 'No public Cocina record' if cocina_record.blank?
    return 'Object rights are dark' if cocina_record.dark_access?
    return 'Not a self-deposit dataset' unless self_deposit_dataset?

    nil
  end

  # Downcased list of release targets for the item
  def true_targets
    @true_targets ||= Array(@change['true_targets']).map(&:downcase)
  end

  # Downcased list of non-release targets for the item
  def false_targets
    @false_targets ||= Array(@change['false_targets']).map(&:downcase)
  end

  # Do the item's release targets match all of our desired targets?
  def true_target?
    targets.all? { |target| true_targets.include?(target) }
  end

  # Do the item's non-release targets match any of our desired targets?
  def false_target?
    targets.any? { |target| false_targets.include?(target) }
  end

  # Is the item in any collection we should skip?
  def in_skipped_collection?
    skip_collections.any? { |druid| Array(@change['collections']).include?(druid) }
  end

  # Is the item a self-deposited dataset?
  # Checks both top-level type and subtypes for self-deposit resource types.
  def self_deposit_dataset?
    cocina_record.self_deposit_resource_types.flat_map(&:values).any? do |type|
      DATASET_RESOURCE_TYPES.include?(type)
    end
  end

  # Public cocina record for the item
  def cocina_record
    @cocina_service.cocina_record(druid: @druid)
  rescue Faraday::ResourceNotFound
    nil
  end

  # Reference to the single persistent dataset record set for SDR
  def dataset_record_set
    @dataset_record_set ||= DatasetRecordSet.find_or_create_by!(provider: 'sdr', complete: true)
  end

  # Create or update the DatasetRecord for this item
  def update_dataset_record
    dataset_record = DatasetRecord.find_or_initialize_by(provider: 'sdr', dataset_id: @druid)
    dataset_record.dataset_record_set_ids = [dataset_record_set.id]
    dataset_record.source = cocina_record.cocina_doc
    dataset_record.modified_token = cocina_record.modified_time
    dataset_record.save!
  end

  # Notify SDR that we didn't take any action for some reason
  def process_skip
    SdrEvents.report_indexing_skipped(@druid, target: 'Dataworks', message: skip_reason)
    Rails.logger.info { "SDR indexer skipped druid:#{@druid}; #{skip_reason}" }
  end

  # Remove item from the database and index and notify SDR
  def process_delete
    DatasetRecord.destroy_by(provider: 'sdr', dataset_id: @druid)
    @solr_service.delete(id: @druid)
    @solr_service.commit
    Rails.logger.info { "SDR indexer deleted druid:#{@druid}" }
    SdrEvents.report_indexing_deleted(@druid, target: 'Dataworks')
  end

  # Add/update item in the database and index and notify SDR
  def process_update
    update_dataset_record
    @solr_service.add(solr_doc: SdrConsumer.map_record(cocina_record))
    @solr_service.commit
    Rails.logger.info { "SDR indexer updated druid:#{@druid}" }
    SdrEvents.report_indexing_success(@druid, target: 'Dataworks')
  end
end
# rubocop:enable Metrics/ClassLength
