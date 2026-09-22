
puts 'Updating HUD...'
puts `ruby update_version.rb`
`kill -9 $(ps aux | grep puma | awk '{print $2}')`
exec('puma -C config/puma-nginx-production-hud.rb &')
puts 'Puma server restarted.'
