require 'rails_helper'

RSpec.describe Character, type: :model do
  context 'when name is nil' do
    subject { build(:character, name: nil) }
    it { is_expected.to_not be_valid }
  end
end
