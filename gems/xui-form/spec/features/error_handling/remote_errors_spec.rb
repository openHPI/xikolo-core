# frozen_string_literal: true

require 'xui/form'

RSpec.describe 'Error Handling: Remote errors' do
  let(:form) do
    Class.new(XUI::Form) do
      self.form_name = 'test'

      attribute :name, :string
    end
  end

  it 'has no errors by default' do
    object = form.from_resource 'name' => 'Hasso'

    expect(object.errors).to be_empty
  end

  it 'maps remote errors to existing attributes' do
    object = form.from_resource 'name' => 'Hasso'
    object.remote_errors({
      'name' => ['too_short'],
    })

    expect(object.errors).to_not be_empty
    expect(object.errors.include?(:name)).to be true
  end

  it 'maps errors not related to a specific field to "base"' do
    object = form.from_resource 'name' => 'Hasso'
    object.remote_errors({
      'base' => ['not_unique'],
    })

    expect(object.errors).to_not be_empty
    expect(object.errors.include?(:base)).to be true
  end

  it 'maps remote errors on non-existing attributes to "base" as well' do
    object = form.from_resource 'name' => 'Hasso'
    object.remote_errors({
      'wealth' => ['too_low'],
    })

    expect(object.errors).to_not be_empty
    expect(object.errors.include?(:base)).to be true
  end
end
