# frozen_string_literal: true

module Clients
  # Results returned from Client#list
  class ListResult
    attr_reader :id, :modified_token, :source

    def initialize(id:, modified_token:, source: nil)
      @id = id
      @modified_token = modified_token
      @source = source
    end
  end
end
