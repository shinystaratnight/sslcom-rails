require "rspec"

describe User do

  it "should consolidate logins" do
    user_with_dupes.consolidate_logins("username", "password")
=begin
    if user has duplicate v2 users and is not consolidated
    then find the duplicate v2 user matching the username
    and copy it's username, crypted password, and email in the respective users fields
    and mark the user consolidated
=end
    true.should == false
  end
end


=begin
logging in

if user has duplicate v2 users and is not consolidated
then find the duplicate v2 user matching the username
and copy it's username, crypted password, and email in the respective users fields
and mark the user consolidated
and attempt to login the user


finding
if user has duplicate v2 users and is not consolidated
then find the duplicate v2 user matching the username
and copy it's username, crypted password, and email in the respective users fields
and mark the user consolidated
send the username to the corresponding email


resetting password
if user has duplicate v2 users and is not consolidated
then find the duplicate v2 user matching the username
and copy it's username, crypted password, and email in the respective users fields
and mark the user consolidated
attempt to reset the password=end
