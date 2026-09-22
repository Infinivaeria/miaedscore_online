require 'roda'

class MyRodaApp < Roda
  route do |r|
    r.root { "Hello from Roda!" }
  end
end
