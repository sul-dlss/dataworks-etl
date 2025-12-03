# frozen_string_literal: true

# Incrementally harvest, store, and index datasets published from SDR
class SdrConsumer < Racecar::Consumer
  subscribes_to Settings.indexer_topic
  self.group_id = Settings.indexer_group

  # If the object doesn't have one of these self-deposit resource types, skip it
  DATASET_RESOURCE_TYPES = [
    'Data',
    'Database',
    'Tabular data',
    'Geospatial data',
    'Remote sensing imagery'
  ].freeze

  def initialize(
    targets: Settings.purl_fetcher.targets,
    skip_collections: Settings.purl_fetcher.skip_collections,
    cocina_service: CocinaService.new,
    logger: Rails.logger
  )
    super()
    @targets = targets.map(&:downcase)
    @skip_collections = skip_collections.map { |druid| "druid:#{druid}" }
    @cocina_service = cocina_service
    @logger = logger
  end

  # Process a single message from the Kafka queue; key is the druid
  def process(message)
    change = JSON.parse(message.value) if message.value.present?
    druid = message.key.delete_prefix('druid:')
    @logger.debug { "SDR indexer received message for druid:#{druid}: #{change}" }

    # An empty message means delete from all platforms; a matching false target
    # means it was unreleased from our platform specifically
    return process_delete(druid) if change.blank? || false_target?(change)

    # If the item's release targets don't match ours, skip it and don't bother
    # notifying SDR; it's going to a different platform (e.g. Searchworks)
    return @logger.debug { "SDR indexer skipped druid:#{druid}; target mismatch" } unless true_target?(change)

    # The message includes the collections the item is in, so we can check them
    # without needing to fetch the cocina record yet
    return process_skip(druid, reason: 'In skipped collection') if in_skipped_collection?(change)

    # Proceed to fetch the cocina from PURL and try to update it
    update_item(druid)
  end

  # Fetch the cocina record and try to update the item in the database
  # NOTE: You can use this in development to manually update an item by running:
  # SdrConsumer.new.update_item('xx123yy4567')
  def update_item(druid)
    record = cocina_record(druid)
    return process_skip(druid, reason: 'No public Cocina record') if record.blank?
    return process_skip(druid, reason: 'Object rights are dark') if record.dark_access?
    return process_skip(druid, reason: 'Not a self-deposit dataset') unless self_deposit_dataset?(record)

    process_update(druid, record: record)
  end

  private

  # Do the item's release targets match all of our desired targets?
  def true_target?(change)
    true_targets = Array(change&.dig('true_targets')).map(&:downcase)
    @targets.all? { |target| true_targets.include?(target) }
  end

  # Do the item's non-release targets match any of our desired targets?
  def false_target?(change)
    false_targets = Array(change&.dig('false_targets')).map(&:downcase)
    @targets.any? { |target| false_targets.include?(target) }
  end

  # Is the item in any collection we should skip?
  def in_skipped_collection?(change)
    collections = Array(change&.dig('collections'))
    @skip_collections.any? { |druid| collections.include?(druid) }
  end

  # Is the item a self-deposited dataset?
  # Checks both top-level type and subtypes for self-deposit resource types.
  def self_deposit_dataset?(cocina_record)
    cocina_record.self_deposit_resource_types.flat_map(&:values).any? do |type|
      DATASET_RESOURCE_TYPES.include?(type)
    end
  end

  # Public cocina record for an item; nil if not found
  def cocina_record(druid)
    @cocina_service.cocina_record(druid: druid)
  rescue Faraday::ResourceNotFound
    nil
  end

  # Reference to the single persistent DatasetRecordSet for SDR
  def dataset_record_set
    @dataset_record_set ||= DatasetRecordSet.find_or_create_by!(provider: 'sdr')
  end

  # Create or update the DatasetRecord for this item
  def update_dataset_record(druid, record:)
    dataset_record = DatasetRecord.find_or_initialize_by(provider: 'sdr', dataset_id: druid)
    dataset_record.dataset_record_set_ids = [dataset_record_set.id]
    dataset_record.source = record.cocina_doc
    dataset_record.modified_token = record.modified_time
    dataset_record.doi = record.doi
    dataset_record.save!
  end

  # Notify SDR that we didn't take any action for some reason
  def process_skip(druid, reason:)
    SdrEvents.report_indexing_skipped(druid, target: 'Dataworks', message: reason)
    @logger.info { "SDR indexer skipped druid:#{druid}; #{reason}" }
    nil
  end

  # Remove item from the database and notify SDR
  def process_delete(druid)
    DatasetRecord.destroy_by(provider: 'sdr', dataset_id: druid)
    @logger.info { "SDR indexer deleted druid:#{druid}" }
    SdrEvents.report_indexing_deletion_scheduled(druid, target: 'Dataworks')
    nil
  end

  # Add/update item in the database and notify SDR
  def process_update(druid, record:)
    update_dataset_record(druid, record: record)
    @logger.info { "SDR indexer updated druid:#{druid}" }
    SdrEvents.report_indexing_scheduled(druid, target: 'Dataworks')
    nil
  end
end
