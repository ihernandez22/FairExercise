module ApplicationHelper
  
  def error_message(resource)
    error_message = "There seems to have been a problem creating the #{resource.class.to_s.underscore.humanize.titlecase}. See below for details:\r\n\r\n"
    count = 0
    resource.errors.messages.each do |k,v|
      v.each do |e|
        count += 1
        error_message += "\r\n(#{count}) #{k.to_s.underscore.humanize.titlecase}: #{e}."
      end
    end
    escape_javascript error_message
  end
end
