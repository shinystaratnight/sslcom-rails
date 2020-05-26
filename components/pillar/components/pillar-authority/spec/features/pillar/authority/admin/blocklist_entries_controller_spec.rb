require 'rails_helper'

module Pillar
  module Authority
    module Admin
      RSpec.describe BlocklistEntriesController, type: :feature do
        context "as an authenticated & authroized user" do
          feature "should be able manage the resources" do
            scenario "should render empty result message" do
              visit authority.admin_blocklist_entries_path
              expect(page).to have_content("Manage Blocklist Entries")
              expect(page).to have_content("NO RESULTS FOUND")
            end
          end

          feature "should be able to create a resource" do
            scenario "with valid data" do
              visit authority.admin_blocklist_entries_path
              wait_for_turbolinks
              expect(page).to have_content("Manage Blocklist Entries")
              click_link("Create")
              wait_for_turbolinks
              fill_in("blocklist_entry_pattern", with: "Test-Pattern-Here")
              fill_in("blocklist_entry_description", with: "description")
              check("blocklist_entry[common_name]")
              click_on("Save Blocklist Entry")
              wait_for_turbolinks
              expect(page).to have_current_path(authority.admin_blocklist_entries_path)
              expect(page).to have_content("The blocklist entry has been created.")
              expect(page).to have_content("Manage Blocklist Entries")
              expect(page).to have_content("Test-Pattern-Here")
            end

            scenario "with invalid data" do
              visit authority.admin_blocklist_entries_path
              wait_for_turbolinks
              expect(page).to have_content("Manage Blocklist Entries")
              click_link("Create")
              wait_for_turbolinks
              click_on("Save Blocklist Entry")
              wait_for_turbolinks
              expect(page).to have_current_path(authority.admin_blocklist_entries_path)
              expect(page).to have_content("The blocklist entry could not be created.")
              expect(page).to have_content("Create Blocklist Entry")
              expect(page).to have_selector :css, 'form div.field_with_errors'
            end
          end

          feature "should be able to edit a resource" do
            scenario "with valid data" do
              visit authority.admin_blocklist_entries_path
              wait_for_turbolinks
              expect(page).to have_content("Manage Blocklist Entries")
              click_link("MODIFY")
              wait_for_turbolinks
              expect(page).to have_content("Modify Blocklist Entry")
              fill_in("blocklist_entry_pattern", with: "Test-Pattern-Here-Updated")
              fill_in("blocklist_entry_description", with: "description")
              check("blocklist_entry[common_name]")
              click_on("Save Blocklist Entry")
              wait_for_turbolinks
              expect(page).to have_current_path(authority.admin_blocklist_entries_path)
              expect(page).to have_content("The blocklist entry has been updated.")
              expect(page).to have_content("Manage Blocklist Entries")
              expect(page).to have_content("Test-Pattern-Here-Updated")
            end

            scenario "with invalid data" do
              pending
            end
          end

          feature "should be able to delete a resource" do
            scenario "with valid id" do
              visit authority.admin_blocklist_entries_path
              wait_for_turbolinks
              expect(page).to have_content("Manage Blocklist Entries")
              find('a.dropdown-toggle').click
              click_link("Permanently Remove Item")
              wait_for_turbolinks
              click_button("Yes")
              wait_for_turbolinks
              expect(page).to have_current_path(authority.admin_blocklist_entries_path)
              expect(page).to have_content("The blocklist entry has been removed.")
              expect(page).to have_content("Manage Blocklist Entries")
              expect(page).to have_content("NO RESULTS FOUND")
            end
          end
        end
      end

      # context "as an unauthenticated or unauthorized user" do
      #   feature "when trying to visit any page" do
      #     scenario "should be redirected to the root path with an error message" do
      #       visit authority.admin_blocklists_path
      #       wait_for_turbolinks
      #       expect(page).to have_current_path(main_app.root_path)
      #       expect(page).to have_content("You don't have permission to view this page")
      #       expect(page).to have_content("Customer login")

      #       visit authority.new_admin_blocklists_path
      #       wait_for_turbolinks
      #       expect(page).to have_current_path(main_app.root_path)
      #       expect(page).to have_content("You don't have permission to view this page")
      #       expect(page).to have_content("Customer login")
            
      #       visit authority.edit_admin_blocklist_path(id: 1)
      #       wait_for_turbolinks
      #       expect(page).to have_current_path(main_app.root_path)
      #       expect(page).to have_content("You don't have permission to view this page")
      #       expect(page).to have_content("Customer login") 

      #       visit authority.admin_blocklist_path(id: 1)
      #       wait_for_turbolinks
      #       expect(page).to have_current_path(main_app.root_path)
      #       expect(page).to have_content("You don't have permission to view this page")
      #       expect(page).to have_content("Customer login") 

      #       visit authority.admin_blocklist_path(id: 1, method: :delete)
      #       wait_for_turbolinks
      #       expect(page).to have_current_path(main_app.root_path)
      #       expect(page).to have_content("You don't have permission to view this page")
      #       expect(page).to have_content("Customer login")
      #     end
      #   end
      # end
    end
  end
end
