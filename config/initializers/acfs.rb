# frozen_string_literal: true

module RestifyCompatiblity
  #
  # Provides a restify compatible access ([], keys?, fetch)
  # to Acfs resources. These methods return non-casted values
  # e.g. times as string. Only basic JSON/Msgpack types are
  # directly supported: nil, string, int, boolean
  #
  # the new `raw_attributes` stores each attributes unprocesses as it
  # has been received from the service
  #
  # `write_local_attribute` and `write_attribute` have been extended to
  # record the input value in `raw_attributes`.
  #
  def raw_attributes
    @_raw_attrs ||= {} # rubocop:disable Naming/MemoizedInstanceVariableName
  end

  def write_local_attribute(name, value, opts = {})
    raw_attributes[name.to_s] = value.as_json
    super
  end

  def write_attribute(name, value, opts = {})
    raw_attributes[name.to_s] = value.as_json
    super
  end

  delegate :[], :key?, :fetch, to: :raw_attributes
end

Acfs::Resource.include RestifyCompatiblity
