# frozen_string_literal: true

require 'spec_helper'

describe Dashboard::Poll::Question, type: :component do
  subject(:rendered) { render_inline(component) }

  let(:poll) { create(:poll, :current) }

  describe 'voting mode' do
    let(:component) { described_class.vote(poll) }

    it 'renders a form to submit the vote' do
      expect(rendered).to have_css "form[action='/polls/#{poll.id}/vote']"
      expect(rendered).to have_button 'Vote'
    end

    it 'renders the answer options' do
      expect(rendered).to have_text 'I like it', count: 3
      expect(rendered).to have_unchecked_field 'poll', type: 'radio', count: 3
    end

    context 'when multiple choices are allowed' do
      let(:poll) { create(:poll, :current, :multiple_choice) }

      it 'renders checkboxes for the answer options' do
        expect(rendered).to have_unchecked_field 'poll[]', type: 'checkbox', count: 3
      end
    end
  end
end
