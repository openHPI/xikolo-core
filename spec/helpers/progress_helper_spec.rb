# frozen_string_literal: true

require 'spec_helper'

class ProgressHelperTestClass
  include ProgressHelper
end

describe ProgressHelper, type: :helper do
  subject(:progress) do
    ProgressHelperTestClass.new.calc_progress(user_points, max_points)
  end

  let(:user_points) { 20.5 }
  let(:max_points) { 100 }

  it 'calculates the percentage, flooring the result' do
    expect(progress).to eq 20
  end

  context 'with achieved bonus points' do
    let(:user_points) { 110.5 }

    it 'calculates the percentage, and caps at 100%' do
      expect(progress).to eq 100
    end
  end

  context 'with zero user points' do
    let(:user_points) { 0 }

    it 'returns 0%' do
      expect(progress).to eq 0
    end
  end

  context 'with zero max points' do
    let(:max_points) { 0 }

    it 'returns 0%' do
      expect(progress).to eq 0
    end
  end

  context 'without any graded quiz or exercise' do
    let(:user_points) { nil }
    let(:max_points) { nil }

    it 'returns 0%' do
      expect(progress).to eq 0
    end
  end
end
