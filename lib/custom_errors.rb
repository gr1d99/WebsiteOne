module CustomErrors

  def self.included(base)
    base.rescue_from Exception, with: ->(exception) { render_error 500, exception }

    base.rescue_from ActionController::RoutingError,
                     ActionController::UnknownController,
                     AbstractController::ActionNotFound,
                     ActiveRecord::RecordNotFound,
                     #Sampriti: It will be be too complex to handle missing templates on every action.
                     ActionView::MissingTemplate,
                     with: ->(exception) { render_error 404, exception }
  end

  private

  # PRIVATE
  def render_error(status, error)
    raise error unless Rails.env.production?

    Rails.logger.error error.message
    error.backtrace.each_with_index { |line, index| Rails.logger.error line; break if index >= 5 }

    unless [ 404 ].include? status
      ExceptionNotifier.notify_exception(error, env: request.env, :data => { message: 'was doing something wrong' })
    end

    case status
      when 404
        render template: 'static_pages/not_found', layout: 'layouts/application', status: 404

      when 500
        render template: 'static_pages/internal_error', layout: 'layouts/application', status: 500

      else
        render template: 'static_pages/internal_error', layout: 'layouts/application', status: 500
    end
  end
end
