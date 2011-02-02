Feature: Studio management
    As an user
    I want to manage releases
    So that I can make video clips available to other users

    Scenario Outline: Studio owner uploads a some new releases
        Given the user with username "<user>" and password "<pass>" is logged in
        When he clicks the "link" with "Add New Release"
          And "<user>" selects some files for uploading
        Then he should see "Two (2) clips were successfully saved"

    Examples:
      |user |pass|
      |aaron|test|

    Scenario: Studio owner deletes a some releases
        Given the user with username "nutty" and password "test" is logged in
        When he clicks the "link" with "Manage Releases"
          And he clicks the "checkbox" with "id[1]" "id"
          And he clicks the "checkbox" with "id[2]" "id"
          And he clicks the "ok" button on the javascript popup "Are you sure you want to delete the selected Release" launched by the "link" with "delete_selected" "id"
        Then he should see "Deleted release(s)"

    Scenario: Studio owner edits a release without changing default fields
        Given the user with username "nutty" and password "jama1kama1" is logged in
        When he clicks the "link" with "Manage Releases" "text"
          And he clicks the "image" with "Sarah_tn" "alt"
          And he clicks the "button" with "submit_release" "id"
        Then he should be directed back to the manage releases page

    Scenario: Studio owner edits a release without required fields
        Given the user with username "nutty" and password "jama1kama1" is logged in
        When he clicks the "link" with "Manage Releases" "text"
          And he clicks the "image" with "Sarah_tn" "alt"
          And he enters "live" in the "select_list" with attribute "id" == "release_published_as"
          And he clicks the "button" with "commit" "name"
        Then he should be see some errors

    Scenario: Studio owner edits a release with required fields
        Given the user with username "nutty" and password "jama1kama1" is logged in
        When he clicks the "link" with "Manage Releases" "text"
          And he clicks the "image" with "Sarah_tn" "alt"
          And he enters "1" in the "select_list" with attribute "id" == "release_genre"
          And he enters "Sarah Demo" in the "text_field" with attribute "id" == "release_title"
          And he enters "Sarah is going to demo the Sybian for us" in the "text_field" with attribute "id" == "release_body_text"
          And he enters "4.99" in the "text_field" with attribute "id" == "release_price"
          And he enters "sarah, sybian, demo" in the "text_field" with attribute "id" == "tag_list"
          And he enters "live" in the "select_list" with attribute "id" == "release_published_as"
          And he clicks the "button" with "commit" "name"
        Then he should be directed back to the manage releases page

