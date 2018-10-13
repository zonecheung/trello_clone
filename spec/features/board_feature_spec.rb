require 'rails_helper'

feature 'Board management', type: :feature, js: true do
  scenario 'when viewed' do
    given_a_board

    visit_the_board_page

    expect(page).to have_content('Awesome Board')
    expect(page).to have_selector(:link_or_button, I18n.t('boards.boards'))
  end

  scenario 'change the board title' do
    given_a_board

    visit_the_board_page

    # Click the board title.
    expect(page).not_to have_selector('input')
    page.find('a', text: 'Awesome Board').click
    expect(page).to have_selector('input')

    # Change the board title.
    page.find('input').fill_in with: 'Super Board'

    # Click outside to trigger onblur.
    page.find('body').click
    expect(page).not_to have_selector('input')
    expect(page).to have_content('Super Board')
  end

  scenario 'destroy the board (and confirm)' do
    given_a_board

    visit_the_board_page

    # Hover on the 'Boards' button.
    expect(page).not_to have_selector('.dropdown-content')
    page.find('button', text: I18n.t('boards.boards')).hover
    expect(page).to have_selector('.dropdown-content')

    # Click the delete button.
    within(:css, '.dropdown-content') do
      # Confirm the dialog.
      page.accept_confirm do
        page.find('a', text: I18n.t('boards.delete')).click
      end
    end
    expect(page).not_to have_content('Awesome Board')
  end

  scenario 'destroy the board (but cancel)' do
    given_a_board

    visit_the_board_page

    # Hover on the 'Boards' button.
    expect(page).not_to have_selector('.dropdown-content')
    page.find('button', text: I18n.t('boards.boards')).hover
    expect(page).to have_selector('.dropdown-content')

    # Click the delete button.
    within(:css, '.dropdown-content') do
      # Cancel the dialog.
      page.dismiss_confirm do
        page.find('a', text: I18n.t('boards.delete')).click
      end
    end
    expect(page).to have_content('Awesome Board')
  end

  scenario 'create a new board' do


  end

  private

  def given_a_board
    @board = FactoryBot.create(:board, title: 'Awesome Board')
  end

  def visit_the_board_page
    visit "/?board_id=#{@board.id}"
  end
end
