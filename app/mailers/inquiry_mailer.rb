class InquiryMailer < ApplicationMailer
  def send_mail(inquiry)
    @inquiry = inquiry
    mail(
      from: 'try.rhtme.ddr@gmail.com',
      to:   'try.rhtme.ddr@gmail.com',
      subject: '<SkateSpotSearch>利用者様から、お問い合わせ通知'
    )
  end
end
