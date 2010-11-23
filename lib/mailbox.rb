class Mailbox < ActiveRecord::Base
  has_many :messages

  def self.create_from_gmail
    found = []
    $gmail.mailboxes.
      select {|box| !box.attr.include?(:Noselect)}.
      each_with_index do |box, index|
        mailbox = Mailbox.find_or_create_by_label box.name
        mailbox.update_attribute :position, index
        found << mailbox
      end
    found.each {|m| puts "- #{m.label}"}
    (Mailbox.all - found).each do |mailbox|
      puts "Destroying #{mailbox.label}"
      mailbox.destroy
    end
  end

  def update_from_gmail(opts = {})
    opts = {:mailbox => self.label, :query => ["ALL"], :num_messages => 10}.update(opts)

    $gmail.fetch(opts) do |imap, uid|
      begin
        message = self.messages.find_by_uid(uid)
        if message.nil?
          email = imap.uid_fetch(uid, "RFC822")[0].attr["RFC822"]
          mail = Mail.new(email)
          from = mail.from[0]
          message = self.messages.create!(:uid => uid, 
                                    :sender => from,
                                    :subject => mail[:subject],
                                    :date => mail.date,
                                    :eml => mail.to_s)
          message.cache_text
          puts "#{self.label}: #{message.uid} #{message.date.to_s} #{message.sender} #{message.subject.to_s[0,20]}"
        end
      rescue
        puts "ERROR"
        puts "Raw email from #{from}"
        puts $!
      end

    end
    puts "#{self.label}: Done update"
  end

  def label_message(message_uid, gmail_label)
    $gmail.mailbox(self.label) do |imap|
      begin
        imap.uid_copy(message_uid, gmail_label)
      rescue Net::IMAP::NoResponseError
        raise "No label `#{label}' exists!"
      end
    end
  end
end


