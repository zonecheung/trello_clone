require 'rails_helper'

describe Task, 'validations', type: :model do
  subject { FactoryBot.build(:task) }

  it { is_expected.to be_valid }

  it 'should not have position after validation' do
    subject.valid?
    expect(subject.position).to be_nil
  end

  context 'when task group is nil' do
    before(:each) do
      subject.task_group = nil
    end

    it { is_expected.not_to be_valid }
  end

  context 'when title is blank' do
    before(:each) do
      subject.title = ''
    end

    it { is_expected.not_to be_valid }
  end

  context 'when title is 255 characters' do
    before(:each) do
      subject.title = 'a' * 255
    end

    it { is_expected.to be_valid }
  end

  context 'when title is 256 characters' do
    before(:each) do
      subject.title = 'a' * 256
    end

    it { is_expected.not_to be_valid }
  end

  context 'when created' do
    before(:each) do
      subject.save!
    end

    it 'should have position assigned' do
      expect(subject.position).not_to be_nil
    end

    context 'when a new one is added in the same board' do
      let!(:another_task) do
        FactoryBot.create(:task, task_group: subject.task_group)
      end

      it 'should have a position' do
        expect(another_task.position).not_to be_nil
      end

      it 'should have a different position from previous task' do
        expect(another_task.position).not_to eql(subject.position)
      end

      context 'when the task group is destroyed' do
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

describe Task, 'move_to_position' do
  let!(:board) { FactoryBot.create(:board) }
  let!(:task_group1) { FactoryBot.create(:task_group, board: board) }
  let!(:task_group2) { FactoryBot.create(:task_group, board: board) }
  let!(:task1_1) { FactoryBot.create(:task, task_group: task_group1) }
  let!(:task1_2) { FactoryBot.create(:task, task_group: task_group1) }
  let!(:task1_3) { FactoryBot.create(:task, task_group: task_group1) }
  let!(:task2_1) { FactoryBot.create(:task, task_group: task_group2) }
  let!(:task2_2) { FactoryBot.create(:task, task_group: task_group2) }
  let!(:task2_3) { FactoryBot.create(:task, task_group: task_group2) }

  before(:each) do
    task_group1.reload
    task_group2.reload
  end

  it 'should have certain tasks in the task groups' do
    expect(task_group1.tasks.count).to eql(3)
    expect(task_group2.tasks.count).to eql(3)
  end

  context 'when moved in the same task group' do
    before(:each) do
      expect(task1_3.move_to_position(board.id, task_group1.id, 1)).to be(true)
      task_group1.reload
      task_group2.reload
    end

    it 'should not change the size of the tasks in task groups' do
      expect(task_group1.tasks.count).to eql(3)
      expect(task_group2.tasks.count).to eql(3)
    end

    it 'should change the order of the tasks' do
      expect(task_group1.tasks[0]).to eql(task1_3)
      expect(task_group1.tasks[1]).to eql(task1_1)
      expect(task_group1.tasks[2]).to eql(task1_2)
    end
  end

  context 'when moved to a different task group' do
    before(:each) do
      expect(task1_1.move_to_position(board.id, task_group2.id, 1)).to be(true)
      task_group1.reload
      task_group2.reload
    end

    it 'should change the size of the tasks in task groups' do
      expect(task_group1.tasks.count).to eql(2)
      expect(task_group2.tasks.count).to eql(4)
    end

    it 'should remove the task from the source task group' do
      expect(task_group1.tasks.pluck(:id)).not_to include(task1_1.id)
    end

    it 'should add the task to the target task group' do
      expect(task_group2.tasks.pluck(:id)).to include(task1_1.id)
    end

    it 'should change the order of the tasks' do
      task_group1.tasks.each_with_index do |task, i|
        expect(task.position).to eql(i + 1)
      end
      task_group2.tasks.each_with_index do |task, i|
        expect(task.position).to eql(i + 1)
      end
    end
  end

  context 'when moved to a non-existent task group' do
    it 'should return false' do
      expect(task1_1.move_to_position(board.id, -1, 1)).to be(false)
    end

    it 'should set the error message' do
      task1_1.move_to_position(board.id, -1, 1)
      expect(task1_1.errors[:task_group_id]).to(
        include(I18n.t('shared.not_found'))
      )
    end
  end

  context 'when moved to a task group in different board' do
    let!(:another_board) { FactoryBot.create(:board) }
    let!(:another_task_group) do
      FactoryBot.create(:task_group, board: another_board)
    end

    it 'should return true' do
      expect(
        task1_1.move_to_position(another_board.id, another_task_group.id, 1)
      ).to be(true)
    end

    it 'should remove the task from current task group' do
      expect do
        task1_1.move_to_position(another_board.id, another_task_group.id, 1)
      end.to(change { task_group1.tasks.count }.by(-1))
      expect(task_group1.tasks).not_to include(task1_1)
    end

    it 'should add the task to the new task group' do
      expect do
        task1_1.move_to_position(another_board.id, another_task_group.id, 1)
      end.to(change { another_task_group.tasks.count }.by(1))
      expect(another_task_group.tasks).to include(task1_1)
    end

    context 'when the task group doesn\'t belong to the board' do
      it 'should return false' do
        expect(
          task1_1.move_to_position(board.id, another_task_group.id, 1)
        ).to be(false)
      end

      it 'should set the error message' do
        task1_1.move_to_position(board.id, another_task_group.id, 1)
        expect(task1_1.errors[:task_group_id]).to(
          include(I18n.t('shared.not_found'))
        )
      end
    end
  end
end
