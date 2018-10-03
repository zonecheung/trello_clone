require 'rails_helper'

describe TaskGroup, 'validations', type: :model do
  subject { FactoryBot.build(:task_group) }

  it { is_expected.to be_valid }

  it 'should not have position after validation' do
    subject.valid?
    expect(subject.position).to be_nil
  end

  describe 'when board is nil' do
    before(:each) do
      subject.board = nil
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
      let!(:another_task_group) do
        FactoryBot.create(:task_group, board: subject.board)
      end

      it 'should have a position' do
        expect(another_task_group.position).not_to be_nil
      end

      it 'should have a different position from previous task group' do
        expect(another_task_group.position).not_to eql(subject.position)
      end

      describe 'when the board is destroyed' do
        before(:each) do
          subject.board.destroy
        end

        it 'should destroy all the task groups as well' do
          expect(TaskGroup).not_to exist(subject.id)
          expect(TaskGroup).not_to exist(another_task_group.id)
        end
      end
    end
  end
end
