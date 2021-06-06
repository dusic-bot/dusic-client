require "./command"

class Worker
  class CommandCallExecutor
    class DonateCommand < Command
      def execute
        encoded_user = Dusic.alphabet_encode(@command_call.author_id)
        encoded_server = Dusic.alphabet_encode(@command_call.server_id)
        donation_id = "#{encoded_user}_#{encoded_server}"

        donation_status = t("commands.donate.text.no_premium")
        last_donation_data = t("commands.donate.text.no_last_donation")

        if donation = server.last_donation
          last_donation_data = donation.date.to_s("%d.%m.%y")
          donation_status = t("commands.donate.text.server_got_premium") if premium?
        end

        reply(
          t("commands.donate.title"),
          t("commands.donate.text.main", {
            donation_id:        donation_id,
            donation_status:    donation_status,
            last_donation_data: last_donation_data,
          }),
          "success"
        )
      end
    end
  end
end
