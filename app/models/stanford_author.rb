# frozen_string_literal: true

# Author information for Stanford profiles
class StanfordAuthor < ApplicationRecord
  def ordered_name
    "#{last_name}, #{first_name}"
  end
end
