# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  def form_label_classes(errors)
    "block mb-2 text-sm font-medium #{errors.any? ? 'text-red-600' : 'text-gray-900'}"
  end

  def form_input_classes(errors)
    <<~CSS.strip
      text-gray-900 text-sm rounded-lg focus:ring-blue-600 focus:border-blue-600 block w-full p-2.5#{' '}
      bg-gray-50 border #{errors.any? ? 'border-red-600' : 'border-gray-900'}
    CSS
  end

  def render_errors(errors)
    return if errors.blank?

    content_tag(:div, errors.join(', '), class: 'block text-sm font-light text-red-600')
  end
end
