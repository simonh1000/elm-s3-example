defmodule S3.Signing do
    # use S3.Web, :controller

    use Timex

    @bucket Application.get_env(:s3, :aws_s3_bucket)
    @public_key Application.get_env(:s3, :aws_s3_public_key)
    @private_key Application.get_env(:s3, :aws_s3_secret_key)

    @region "us-east-1"
    @service "s3"
    @aws_request "aws4_request"

    ######### API - Called by UploadController
    def file_stem2(customer_id, group_id, job_id, estimate_id) do
      stem = "cust" <> customer_id <> "/group" <> group_id
      stem = case {job_id, estimate_id} do
          {job_id, nil} ->
              stem <> "/job" <> job_id
          {job_id, estimate_id} ->
              stem <> "/job" <> job_id <> "/est" <> estimate_id
      end
      stem <> "/"
    end

    def credential() do
        credential(@public_key, get_date())
    end

    def get_date() do
      datetime = Timex.now
      {:ok, t} = Timex.format(datetime, "%Y%m%d", :strftime)
      t
    end

    def policy64(stem, host, expiration_window \\ 30) do
        policy(stem, host, expiration_window)
        |> Poison.encode!
        |> Base.encode64
    end

    def signature(stem, host, expiration_window \\ 30) do
        string_to_sign = policy64(stem, host, expiration_window)

        signing_key()
        |> hash_sha256(string_to_sign)
        |> Base.encode16(case: :lower)
    end

    def random_string(length) do
      :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
    end

    ######### API - Called by ThirdPartyView
    def file_stem(%{customer: customer, user: _user, link: link}) do
      stem = "cust" <> Integer.to_string(customer.id) <> "/group" <> Integer.to_string(link.group_id)
      case {link.job_id, link.template_id, link.estimate_id} do
          {job_id, nil, nil} ->        # mailinglist
              stem <> "/job" <> Integer.to_string(job_id)
          {job_id, nil, estimate_id} ->        # artwork
              stem <> "/job" <> Integer.to_string(job_id) <> "/est" <> Integer.to_string(estimate_id)
          {nil, template_id, estimate_id} ->        # artwork for template
              stem <> "/template" <> Integer.to_string(template_id) <> "/est" <> Integer.to_string(estimate_id)
          _ ->        # unknown
              stem
      end
    end

    ####### Helpers

    defp policy(stem, host, _expiration_window) do
      %{"expiration" => now_plus(),
        "conditions" => [
              %{"bucket" => @bucket},
              ["starts-with", "$key", stem],
              %{"x-amz-algorithm" => "AWS4-HMAC-SHA256"},
              %{"x-amz-credential" => credential()},
              %{"x-amz-date" => get_date() <> "T000000Z"},
              %{"success_action_redirect" => host <> "/success"}]}
    end

    defp credential(key, date) do
        key <> "/" <> date <> "/" <> @region <> "/" <> @service <> "/" <> @aws_request
    end

    defp now_plus(minutes \\ 5) do
      secs = :calendar.datetime_to_gregorian_seconds(:calendar.universal_time)
      { {year, month, day}, {hour, min, sec} } =
        :calendar.gregorian_seconds_to_datetime(secs + 60 * minutes)
      to_string(:io_lib.format("~.4.0w-~.2.0w-~.2.0wT~.2.0w:~.2.0w:~.2.0wZ", [year, month, day, hour, min, sec]))
    end

    defp signing_key() do
        signing_key(@private_key, get_date(), @region, @service)
    end

    def signing_key(secret_key, date, region, service) do
        hash_sha256("AWS4" <> secret_key, date)
        |> hash_sha256(region)
        |> hash_sha256(service)
        |> hash_sha256("aws4_request")
    end

    def hash_sha256(secret, msg) do
        :crypto.hmac(:sha256, secret, msg)
    end
end
