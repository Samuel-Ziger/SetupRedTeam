module Intrigue
module Ident
module FtpCheck
class Base

  include Intrigue::Ident::BannerHelpers

  def self.inherited(base)
    Intrigue::Ident::Ftp::CheckFactory.register(base)
  end

end
end
end
end
