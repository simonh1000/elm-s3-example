defmodule S3.SigningController do
  use S3.Web, :controller

  alias S3.Signing

  def show(conn, _params) do
      stem = "test"
      credential = Signing.credential()
      date = Signing.get_date() <> "T000000Z"
      policy = Signing.policy64(stem, url(conn))
      signature = Signing.signature(stem, url(conn), 30)

      render conn, "show.json", %{stem: stem,
                                  host: url(conn),
                                  credential: credential,
                                  date: date,
                                  policy: policy,
                                  signature: signature}
  end
  # def create(conn, %{"name" => stem}) do
  #     stem = "test"
  #     credential = Signing.credential()
  #     date = Signing.get_date() <> "T000000Z"
  #     policy = Signing.policy64(stem, url(conn))
  #     signature = Signing.signature(stem, url(conn), 30)
  #
  #     render conn, "show.json", %{stem: stem,
  #                                 host: url(conn),
  #                                 credential: credential,
  #                                 date: date,
  #                                 policy: policy,
  #                                 signature: signature}
  # end

  def success(conn, params) do
      render(conn, "etag.json", tag: params["etag"])
  end

end
