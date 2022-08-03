class ContactTemplate < ApplicationRecord

  has_one :company
  has_many :contacts

  belongs_to :contact_type

  # Create an explicity class method: Suggestion  def self.ordered_by_name
  # default scope has hidden side-effect. See: https://riptutorial.com/ruby-on-rails/example/17746/beware-of--default-scope
  default_scope { order('name ASC') }

  validates :body, :headline, :name, presence: true

  # Rename Method: Suggestion -> body_with_debt_reference_number
  # Pass reference_number as argument instead of debt

  def parse_fields_no_format(debt)
    strip_tags(parse_fields(debt))
  end

  def parse_fields(debt)
    body.gsub(/#REF#/, debt.reference_number)
  end

