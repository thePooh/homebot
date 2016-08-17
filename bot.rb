require 'byebug'

require 'open3'
require 'telegram/bot'

TOKEN = ENV["TOKEN"]
allowed_usernames = ['cybPooh', 'sweetChaotic']

def say bot, message, text
  bot.api.send_message(
    chat_id: message.chat.id,
    text: text,
    # disable_web_page_preview: true,
    parse_mode: 'Markdown',
  )
end

def reply bot, message, text
  bot.api.send_message(
    chat_id: message.chat.id,
    text: text,
    disable_web_page_preview: true,
    reply_to_message_id: message.message_id
  )
end

puts "Starting bot..."
Telegram::Bot::Client.run(TOKEN) do |bot|
  bot.listen do |message|
    unless allowed_usernames.include? message.from.username
      from = message.from
      puts "Unauthorized access: #{from.id}, #{from.username}, #{from.first_name} #{from.last_name}"
      bot.api.send_message(chat_id: message.chat.id, text: "Sorry, my parents do not allow me to talk to strangers.")
    else
      text = message.text
      if text =~ /https?:\/\/.*/
        output, status = Open3.capture2e("curl #{text} --head")
        /^Location:.*\/([^\/\s]*)/.match(output) do |match|
          filename = match[1].gsub(/_/, '-')
          is_series = filename =~ /\d\d.+\d\d/
          folder = is_series ? 'Series' : 'Movies'
          say(bot, message, "Downloading _#{filename}_ to #{folder}")
          Thread.new do
            prefix = "~/#{folder}/"
            output, status = Open3.capture2e("wget --content-disposition #{text} -P #{prefix} -nv")
            reply(bot, message, "#{filename} is downloaded\n\n#{output}")
          end
        end
      else
        bot.api.send_message(chat_id: message.chat.id, text: "Sorry, I did not get it")
      end
    end
  end
end
puts "Bot ended his current life"
