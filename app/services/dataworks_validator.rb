# frozen_string_literal: true

# Validator for the Dataworks flavor of DataCite metadata
class DataworksValidator
  class ValidationError < StandardError; end

  def initialize(metadata:)
    @metadata = metadata
  end

  def valid?
    errors.empty?
  end

  # raise ValidationError if the metadata is not valid
  def valid!
    raise ValidationError, errors.join(', ') unless valid?
  end

  def errors
    @errors ||= JSONSchemer.schema(schema).validate(metadata).pluck('error')
  end

  private

  attr_reader :metadata

  def schema
    @@schema ||= YAML.load_file('config/dataworks_schema.yml').tap do |schema| # rubocop:disable Style/ClassVars
      raise 'Schema is not valid' unless JSONSchemer.valid_schema?(schema)
    end
  end
end
