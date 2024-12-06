# frozen_string_literal: true

class Course::Create < Course::Store
  def initialize(params)
    # ensure we have a course record with an assigned ID
    super(Course.new(id: UUID4.new), params)
  end

  def call
    Course.transaction do
      next course unless update # assign attributes and save from parent class

      create_context!
      Xikolo.config.course_groups.each do |name, data|
        create_group! name, data['description'], data['grants']
      end
      grant_visitor!
      @course.save!
      @course
    end
  rescue ActiveRecord::RecordInvalid => e
    e.record
  rescue OperationError => e
    @course.errors.add :base, e.message
    @course
  end

  private

  def create_context!
    context_data = {
      parent: 'root',
      reference_uri: "urn:x-xikolo:course:course:#{@course.course_code}",
    }
    context = account.rel(:contexts).post(context_data).value!
    @course.context_id = context[:id]
  rescue Restify::ResponseError => e
    raise_operation_error e, 'error creating context'
  end

  def create_group!(name, description, grants)
    group_data = {
      name: "course.#{@course.course_code}.#{name}",
      description: format(description, @course.course_code),
    }
    group = account.rel(:groups).post(group_data).value!
    grants.each do |grant|
      grant! role: grant['role'],
        group: group['name'],
        context: grant['context']
    end
    @course.special_groups << name if name != 'students'
  rescue Restify::ResponseError => e
    raise_operation_error e, 'error creating group'
  end
end
