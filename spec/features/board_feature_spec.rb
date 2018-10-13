require 'rails_helper'

feature 'Board management', type: :feature, js: true do
  context 'existing board' do
    before(:each) do
      given_a_board
      visit_the_board_page
    end

    scenario 'when viewed' do
      expect(page).to have_text('Awesome Board')
      expect(page).to have_selector(:link_or_button, I18n.t('boards.boards'))
    end

    scenario 'change the board title' do
      # Click the board title.
      expect(page).not_to have_selector('input')
      find('a', text: 'Awesome Board').click
      expect(page).to have_selector('input')

      # Change the board title.
      find('input').fill_in with: 'Super Board'

      # Click outside to trigger onblur.
      find('body').click
      expect(page).not_to have_selector('input')

      # Check for changes.
      expect(page).not_to have_text('Awesome Board')
      expect(page).to have_text('Super Board')
    end

    scenario 'destroy the board (and confirm)' do
      # Hover on the 'Boards' button.
      hover_over_boards_button

      # Click the delete button.
      within(:css, '.dropdown-content') do
        # Confirm the dialog.
        accept_confirm do
          find('a', text: I18n.t('boards.delete')).click
        end
      end
      expect(page).not_to have_text('Awesome Board')
    end

    scenario 'destroy the board (but cancel)' do
      # Hover over the 'Boards' button.
      hover_over_boards_button

      # Click the delete button.
      within(:css, '.dropdown-content') do
        # Cancel the dialog.
        dismiss_confirm do
          find('a', text: I18n.t('boards.delete')).click
        end
      end
      expect(page).to have_text('Awesome Board')
    end
  end

  scenario 'create a new board' do
    visit '/'

    # It should not have the 'Add another list' text.
    expect(page).not_to have_text(I18n.t('task_groups.add_another'))

    # Hover over the 'Boards' button.
    hover_over_boards_button

    # Click the create button.
    within(:css, '.dropdown-content') do
      find('a', text: I18n.t('boards.new')).click
    end

    expect(page).to have_selector('.modal input')
    # Enter a new title for the board.
    find('.modal input').fill_in with: 'Super Board'
    # Click create.
    find('.modal button', text: I18n.t('boards.new')).click

    # It should close the modal.
    expect(page).not_to have_selector('.modal input')
    # It should have the created board displayed on the page.
    expect(page).to have_text('Super Board')

    # It should not have the 'Add another list' text.
    expect(page).to have_text(I18n.t('task_groups.add_another'))
  end

  private

  def given_a_board
    @board = FactoryBot.create(:board, title: 'Awesome Board')
  end

  def visit_the_board_page
    visit "/?board_id=#{@board.id}"
  end

  def hover_over_boards_button
    expect(page).not_to have_selector('.dropdown-content')
    find('button', text: I18n.t('boards.boards')).hover
    expect(page).to have_selector('.dropdown-content')
  end
end
