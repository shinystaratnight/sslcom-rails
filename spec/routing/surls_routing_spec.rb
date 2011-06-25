require "spec_helper"

describe SurlsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/surls" }.should route_to(:controller => "surls", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/surls/new" }.should route_to(:controller => "surls", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/surls/1" }.should route_to(:controller => "surls", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/surls/1/edit" }.should route_to(:controller => "surls", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/surls" }.should route_to(:controller => "surls", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/surls/1" }.should route_to(:controller => "surls", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/surls/1" }.should route_to(:controller => "surls", :action => "destroy", :id => "1")
    end

  end
end
