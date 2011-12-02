require "spec_helper"

describe UnsubscribesController do
  describe "routing" do

    it "routes to #index" do
      get("/unsubscribes").should route_to("unsubscribes#index")
    end

    it "routes to #new" do
      get("/unsubscribes/new").should route_to("unsubscribes#new")
    end

    it "routes to #show" do
      get("/unsubscribes/1").should route_to("unsubscribes#show", :id => "1")
    end

    it "routes to #edit" do
      get("/unsubscribes/1/edit").should route_to("unsubscribes#edit", :id => "1")
    end

    it "routes to #create" do
      post("/unsubscribes").should route_to("unsubscribes#create")
    end

    it "routes to #update" do
      put("/unsubscribes/1").should route_to("unsubscribes#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/unsubscribes/1").should route_to("unsubscribes#destroy", :id => "1")
    end

  end
end
