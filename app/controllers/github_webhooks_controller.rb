class GithubWebhooksController < ActionController::Base
  include GithubWebhook::Processor

  def github_delete(payload)
    Rails.logger.info("##### DELETE #####  \n#{payload.inspect}")
  end

  def github_create(payload)
    Rails.logger.info("##### CREATE #####  \n#{payload.inspect}")
  end

  def github_release(payload)
    Rails.logger.info("##### RELEASE #####  \n#{payload.inspect}")
  end

  private

  def webhook_secret(payload)
    'wibble'
  end
end