# frozen_string_literal: true

class Filter < ApplicationRecord
  has_and_belongs_to_many :user_tests

  validates :operator, inclusion: {in: ->(_filter) { Filter.operators }}
  validates :operator, exclusion: {in: ->(_filter) { Filter.int_operators }},
    if: :string_field?
  validates :field_name, inclusion: {in: ->(_filter) { Filter.field_names }}

  def filter(user_id, course_id = nil)
    return if invalid?

    if Filter.complex_queries.include? field_name
      Filter.complex_queries[field_name].call self, user_id, course_id
    else
      check_profile_field user_id, course_id
    end
  end

  def check_profile_field(user_id, _)
    profile = Xikolo.api(:account).value!
      .rel(:user).get(id: user_id).value!
      .rel(:profile).get.value!

    field = profile['fields'].find do |f|
      f['name'] == field_name
    end
    field['values'].any? {|value| check(value) }
  end

  def check(value, int: false, bool: false)
    field_value_ = field_value.split(',')
    field_value_.map!(&:to_i) if int
    field_value_.map!(&:to_bool) if bool
    case operator
      when 'in' then field_value_.include? value
      when '<=<=' then check_range(field_value_, value, '<=', '>=')
      when '<<' then check_range(field_value_, value, '<', '>')
      else value.send(operator, field_value_.first)
    end
  end

  def check_range(field_value_, value, l_op, h_op)
    low, high = field_value_.to(1).sort
    low.send(l_op, value) && high.send(h_op.first, value)
  end

  def string_field?
    Filter.complex_queries.keys.exclude? field_name
  end

  def self.field_names
    @field_names ||=
      %w[gender show_birthdate_on_records affiliation career_status
         highest_degree background_it professional_life position
         profile_facebook profile_google_plus profile_linked_in
         profile_twitter profile_xing has_accepted_privacy sap_id
         subscribed_to_newsletter relation country city] +
      complex_queries.keys
  end

  def self.complex_queries
    @complex_queries ||=
      {'enrollments' =>
           proc do |filter, user_id, _|
             enrollments = Xikolo.api(:course).value!.rel(:enrollments).get(
               user_id:
             ).value!
             filter.check enrollments.size, int: true
           end}
  end

  def self.operators
    @operators ||= %w[== != in] + int_operators
  end

  def self.int_operators
    @int_operators ||= %w[< > <= >= << <=<=]
  end
end
