# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  def form_label(errors = [])
    "form-label #{errors.any? ? 'error' : ''}".strip
  end

  def form_input(errors = [])
    "form-input #{errors.any? ? 'error' : ''}".strip
  end

  def render_form_error_messages(errors)
    return if errors.blank?

    content_tag(:div, errors.join(', '), class: 'form-error-messages')
  end

  def btn_element(colour, full_width: false)
    "btn #{colour} #{full_width ? 'full_width' : ''}".strip
  end
end
