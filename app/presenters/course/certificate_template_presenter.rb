# frozen_string_literal: true

class Course::CertificateTemplatePresenter
  extend Forwardable

  def_delegators :@template, :id, :file_url, :certificate_type

  def initialize(template)
    @template = template
  end

  def record_count
    @record_count ||= @template.records.count
  end

  def deletable?
    record_count.zero?
  end
end
