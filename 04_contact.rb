# Better class naming
# Possible CustomerCommunication

class Contact < ApplicationRecord
  # Associations should not be optional
  belongs_to :debt, required: false
  belongs_to :debitor, required: false

  has_many :archive_documents

end