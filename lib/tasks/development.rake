# frozen_string_literal: true

namespace :development do
  desc 'Performs a dryrun of the transformation of the dataset records for a given provider'
  task :transform_dryrun, [:provider] => :environment do |_t, args|
    provider = args[:provider]

    mapper = "DataworksMappers::#{provider.camelize}".constantize

    DatasetRecordSet.where(provider:).select(:list_args).group(:list_args).pluck(:list_args).each do |list_args|
      dataset_record_set = DatasetRecordSet.where(provider:, list_args:, complete: true).order(updated_at: :desc).first
      next unless dataset_record_set

      dataset_record_set.dataset_records.each do |dataset_record|
        mapper.call(source: dataset_record.source)
        puts "#{dataset_record.id} succeeded"
      rescue DataworksMappers::MappingError => e
        puts "#{dataset_record.id} failed - #{e.message}"
        Rails.logger.error "Mapping error for dataset_record_id #{dataset_record.id}: #{e.message}"
      end
    end
  end
end
