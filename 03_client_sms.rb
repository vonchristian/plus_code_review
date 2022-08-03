class ClientSms < ApplicationRecord

  belongs_to :debitor, optional: true

  validates :sender, presence: true
  validates :direction, inclusion: %w[inbox outbox]
  validates :sent_to, presence: true, length: { maximum: 255 }


  after_create :send_sms, if: :outbound_sms?

  def inbound_sms?
    direction == 'inbox'
  end

  def outbound_sms?
    direction == 'outbox'
  end

  private
  # Code Smell: Long Method
  # Use Extract Class
  # Use background job to send sms
  # Introduce Gateway
  def send_sms
    api_instance = MessenteApi::OmnimessageApi.new
    omnimessage = MessenteApi::Omnimessage.new
    omnimessage.to = sent_to.to_s
    omnimessage.messages = [
      MessenteApi::SMS.new(
        sender: sender.to_s,
        text: body.to_s
      )
    ]

    begin
      result = api_instance.send_omnimessage(omnimessage)

      if result.is_a?(MessenteApi::OmniMessageCreateSuccessResponse)
        update_columns(
          messente_message_id: result.as_json['messages'][0]['message_id'],
          messente_omnimessage_id: result.as_json['omnimessage_id']
        )
      end
    rescue MessenteApi::ApiError, ArgumentError => e
      Rails.logger.info "Exception when calling send_omnimessage: #{e}"
      Rails.logger.info e.response_body
      update_columns(status: 'API_ERROR', last_error: e.response_body.to_s)
      contact&.update_columns(status: 'API_ERROR')
    end
  end

end