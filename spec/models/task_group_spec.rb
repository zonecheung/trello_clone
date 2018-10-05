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

describe TaskGroup, 'move_to_position' do
  # NOTE: There are 3 default task groups, but we don't want to rely on them.
  let!(:board) { FactoryBot.create(:board) }
  let!(:task_group1) { FactoryBot.create(:task_group, board: board) }
  let!(:task_group2) { FactoryBot.create(:task_group, board: board) }
  let!(:task_group3) { FactoryBot.create(:task_group, board: board) }

  before(:each) do
    board.reload
  end

  it 'should have certain task groups in the board' do
    expect(board.task_groups).to include(task_group1)
    expect(board.task_groups).to include(task_group2)
    expect(board.task_groups).to include(task_group3)
  end

  describe 'when moved in the same board' do
    it 'should not change the size of the task groups in the board' do
      expect { task_group3.move_to_position(board.id, 1) }.not_to(
        change { board.task_groups.count }
      )
    end

    it 'should change the order of the task groups' do
      task_group3.move_to_position(board.id, 1)
      expect(board.task_groups[0]).to eql(task_group3)
      expect(board.task_groups[-2]).to eql(task_group1)
      expect(board.task_groups[-1]).to eql(task_group2)
    end
  end

  describe 'when moved to a non-existent board' do
    it 'should return false' do
      expect(task_group1.move_to_position(-1, 1)).to be(false)
    end

    it 'should set the error message' do
      task_group1.move_to_position(-1, 1)
      expect(task_group1.errors[:board_id]).to(
        include(I18n.t('shared.not_found'))
      )
    end
  end

  describe 'when moved to a different board' do
    let(:another_board) { FactoryBot.create(:board) }

    it 'should return true' do
      expect(task_group1.move_to_position(another_board.id, 1)).to be(true)
    end

    it 'should remove the task group from current board' do
      expect do
        task_group1.move_to_position(another_board.id, 1)
      end.to(change { board.task_groups.count }.by(-1))
      expect(board.task_groups).not_to include(task_group1)
    end

    it 'should add the task group to the new board' do
      expect do
        task_group1.move_to_position(another_board.id, 1)
      end.to(change { another_board.task_groups.count }.by(1))
      expect(another_board.task_groups).to include(task_group1)
    end

    it 'should change the order of the task groups' do
      board.task_groups.each_with_index do |task_group, i|
        expect(task_group.position).to eql(i + 1)
      end
      another_board.task_groups.each_with_index do |task_group, i|
        expect(task_group.position).to eql(i + 1)
      end
    end
  end
end
