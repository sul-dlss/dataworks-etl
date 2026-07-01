# frozen_string_literal: true

namespace :development do # rubocop:disable Metrics/BlockLength
  desc 'Performs a dryrun of the transformation of the dataset records for a given provider'
  task :transform_dryrun, [:provider] => :environment do |_t, args|
    provider = args[:provider]

    mapper = "DataworksMappers::#{provider.camelize}".constantize

    DatasetRecordSet.where(provider:).select(:list_args).group(:list_args).pluck(:list_args).each do |list_args|
      dataset_record_set = DatasetRecordSet.where(provider:, list_args:, complete: true).order(updated_at: :desc).first
      next unless dataset_record_set

      dataset_record_set.dataset_records.each do |dataset_record|
        mapper.call(source: dataset_record.source)
      rescue DataworksMappers::MappingError => e
        # Not every dataset has a DOI but all have a dataset id, which may be a DOI
        puts "#{dataset_record.dataset_id} - Failure message #{e.message}"
      # Some errors may occur for other reasons, for example, a malformed URI
      # throwing an error from within Cocina code
      # We want to capture any errors and output them for tracking
      rescue StandardError => e
        puts "#{dataset_record.dataset_id} - Non mapping error #{e.message}"
      end
    end
  end

  desc 'Export Vertex docs'
  task export_vertex_docs: :environment do
    File.open('vertex_docs.jsonl', 'w') do |file|
      TransformerLoader.call(load: false, mapper_class: VertexMapper) do |doc|
        next unless doc

        file.write(doc.to_json)
        file.write("\n")
      rescue DataworksMappers::MappingError
        # Ignore
      end
    end
  end

  # rubocop:disable Metrics/BlockLength
  desc 'Export Vertex html docs'
  task export_vertex_html_docs: :environment do
    File.open('vertex_html_docs.jsonl', 'w') do |file|
      TransformerLoader.call(load: false, mapper_class: VertexMapper) do |doc|
        next unless doc

        filepath = "html_docs/#{doc[:id]}.html"
        unless File.exist?(filepath)
          begin
            conn = Faraday.new do |faraday|
              faraday.response :follow_redirects, limit: 5
              faraday.headers['User-Agent'] = 'DataWorks, Stanford University Libraries'
            end
            resp = conn.get(doc[:url])
            next unless resp.success?

            FileUtils.mkdir_p(File.dirname(filepath))
            File.write(filepath, resp.body.force_encoding('UTF-8'))
          rescue Faraday::FollowRedirects::RedirectLimitReached, Faraday::SSLError,
                 Faraday::TimeoutError, Faraday::ConnectionFailed
            next
          end
        end

        data = {
          id: doc[:id].gsub(%r{[.,/]}, '_'),
          structData: doc,
          content: { mimeType: 'text/html', uri: "gs://dataworks-jlit/#{filepath}" }
        }

        file.write(data.to_json)
        file.write("\n")
      rescue DataworksMappers::MappingError
        # Ignore
      end
    end
    # rubocop:enable Metrics/BlockLength
  end

  desc 'Load author CSV into database'
  task :load_stanford_authors, [:file_path] => :environment do |_t, args|
    require 'csv'
    require 'activerecord-import'
    file_path = args[:file_path]
    full_path = Rails.root.join(file_path)
    puts "Loading file at #{full_path}"

    import_records = []
    CSV.foreach(full_path, headers: true) do |row|
      import_records << StanfordAuthor.new(sunet_id: row['sunetid'],
                                           cap_profile_id: row['cap_profile_id'],
                                           full_name: row['full_name'],
                                           first_name: row['first_name'],
                                           last_name: row['last_name'],
                                           orcid: row['orcidid'],
                                           email: row['email'],
                                           active: row['active'] == 'TRUE',
                                           departments: row['all_departments']&.split('|'))
    end

    puts "Created records for import: #{import_records.length}"
    StanfordAuthor.import import_records
    puts 'Finished importing records'
  end

  desc 'Delete authors from stanford authors'
  task remove_stanford_authors: :environment do
    StanfordAuthor.delete_all
    puts 'Removed all Stanford authors'
  end
end
