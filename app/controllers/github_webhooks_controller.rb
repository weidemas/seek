class GithubWebhooksController < ActionController::Base
  include GithubWebhook::Processor

  def github_delete(payload)
    pp "##### DELETE #####"
    pp payload.inspect
  end

  def github_create(payload)
    pp "##### CREATE #####"
    pp payload.inspect
  end

  def github_release(payload)
    pp "##### RELEASE #####"
    pp payload.inspect
  end


  def github_tag(payload)
    pp "##### TAG #####"
    pp payload.inspect
  end

  private

  def webhook_secret(payload)
    'wibble'
  end
end