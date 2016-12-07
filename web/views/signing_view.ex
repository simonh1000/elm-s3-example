defmodule S3.SigningView do
  use S3.Web, :view

   def render("show.json", %{stem: stem, host: host, credential: credential, date: date, policy: policy, signature: signature}) do
     %{stem: stem,
       host: host,
       credential: credential,
       date: date,
       policy: policy,
       signature: signature}
  end

  def render("etag.json", %{tag: tag}) do
      %{ETag: tag}
  end

end
