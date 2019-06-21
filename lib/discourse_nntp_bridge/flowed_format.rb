# frozen_string_literal: true

# Decodes and encodes Mail::Message objects from or into the "flowed format"
# specified in RFC3676 (though without support for the "DelSp" parameter)

module DiscourseNntpBridge
  module FlowedFormat
    # TODO: This does not actually perform a message-object-to-message-object
    # decoding, it instead returns a string that is the decoded message body,
    # whether or not it was flowed. Implementing the former is blocked on this:
    # https://github.com/mikel/mail/issues/793
    def self.decode_message(message)
      if message.content_type_parameters.to_h['format'] == 'flowed'
        new_body_lines = []
        message.decoded.each_line do |line|
          line.chomp!
          quotes = line[/^>+/]
          line.sub!(/^>+/, '')
          line.sub!(/^ /, '')
          if (line != '-- ') &&
             !new_body_lines.empty? &&
             !new_body_lines[-1][/^-- $/] &&
             new_body_lines[-1][/ $/] &&
             (quotes == new_body_lines[-1][/^>+/])
            new_body_lines[-1] << line
          else
            new_body_lines << quotes.to_s + line
          end
        end

        new_body_lines.join("\n")
      else
        message.decoded
      end
    end

    def self.encode_message(message)
      if (!message.has_content_type? || message.content_type == 'text/plain') &&
         message.content_type_parameters.to_h['format'] != 'flowed'
        message = message.dup
        message.content_type ||= 'text/plain'
        message.content_type_parameters[:format] = 'flowed'

        message.body = message.body.to_s.split("\n").map do |line|
          line.rstrip!
          quotes = ''
          if line[/^>/]
            quotes = line[/^([> ]*>)/, 1].delete(' ')
            line.gsub!(/^[> ]*>/, '')
          end
          line = ' ' + line if line[/^ /]
          if line.length > 78
            line.gsub(/(.{1,#{72 - quotes.length}}|[^\s]+)(\s+|$)/, "#{quotes}\\1 \n").rstrip
          else
            quotes + line
          end
        end.join("\n")
      end

      message
    end
  end
end
