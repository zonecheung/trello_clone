require 'rails_helper'

feature 'Task group (or List) management', type: :feature, js: true do
  context 'existing board' do
    before(:each) do
      given_a_board_with_two_task_groups
      visit_the_board_page
    end

    scenario 'when viewed' do
      expect(page).to have_text('Awesome Board')
      expect(page).to have_text('To Do List')
      expect(page).to have_text('Doing List')
    end

    scenario 'change the task group title' do
      # Find the task group title and click it.
      expect(page).not_to have_selector('textarea')
      find('a', text: 'To Do List').click
      expect(page).to have_selector('textarea')

      # Change the task group title.
      find('textarea').fill_in with: 'Will Do List'

      # Click outside to trigger onblur.
      find('body').click
      expect(page).not_to have_selector('textarea')

      # Check for changes.
      expect(page).not_to have_text('To Do List')
      expect(page).to have_text('Will Do List')
    end

    scenario 'destroy the task group (and confirm)' do
      hover_over_ellipsis_button('To Do List')

      # Click the delete button.
      within(:css, '.dropdown-content') do
        # Confirm the dialog.
        accept_confirm do
          find('a', text: I18n.t('task_groups.delete')).click
        end
      end
      expect(page).not_to have_text('To Do List')
    end

    scenario 'destroy the task group (and cancel)' do
      hover_over_ellipsis_button('To Do List')

      # Click the delete button.
      within(:css, '.dropdown-content') do
        # Cancel the dialog.
        dismiss_confirm do
          find('a', text: I18n.t('task_groups.delete')).click
        end
      end
      expect(page).to have_text('To Do List')
    end

    scenario 'create a new task group' do
      # Click on the add task group link.
      expect(page).not_to have_text(I18n.t('task_groups.add'))
      find('a', text: I18n.t('task_groups.add_another')).click
      expect(page).to have_text(I18n.t('task_groups.add'))

      # Enter the new task group title.
      find('input').fill_in with: 'Done List'
      find('a', text: I18n.t('task_groups.add')).click

      expect(page).not_to have_selector('input')
      expect(page).to have_selector('a', text: 'Done List')
    end

    scenario 'move the task group in the same board to the right' do
      # Check the order of the task groups.
      expect(title_position('To Do List')).to be < title_position('Doing List')

      hover_over_ellipsis_button('To Do List')

      click_the_move_button

      # Change the position to 2.
      within(:css, '.modal .field', text: I18n.t('shared.position')) do
        select('2')
      end
      find('.modal button', text: I18n.t('task_groups.move')).click

      expect(page).not_to have_selector('.modal select')

      # Check the order of the task groups.
      expect(title_position('To Do List')).to be > title_position('Doing List')
    end

    scenario 'move the task group in the same board to the left' do
      # Check the order of the task groups.
      expect(title_position('To Do List')).to be < title_position('Doing List')

      hover_over_ellipsis_button('Doing List')

      click_the_move_button

      # Change the position to 1.
      within(:css, '.modal .field', text: I18n.t('shared.position')) do
        select('1')
      end
      find('.modal button', text: I18n.t('task_groups.move')).click

      expect(page).not_to have_selector('.modal select')

      # Check the order of the task groups.
      expect(title_position('To Do List')).to be > title_position('Doing List')
    end
  end

  scenario 'move the task group to a different board' do
    given_a_board_with_two_task_groups
    given_another_board_with_two_task_groups
    visit_the_board_page

    hover_over_ellipsis_button('Doing List')

    click_the_move_button

    # Select another board.
    within(:css, '.modal .field', text: I18n.t('boards.board')) do
      select('Media Board')
    end
    # Select position in another board.
    within(:css, '.modal .field', text: I18n.t('shared.position')) do
      select('2')
    end

    # Confirm the dialog.
    accept_confirm do
      find('.modal button', text: I18n.t('task_groups.move')).click
    end

    expect(page).not_to have_selector('.modal select')

    # It should not have the moved task group.
    expect(page).not_to have_text('Doing List')

    # Visit another board.
    visit_another_board_page

    # It should have the moved task group.
    expect(page).to have_text('Doing List')

    # It should be at the correct position.
    expect(title_position('Song List')).to eql(0)
    expect(title_position('Doing List')).to eql(1)
    expect(title_position('Video List')).to eql(2)
  end

  private

  def given_a_board_with_two_task_groups
    @board = FactoryBot.create(:board, title: 'Awesome Board')
    # Reset the task groups if there's any.
    @board.task_groups.destroy_all
    FactoryBot.create(:task_group, board: @board, title: 'To Do List')
    FactoryBot.create(:task_group, board: @board, title: 'Doing List')
  end

  def given_another_board_with_two_task_groups
    @another_board = FactoryBot.create(:board, title: 'Media Board')
    # Reset the task groups if there's any.
    @another_board.task_groups.destroy_all
    FactoryBot.create(:task_group, board: @another_board, title: 'Song List')
    FactoryBot.create(:task_group, board: @another_board, title: 'Video List')
  end

  def visit_the_board_page
    visit "/?board_id=#{@board.id}"
  end

  def visit_another_board_page
    visit "/?board_id=#{@another_board.id}"
  end

  def hover_over_ellipsis_button(text)
    expect(page).not_to have_selector('.dropdown-content')
    within(:css, '.task-group-container', text: text) do
      first('button', text: '…').hover
    end
    expect(page).to have_selector('.dropdown-content')
  end

  def click_the_move_button
    expect(page).not_to have_selector('.modal select')
    within(:css, '.dropdown-content') do
      find('a', text: I18n.t('task_groups.move')).click
    end
    expect(page).to have_selector('.modal select')
  end

  def title_position(text)
    page.all('.task-group-title a').index { |a| a.text == text }
  end
end
