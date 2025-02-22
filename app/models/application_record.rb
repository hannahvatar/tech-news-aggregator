# app/models/application_record.rb
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def source_name
    # Implement a default method that can be overridden
    "Unknown Source"
  end
end
