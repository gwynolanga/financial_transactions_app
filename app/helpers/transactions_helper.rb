# frozen_string_literal: true

module TransactionsHelper
  def transaction_field_set(transaction, form, account)
    fields = []
    if transaction.immediate? || transaction.scheduled?
      fields.concat(immediate_and_scheduled_fields(transaction, form, account))
    end
    fields.concat(scheduled_fields(transaction, form)) if transaction.scheduled?
    fields.concat(deposit_fields(transaction, form)) if transaction.deposit?
    fields.concat(withdrawal_fields(transaction, form)) if transaction.withdrawal?
    fields
  end

  private

  def immediate_and_scheduled_fields(transaction, form, account)
    [
      field(:amount, form, :sender_amount, transaction.errors[:sender_amount]),
      field(:select, form, :recipient_id, recipient_errors(transaction), recipient_options(account))
    ]
  end

  def scheduled_fields(transaction, form)
    [
      field(:datetime, form, :execution_date, transaction.errors[:execution_date])
    ]
  end

  def deposit_fields(transaction, form)
    [
      field(:amount, form, :recipient_amount, transaction.errors[:recipient_amount])
    ]
  end

  def withdrawal_fields(transaction, form)
    [
      field(:amount, form, :sender_amount, transaction.errors[:sender_amount])
    ]
  end

  def field(type, form, attribute, errors, options = nil)
    {
      type: type,
      locals: {
        form: form,
        attribute: attribute,
        errors: errors,
        options: options
      }
    }
  end

  def recipient_options(account)
    Account.where.not(id: account.id).map do |a|
      ["#{a.human_number} / #{a.currency_name} / #{a.user_full_name}", a.id]
    end
  end

  def recipient_errors(transaction)
    transaction.errors[:recipient_id] + transaction.errors[:recipient]
  end
end
