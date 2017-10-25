module Lita
  module Handlers
    class Didyoumean < Handler

			on :unhandled_message, :chat

      def should_reply?(message)
        message.command? || message.body =~ /#{aliases.join('|')}/i
      end

      def aliases
        [robot.mention_name, robot.alias].map{|a| a unless a == ''}.compact
      end

      def chat(payload)
        message = payload[:message]
        return unless should_reply?(message)
        robot.send_message(message.source, build_response(message))
      end

      def build_response(message)
        # Get Command
        raw_command = message.body.split(" ")[0,2]
        sent_command = raw_command.join(" ")
        reverse_command = raw_command.reverse.join(" ")
        commands = all_commands
        p reverse_command
        # Calculate levenshtein against first two commands
        results = commands.map { |c| [c, levenshtein_distance(sent_command, c)] }
        # Calculate levenshtein against first two commands reversed (to help deploy/deploy help)
        if raw_command.length == 2
          results += commands.map { |c| [c, levenshtein_distance(reverse_command, c)] }
        end
        # Sort by lowest levenshtein
        p results
        results = results.sort_by { |r| r[1] }.take(5)

        reply = <<~EOF
        I did not understand `#{sent_command}`
        Did you mean:
        EOF
        results.each { |r| reply += "- #{r[0]}\n" }

        reply
      end

			def all_commands
        commands = []
        Lita.handlers.each do |h|
          if h.respond_to?(:routes) && !h.routes.nil?
            commands << h.routes.map { |r| r.help.keys[0].split(" ")[0,2].join(" ") }
          end
        end
        commands.flatten.uniq
      end


      # StackOverflow'd
			def levenshtein_distance(s, t)
				m = s.length
				n = t.length
				return m if n == 0
				return n if m == 0
				d = Array.new(m+1) {Array.new(n+1)}

				(0..m).each {|i| d[i][0] = i}
				(0..n).each {|j| d[0][j] = j}
				(1..n).each do |j|
					(1..m).each do |i|
						d[i][j] = if s[i-1] == t[j-1]  # adjust index into string
												d[i-1][j-1]       # no operation required
											else
												[ d[i-1][j]+1,    # deletion
													d[i][j-1]+1,    # insertion
													d[i-1][j-1]+1,  # substitution
												].min
											end
					end
				end
				d[m][n]
			end

      Lita.register_handler(self)
    end
  end
end
