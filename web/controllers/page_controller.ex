defmodule S3.PageController do
  use S3.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
