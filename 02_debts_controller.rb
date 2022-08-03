class DebtsController < ApplicationController

  # Code Smell: Long Method
  # Decompose this into smaller methods
  # Use background job for sending SMS

  def mass_smses_send
    @debts = @debts.uniq(&:debitor_id) if params[:create_for_client].to_s == 'true'

    @debts.each do |debt|
      # Code Smell: Duplicate Code, Message Chain
      # Use Replace Temp with Query -> create a method recipient_number
      # Decompose Conditional
      # Use better naming: if recipient_number.blank?
      unless params[:send_to].present? || debt.debitor.phone1.present?
        next
      end

      # Use Extract Method, Extract Class
      # create_contact(debt) or
      # create a class CreateContact
      # Apply good naming on variables
      ct = ContactTemplate.find_by_id(params[:contact_template_id]) || ContactTemplate.new
      # Should be current_user instead of @current_user
      ct.current_user = @current_user
      ct.body = params[:body]
      # Use Inline Temp
      rendered_body = ct.parse_fields_no_format(debt)

      c = Contact.new(
        user: current_user,
        debitor_id: debt.debitor.id,
        contact_type: ContactType.find_by(id_name: 'sms'),
        # Code Smell: Duplicate Code, Message Chain
        contact_number: params[:send_to].present? ? params[:send_to] : debt.debitor.phone1,
        body: rendered_body,
        sender: params[:sender],
        status: 'IN_PROGRESS',
        contact_template_id: ct.id,
        headline: 'SMS OUT',
        skip_create_activity: true
      )

      unless c.save
        next
      end

      # Use Extract Method, Extract Class
      # create_sms(debt) or
      # Create a class GenerateSMSBody

      sms = ClientSms.new(
        direction: 'outbox',
        sent_by: current_user,
        sender: params[:sender],
        # Code Smell: Duplicate Code, Message Chain
        sent_to: params[:send_to].present? ? params[:send_to] : debt.debitor.phone1,
        body: rendered_body,
        debitor_id: debt.debitor.id,
        status: 'IN_PROGRESS',
        contact: c
      )

      unless sms.save
        c.destroy
        next
      end
    end

    render json: { message: 'SMSes sent!' }, status: :ok
  end


  # def create_contact(debt)
  #   ct = ContactTemplate.find_by_id(params[:contact_template_id]) || ContactTemplate.new
  #   ct.current_user = @current_user
  #   ct.body = params[:body]
  #   rendered_body = ct.parse_fields_no_format(debt)

  #   c = Contact.new(
  #     user: current_user,
  #     debitor_id: debt.debitor.id,
  #     contact_type: ContactType.find_by(id_name: 'sms'),
  #     contact_number: params[:send_to].present? ? params[:send_to] : debt.debitor.phone1,
  #     body: rendered_body,
  #     sender: params[:sender],
  #     status: 'IN_PROGRESS',
  #     contact_template_id: ct.id,
  #     headline: 'SMS OUT',
  #     skip_create_activity: true
  #   )
  # end

  # def create_sms(debt)
  #   ClientSms.new(
  #     direction: 'outbox',
  #     sent_by: current_user,
  #     sender: params[:sender],
  #     sent_to: params[:send_to].present? ? params[:send_to] : debt.debitor.phone1,
  #     body: rendered_body,
  #     debitor_id: debt.debitor.id,
  #     status: 'IN_PROGRESS',
  #     contact: c
  #   )
  # end

end

