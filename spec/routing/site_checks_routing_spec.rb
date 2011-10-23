require "spec_helper"

describe SiteChecksController do
  describe "routing" do

    it "routes to #index" do
      get("/site_checks").should route_to("site_checks#index")
    end

    it "routes to #new" do
      get("/site_checks/new").should route_to("site_checks#new")
    end

    it "routes to #show" do
      get("/site_checks/1").should route_to("site_checks#show", :id => "1")
    end

    it "routes to #edit" do
      get("/site_checks/1/edit").should route_to("site_checks#edit", :id => "1")
    end

    it "routes to #create" do
      post("/site_checks").should route_to("site_checks#create")
    end

    it "routes to #update" do
      put("/site_checks/1").should route_to("site_checks#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/site_checks/1").should route_to("site_checks#destroy", :id => "1")
    end

  end
end
