class GithubWebhooksController < ActionController::Base
  include GithubWebhook::Processor

  # Handle push event
  def github_release(payload)
    pp payload.inspect
  end

  # Handle create event
  def github_tag(payload)
    pp payload.inspect
  end

  private

  def webhook_secret(payload)
    'wibble'
  end
end