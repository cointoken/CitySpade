class Document < ActiveRecord::Base
   belongs_to :client_apply
   mount_uploader :name, DocumentUploader
   attr_accessor :photo_id, :bank_statement, :school_letter, :paystub, :passport, :visa, :i20, :green_card, :opt, :h1b, :other

  def file_size
    # Encoded file size
    return ((1.37 * self.name.size.to_f) / 2**20).round(2)
  end
end
