require 'rails_helper'

shared_examples_for 'content with an is_public scope' do
  context 'when model is in a public universe' do
    let(:universe) { create(:universe, privacy: 'public') }

    context 'when model is private' do
      let(:model) {
        create(
          described_class.model_name.param_key.to_sym,
          universe: universe,
          privacy: 'private'
        )
      }

      describe '#is_public' do
        subject { described_class.is_public }
        it { is_expected.to include(model) }
      end
    end

    context 'when model is public' do
      let(:model) {
        create(
          described_class.model_name.param_key.to_sym,
          universe: universe,
          privacy: 'public'
        )
      }

      describe '#is_public' do
        subject { described_class.is_public }
        it { is_expected.to include(model) }
      end
    end
  end

  context 'when model is in a private universe' do
    let(:universe) { build(:universe, privacy: 'private') }

    context 'when model is private' do
      let(:model) {
        create(
          described_class.model_name.param_key.to_sym,
          universe: universe,
          privacy: 'private'
        )
      }

      describe '#is_public' do
        subject { described_class.is_public }
        it { is_expected.to_not include(model) }
      end
    end

    context 'when model is public' do
      let(:model) {
        create(
          described_class.model_name.param_key.to_sym,
          universe: universe,
          privacy: 'public'
        )
      }

      describe '#is_public' do
        subject { described_class.is_public }
        it { is_expected.to include(model) }
      end
    end
  end
end

RSpec.describe Character, type: :model do
  it_behaves_like 'content with an is_public scope'
end

RSpec.describe Item, type: :model do
  it_behaves_like 'content with an is_public scope'
end
