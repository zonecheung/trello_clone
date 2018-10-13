require 'rails_helper'

feature 'Task (or card) management', type: :feature, js: true do
  context 'existing board' do
    before(:each) do
      given_a_board_with_two_task_groups_and_tasks
      visit_the_board_page
    end

    scenario 'when viewed' do
      expect(page).to have_text('Awesome Board')
      expect(page).to have_text('To Do List')
      expect(page).to have_text('Doing List')
      expect(page).to have_text('Shopping')
      expect(page).to have_text('Cooking')
      expect(page).to have_text('Playing')
      expect(page).to have_text('Sleeping')
    end

    scenario 'change the task title' do
      # Find the task title and click it.
      expect(page).not_to have_selector('textarea')
      find('a', text: 'Shopping').click
      expect(page).to have_selector('textarea')

      # Change the task group title.
      find('textarea').fill_in with: 'Working'

      # Click outside to trigger onblur.
      find('body').click
      expect(page).not_to have_selector('textarea')

      # Check for changes.
      expect(page).not_to have_text('Shopping')
      expect(page).to have_text('Working')
    end

    scenario 'destroy the task (and confirm)' do
      hover_over_ellipsis_button('Shopping')

      # Click the delete button.
      within(:css, '.dropdown-content') do
        # Confirm the dialog.
        accept_confirm do
          find('a', text: I18n.t('tasks.delete')).click
        end
      end
      expect(page).not_to have_text('Shopping')
    end

    scenario 'destroy the task (and cancel)' do
      hover_over_ellipsis_button('Shopping')

      # Click the delete button.
      within(:css, '.dropdown-content') do
        # Cancel the dialog.
        dismiss_confirm do
          find('a', text: I18n.t('tasks.delete')).click
        end
      end
      expect(page).to have_text('Shopping')
    end

    scenario 'create a new task' do
      # Click on the first add task link.
      expect(page).not_to have_text(I18n.t('tasks.add'))
      first('a', text: I18n.t('tasks.add_another')).click
      expect(page).to have_text(I18n.t('tasks.add'))

      # Enter the new task title.
      find('input').fill_in with: 'Working'
      find('a', text: I18n.t('tasks.add')).click

      expect(page).not_to have_selector('input')
      expect(page).to have_selector('a', text: 'Working')
    end

    scenario 'move the task in the same task group down' do
      # Check the order of the task groups.
      expect(title_position('Shopping')).to be < title_position('Cooking')

      hover_over_ellipsis_button('Shopping')

      click_the_move_button

      # Change the position to 2.
      within(:css, '.modal .field', text: I18n.t('shared.position')) do
        select('2')
      end
      find('.modal button', text: I18n.t('tasks.move')).click

      expect(page).not_to have_selector('.modal select')

      # Check the order of the task groups.
      expect(title_position('Shopping')).to be > title_position('Cooking')
    end

    scenario 'move the task in the same task group up' do
      # Check the order of the task groups.
      expect(title_position('Shopping')).to be < title_position('Cooking')

      hover_over_ellipsis_button('Cooking')

      click_the_move_button

      # Change the position to 1.
      within(:css, '.modal .field', text: I18n.t('shared.position')) do
        select('1')
      end
      find('.modal button', text: I18n.t('tasks.move')).click

      expect(page).not_to have_selector('.modal select')

      # Check the order of the task groups.
      expect(title_position('Shopping')).to be > title_position('Cooking')
    end

    scenario 'move the task to a different task group' do
      hover_over_ellipsis_button('Shopping')

      click_the_move_button

      # Select another task group.
      within(:css, '.modal .field', text: I18n.t('task_groups.task_group')) do
        select('Doing List')
      end
      # Select position in another board.
      within(:css, '.modal .field', text: I18n.t('shared.position')) do
        select('2')
      end

      # Click move button.
      find('.modal button', text: I18n.t('tasks.move')).click

      expect(page).not_to have_selector('.modal select')

      # Check the first task group.
      within(:css, '.task-group-container', text: 'To Do List') do
        expect(page).not_to have_text('Shopping')
      end

      # Check the next task group.
      within(:css, '.task-group-container', text: 'Doing List') do
        expect(page).to have_text('Shopping')
        expect(title_position('Playing')).to eql(0)
        expect(title_position('Shopping')).to eql(1)
        expect(title_position('Sleeping')).to eql(2)
      end
    end
  end

  scenario 'move the task to a different board' do
    given_a_board_with_two_task_groups_and_tasks
    given_another_board_with_two_task_groups_and_tasks
    visit_the_board_page

    hover_over_ellipsis_button('Sleeping')

    click_the_move_button

    # Select another board.
    within(:css, '.modal .field', text: I18n.t('boards.board')) do
      select('Media Board')
    end
    # Select task group in another board.
    within(:css, '.modal .field', text: I18n.t('task_groups.task_group')) do
      select('Video List')
    end
    # Select position in another board.
    within(:css, '.modal .field', text: I18n.t('shared.position')) do
      select('2')
    end

    # Confirm the dialog.
    accept_confirm do
      find('.modal button', text: I18n.t('tasks.move')).click
    end

    expect(page).not_to have_selector('.modal select')

    # It should not have the moved task.
    expect(page).not_to have_text('Sleeping')

    # Visit another board.
    visit_another_board_page

    # It should have the moved task.
    expect(page).to have_text('Sleeping')

    # It should be at the correct position.
    within(:css, '.task-group-container', text: 'Video List') do
      expect(title_position('Avengers')).to eql(0)
      expect(title_position('Sleeping')).to eql(1)
      expect(title_position('Harry Potter')).to eql(2)
    end
  end

  private

  def given_a_board_with_two_task_groups_and_tasks
    @board = FactoryBot.create(:board, title: 'Awesome Board')
    # Reset the task groups if there's any.
    @board.task_groups.destroy_all
    task_group1 = FactoryBot.create(:task_group,
                                    board: @board, title: 'To Do List')
    task_group2 = FactoryBot.create(:task_group,
                                    board: @board, title: 'Doing List')
    FactoryBot.create(:task, task_group: task_group1, title: 'Shopping')
    FactoryBot.create(:task, task_group: task_group1, title: 'Cooking')
    FactoryBot.create(:task, task_group: task_group2, title: 'Playing')
    FactoryBot.create(:task, task_group: task_group2, title: 'Sleeping')
  end

  def given_another_board_with_two_task_groups_and_tasks
    @another_board = FactoryBot.create(:board, title: 'Media Board')
    # Reset the task groups if there's any.
    @another_board.task_groups.destroy_all
    task_group1 = FactoryBot.create(:task_group,
                                    board: @another_board, title: 'Song List')
    task_group2 = FactoryBot.create(:task_group,
                                    board: @another_board, title: 'Video List')
    FactoryBot.create(:task, task_group: task_group1, title: 'Unforgiven')
    FactoryBot.create(:task, task_group: task_group1, title: 'San Francisco')
    FactoryBot.create(:task, task_group: task_group2, title: 'Avengers')
    FactoryBot.create(:task, task_group: task_group2, title: 'Harry Potter')
  end

  def visit_the_board_page
    visit "/?board_id=#{@board.id}"
  end

  def visit_another_board_page
    visit "/?board_id=#{@another_board.id}"
  end

  def hover_over_ellipsis_button(text)
    expect(page).not_to have_selector('.dropdown-content')
    within(:css, '.task-container', text: text) do
      first('button', text: '…').hover
    end
    expect(page).to have_selector('.dropdown-content')
  end

  def click_the_move_button
    expect(page).not_to have_selector('.modal select')
    within(:css, '.dropdown-content') do
      find('a', text: I18n.t('tasks.move')).click
    end
    expect(page).to have_selector('.modal select')
  end

  def title_position(text)
    page.all('.task-title a').index { |a| a.text == text }
  end
end
