import { shallowMount } from '@vue/test-utils'
import axios from 'axios'
import Task from '../../../app/javascript/packs/components/task_vue.js'

jest.mock('axios')

# We're unit testing, remove child components and template.
Task.components = {}
Task.template = '<div></div>'

describe 'TaskGroup component', ->
  task1 = { id: 1, title: 'ID Card' }
  task2 = { id: 2, title: 'Health Card' }
  task3 = { id: 3, title: 'Insurance Card' }
  task_group1 = { id: 1, title: 'Santa\'s List' }
  task_group2 = { id: 2, title: 'Bucket List', tasks: [task1, task2, task3] }
  task_group3 = { id: 3, title: 'Grinch\'s List' }
  task_group4 = { id: 4, title: 'Song List', tasks: [] }
  boards = [
    { id: 1, title: 'Board 1', task_groups: [] },
    { id: 2, title: 'Board 2', task_groups: [
        task_group1, task_group2, task_group3
      ]
    },
    { id: 3, title: 'Board 3', task_groups: [task_group4] }
  ]
  $parent = {
    board: boards[1],
    boards: boards,
    task_group: task_group2
  }

  component = null
  vm = null

  beforeEach ->
    component = shallowMount(
      Task,
      propsData:
        task: task2
      mocks:
        $parent
    )
    vm = component.vm

  it 'is a Vue instance', ->
    expect(component.isVueInstance()).toBeTruthy()

  it 'should have the correct board', ->
    vm.$nextTick ->
      expect(vm.board.id).toEqual(2)
      expect(vm.board.task_groups.length).toEqual(3)

  it 'should have the correct task_group', ->
    vm.$nextTick ->
      expect(vm.task_group.id).toEqual(2)
      expect(vm.task_group.tasks.length).toEqual(3)

  describe 'checking methods', ->
    describe 'when updating a task', ->
      beforeAll ->
        axios.patch.mockResolvedValue({})

      it 'should call axios.patch once', ->
        vm.$nextTick ->
          vm.task.title = 'Bank Card'
          vm.update()
          vm.$nextTick ->
            expect(axios.patch.mock.calls.length).toEqual(1)
            expect(axios.patch.mock.calls[0]).toEqual(
              ['/api/boards/2/task_groups/2/tasks/2',
               { task: { title: 'Bank Card' } }]
            )

      it 'should reset the editing flag', ->
        vm.$nextTick ->
          vm.task.title = 'Bank Card'
          vm.parent.editing_task_id = vm.task.id
          vm.update()
          vm.$nextTick ->
            expect(vm.parent.editing_task_id).toEqual(null)

      it 'should not call the axios.patch if the title is blank', ->
        vm.$nextTick ->
          vm.task.title = ''
          vm.update()
          expect(axios.patch.mock.calls.length).toEqual(0)

    describe 'when destroying a task', ->
      beforeAll ->
        axios.delete.mockResolvedValue({})

      describe 'when confirmed in the dialog', ->
        beforeEach ->
          global.confirm = jest.fn -> true

        it 'should remove task from task_group', ->
          vm.$nextTick ->
            expect(vm.task_group.tasks.length).toEqual(3)
            vm.destroy()
            vm.$nextTick ->
              expect(vm.task_group.tasks.length).toEqual(2)

        it 'should call axios.delete once', ->
          vm.$nextTick ->
            vm.destroy()
            vm.$nextTick ->
              expect(axios.delete.mock.calls.length).toEqual(1)
              expect(axios.delete.mock.calls[0]).toEqual(
                ['/api/boards/2/task_groups/2/tasks/2']
              )

      describe 'when not confirmed in the dialog', ->
        beforeEach ->
          global.confirm = jest.fn -> false

        it 'should not call axios.delete', ->
          vm.$nextTick ->
            vm.destroy()
            expect(axios.delete.mock.calls.length).toEqual(0)

    describe 'when moving a task', ->
      beforeAll ->
        axios.patch.mockResolvedValue({})

      beforeEach ->
        # Re-assign because the object was modified by previous operations.
        vm.task_group.tasks = [task1, task2, task3]

      it 'should have 3 tasks in the task_group', ->
        vm.$nextTick ->
          expect(vm.task_group.tasks.length).toEqual(3)

      describe 'in the same board', ->
        beforeEach ->
          vm.target_board_id = vm.board.id

        describe 'in the same task_group', ->
          beforeEach ->
            vm.target_task_group_id = vm.task_group.id

          describe 'when position is not changed', ->
            beforeEach ->
              vm.target_position = 2

            it 'should not call axios.patch', ->
              vm.$nextTick ->
                vm.move()
                vm.$nextTick ->
                  expect(axios.patch.mock.calls.length).toEqual(0)

            it 'should not change the position in current task_group', ->
              vm.$nextTick ->
                vm.move()
                vm.$nextTick ->
                  expect(vm.task_group.tasks[1]).toEqual(task2)

          describe 'when the position is changed', ->
            beforeEach ->
              vm.target_position = 1

            it 'should call axios.patch once', ->
              vm.$nextTick ->
                vm.move()
                vm.$nextTick ->
                  expect(axios.patch.mock.calls.length).toEqual(1)
                  expect(axios.patch.mock.calls[0]).toEqual(
                    [
                      '/api/boards/2/task_groups/2/tasks/2/move_to_position', {
                        target_board_id: 2, target_task_group_id: 2, position: 1
                      }
                    ]
                  )

            it 'should change the position in current task_group', ->
              vm.$nextTick ->
                vm.move()
                vm.$nextTick ->
                  expect(vm.task_group.tasks[0]).toEqual(task2)

            it 'should reset the active modal flag', ->
              vm.$nextTick ->
                vm.parent.active_modal_task_id = 2
                vm.move()
                vm.$nextTick ->
                  expect(vm.parent.active_modal_task_id).toEqual(null)

        describe 'to another task_group', ->
          beforeEach ->
            # Reset the tasks in target task_group.
            vm.board.task_groups[0].tasks = []
            vm.target_task_group_id = vm.board.task_groups[0].id
            vm.target_position = 1

          it 'should call axios.patch once', ->
            vm.$nextTick ->
              vm.move()
              vm.$nextTick ->
                expect(axios.patch.mock.calls.length).toEqual(1)
                expect(axios.patch.mock.calls[0]).toEqual(
                  ['/api/boards/2/task_groups/2/tasks/2/move_to_position',
                   { target_board_id: 2, target_task_group_id: 1, position: 1 }]
                )

          it 'should be removed from current task_group', ->
            vm.$nextTick ->
              vm.move()
              vm.$nextTick ->
                expect(vm.task_group.tasks.length).toEqual(2)
                expect(vm.task_group.tasks).not.toContain(task2)

          it 'should be added to another task_group', ->
            vm.$nextTick ->
              vm.move()
              vm.$nextTick ->
                expect(vm.board.task_groups[0].tasks.length).toEqual(1)
                expect(vm.board.task_groups[0].tasks).toContain(task2)

      describe 'to another board', ->
        beforeEach ->
          vm.target_board_id = 3
          vm.target_task_group_id = 4
          vm.target_position = 1

        describe 'when confirmed in the dialog', ->
          beforeEach ->
            global.confirm = jest.fn -> true
            # Reset the tasks in target task_group.
            vm.boards[2].task_groups[0].tasks = []

          it 'should call axios.patch once', ->
            vm.$nextTick ->
              vm.move()
              vm.$nextTick ->
                expect(axios.patch.mock.calls.length).toEqual(1)
                expect(axios.patch.mock.calls[0]).toEqual(
                  ['/api/boards/2/task_groups/2/tasks/2/move_to_position',
                   { target_board_id: 3, target_task_group_id: 4, position: 1 }]
                )

          it 'should be removed from current task_group', ->
            vm.$nextTick ->
              vm.move()
              vm.$nextTick ->
                expect(vm.task_group.tasks.length).toEqual(2)
                expect(vm.task_group.tasks).not.toContain(task2)

          it 'should be added to another task_group', ->
            vm.$nextTick ->
              vm.move()
              vm.$nextTick ->
                expect(vm.boards[2].task_groups[0].tasks.length).toEqual(1)
                expect(vm.boards[2].task_groups[0].tasks).toContain(task2)

        describe 'when not confirmed in the dialog', ->
          beforeEach ->
            global.confirm = jest.fn -> false

          it 'should not call axios.patch', ->
            vm.$nextTick ->
              vm.move()
              expect(axios.patch.mock.calls.length).toEqual(0)
