require 'rails_helper'

describe Task, 'validations', type: :model do
  subject { FactoryBot.build(:task) }

  it { is_expected.to be_valid }

  it 'should not have position after validation' do
    subject.valid?
    expect(subject.position).to be_nil
  end

  describe 'when task group is nil' do
    before(:each) do
      subject.task_group = nil
    end

    it { is_expected.not_to be_valid }
  end

  describe 'when title is blank' do
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

  describe 'when created' do
    before(:each) do
      subject.save!
    end

    it 'should have position assigned' do
      expect(subject.position).not_to be_nil
    end

    describe 'when a new one is added in the same board' do
      let!(:another_task) do
        FactoryBot.create(:task, task_group: subject.task_group)
      end

      it 'should have a position' do
        expect(another_task.position).not_to be_nil
      end

      it 'should have a different position from previous task' do
        expect(another_task.position).not_to eql(subject.position)
      end

      describe 'when the task group is destroyed' do
        before(:each) do
          subject.task_group.destroy
        end

        it 'should destroy all the tasks as well' do
          expect(Task).not_to exist(subject.id)
          expect(Task).not_to exist(another_task.id)
        end
      end
    end
  end
end
