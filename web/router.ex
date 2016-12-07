defmodule S3.Router do
  use S3.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Other scopes may use custom stacks.
  scope "/api", S3 do
    pipe_through :api

    get "/signature", SigningController, :show
    # post "/signature", SigningController, :create
  end

  scope "/", S3 do
    pipe_through :browser # Use the default browser stack

    get "/success", SigningController, :success
    get "/*x", PageController, :index
  end


end
