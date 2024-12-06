# frozen_string_literal: true

require 'xui/form'
require 'action_controller/metal/strong_parameters'
require 'restify'

RSpec.describe 'Instantiation' do
  let(:form) do
    Class.new(XUI::Form) do
      self.form_name = 'test'

      attribute :title, :text
      attribute :number, :integer
    end
  end

  describe '#from_params' do
    it 'is assumed to not be persisted' do
      f = form.from_params('title' => 'Hey')
      expect(f).to_not be_persisted
    end

    it 'can be marked as persisted' do
      f = form.from_params('title' => 'Hey').tap(&:persisted!)
      expect(f).to be_persisted
    end

    describe 'with a hash' do
      it 'converts all known attributes according to their types' do
        f = form.from_params('title' => 'Hey', 'number' => '42')
        expect(f.title).to eq 'Hey'
        expect(f.number).to eq 42
      end

      it 'falls back to nil for missing keys' do
        f = form.from_params({})
        expect(f.title).to be_nil
        expect(f.number).to be_nil
      end
    end

    describe 'with Rails strong parameters (ActionController::Parameters)' do
      it 'takes all known attributes from a key named after the form name' do
        f = form.from_params(ActionController::Parameters.new(
          'test' => {'title' => 'Hey', 'number' => '42'}
        ))
        expect(f.title).to eq 'Hey'
        expect(f.number).to eq 42
      end

      it 'ignores unknown keys' do
        f = form.from_params(ActionController::Parameters.new(
          'test' => {'title' => 'Hey', 'number' => '42', 'unknown' => 123}
        ))
        expect { f.unknown }.to raise_error(NoMethodError)
      end

      # When dealing with strong parameters, we expect that all fields have
      # been sent by the browser
      it 'raises when form name key is missing' do
        expect do
          form.from_params(ActionController::Parameters.new({}))
        end.to raise_error(ActionController::ParameterMissing)
      end

      it 'gracefully handles missing keys in the child hash' do
        f = form.from_params(ActionController::Parameters.new(
          'test' => {'title' => 'Hey'}
        ))
        expect(f.number).to be_nil
      end

      it 'does not modify the parameters object' do
        params = ActionController::Parameters.new(
          'test' => {'title' => 'Hey', 'number' => '42'}
        )
        expect { form.from_params params }.not_to change(params[:test], :permitted?)
      end
    end
  end

  describe '#from_resource' do
    it 'is assumed to be persisted' do
      f = form.from_resource('title' => 'Hey')
      expect(f).to be_persisted
    end

    describe 'with a hash' do
      it 'converts all known attributes according to their types' do
        f = form.from_resource('title' => 'Hey', 'number' => '42')
        expect(f.title).to eq 'Hey'
        expect(f.number).to eq 42
      end

      it 'falls back to nil for missing keys' do
        f = form.from_resource({})
        expect(f.title).to be_nil
        expect(f.number).to be_nil
      end
    end

    describe 'with a Restify resource' do
      it 'converts all known attributes according to their types' do
        f = form.from_resource(
          Restify::Resource.new(nil, data: {'title' => 'Hey', 'number' => '42'})
        )
        expect(f.title).to eq 'Hey'
        expect(f.number).to eq 42
      end

      it 'falls back to nil for missing keys' do
        f = form.from_resource(
          Restify::Resource.new(nil, data: {})
        )
        expect(f.title).to be_nil
        expect(f.number).to be_nil
      end
    end
  end
end
