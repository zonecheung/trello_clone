require 'rails_helper'

describe Board, 'validations', type: :model do
  subject { FactoryBot.build(:board) }

  it { is_expected.to be_valid }

  describe 'when the title is blank' do
    before(:each) do
      subject.title = ''
    end

    it { is_expected.not_to be_valid }
  end

  describe 'when title is 255 characters' do
    before(:each) do
      subject.title = 'a' * 255
    end

    it { is_expected.to be_valid }
  end

  describe 'when title is 256 characters' do
    before(:each) do
      subject.title = 'a' * 256
    end

    it { is_expected.not_to be_valid }
  end
end

describe Board, 'after_create', type: :model do
  subject { FactoryBot.build(:board) }

  it 'should not have any task_groups after validation' do
    subject.valid?
    expect(subject.task_groups.count).to eql(0)
  end

  describe 'when created' do
    before(:each) do
      subject.save!
    end

    it 'should have 3 default task_groups' do
      expect(subject.task_groups.count).to eql(3)
    end

    it 'should have task_groups in correct order' do
      task_groups = subject.task_groups
      expect(task_groups[0].title).to eql(I18n.t('task_groups.todo'))
      expect(task_groups[0].position).to eql(1)
      expect(task_groups[1].title).to eql(I18n.t('task_groups.doing'))
      expect(task_groups[1].position).to eql(2)
      expect(task_groups[2].title).to eql(I18n.t('task_groups.done'))
      expect(task_groups[2].position).to eql(3)
    end
  end
end
