require 'rails_helper'
require 'json'

RSpec.feature 'defence request creation' do

  before do
    create_cso_and_login
  end

  scenario 'Filling in form manually for own solicitor', js: true do
    visit root_path
    click_link 'New Defence Request'
    expect(page).to have_content ('New Defence Request')


    within '.new_defence_request' do
      choose 'Own'
      within '.details' do
        fill_in 'Solicitor Name', with: 'Bob Smith'
        fill_in 'Solicitor Firm', with: 'Acme Solicitors'
        fill_in 'Phone Number', with: '0207 284 0000'
        fill_in 'Custody Number', with: '#CUST-01234'
        fill_in 'Allegations', with: 'BadMurder'
        select('09', from: 'defence_request_time_of_arrival_4i')
        select('30', from: 'defence_request_time_of_arrival_5i')
      end

      within '.detainee' do
        fill_in 'Detainee Surname', with: 'Mannie'
        fill_in 'Detainee First Name', with: 'Badder'
        choose 'Male'
        check 'defence_request[adult]'
        select('1976', from: 'defence_request_date_of_birth_1i')
        select('January', from: 'defence_request_date_of_birth_2i')
        select('1', from: 'defence_request_date_of_birth_3i')
        check 'defence_request[appropriate_adult]'
      end
      fill_in 'Comments', with: 'This is a very bad man. Send him down...'
      click_button 'Create Defence request'
    end
    an_audit_should_exist_for_the_defence_request_creation
    expect(page).to have_content 'Bob Smith'
    expect(page).to have_content 'DefenceRequest successfully created'
  end

  scenario 'selecting own solicior and choosing from search box', js: true do
   stub_solicitor_search_for_bob_smith
   visit root_path
   click_link 'New Defence Request'
   choose 'Own'
   fill_in 'q', with: "Bob Smith"

   click_button 'Search'
   expect(page).to have_content 'Bobson Smith'
   expect(page).to have_content 'Bobby Bob Smithson'

   click_link 'Bobson Smith'
   expect(page).to_not have_content 'Bobby Bob Smithson'
   expect(page).to have_field 'Solicitor Name', with: 'Bobson Smith'
   expect(page).to have_field 'Solicitor Firm', with: 'Kreiger LLC'
   expect(page).to have_field 'Phone Number', with: '248.412.8095'
  end

  scenario 'performing multiple own solicitor searches', js: true do
   stub_solicitor_search_for_bob_smith
   stub_solicitor_search_for_barry_jones

   visit root_path
   click_link 'New Defence Request'
   choose 'Own'
   fill_in 'q', with: "Bob Smith"
   click_button 'Search'
   expect(page).to have_content 'Bobson Smith'

   fill_in 'q', with: "Barry Jones"
   click_button 'Search'

   expect(page).to_not have_content 'Bobson Smith'
   expect(page).to have_content 'Barry Jones'
  end

  scenario "searching for someone who doesn't exist", js: true do
   stub_solicitor_search_for_mystery_man

   visit root_path
   click_link 'New Defence Request'
   choose 'Own'
   fill_in 'q', with: "Mystery Man"
   click_button 'Search'

   expect(page).to have_content 'No results found'
  end

  scenario "toggling duty or own", js: true do
   stub_solicitor_search_for_bob_smith

   visit root_path
   click_link 'New Defence Request'
   choose 'Own'
   fill_in 'q', with: "Bob Smith"
   click_button 'Search'
   click_link 'Bobson Smith'
   choose 'Duty'

   expect(page).to have_field 'Solicitor Name', with: "", disabled: true
   expect(page).to have_field 'Solicitor Firm', with: "", disabled: true
   expect(page).to have_field 'Scheme', with: "No Scheme", disabled: false
   expect(page).to_not have_content 'Bobson Smith'

   choose 'Own'
   expect(page).to have_field 'Scheme', with: "No Scheme", disabled: true
   expect(page).to have_field 'q', with: ''
  end

end

def stub_solicitor_search_for_bob_smith
  body = File.open 'spec/fixtures/bob_smith_solicitor_search.json'
  stub_request(:post, "http://solicitor-search.herokuapp.com/search/?q=Bob%20Smith").
    to_return(body: body, status: 200)
end

def stub_solicitor_search_for_barry_jones
  body = File.open 'spec/fixtures/barry_jones_solicitor_search.json'
  stub_request(:post, "http://solicitor-search.herokuapp.com/search/?q=Barry%20Jones").
    to_return(body: body, status: 200)
end

def stub_solicitor_search_for_mystery_man
  body = { solicitors: [], firms: [] }.to_json
  stub_request(:post, "http://solicitor-search.herokuapp.com/search/?q=Mystery%20Man").
    to_return(body: body, status: 200)
end

def an_audit_should_exist_for_the_defence_request_creation
  expect(DefenceRequest.first.audits.length).to eq 1
  audit = DefenceRequest.first.audits.first

  expect(audit.auditable_type).to eq 'DefenceRequest'
  expect(audit.action).to eq 'create'
end