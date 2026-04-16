puts "Seeding users..."

[
  { email: "admin@cairn.test",  password: "password", role: :admin  },
  { email: "editor@cairn.test", password: "password", role: :editor },
  { email: "author@cairn.test", password: "password", role: :author }
].each do |attrs|
  user = User.find_or_initialize_by(email: attrs[:email])
  user.assign_attributes(
    password:              attrs[:password],
    password_confirmation: attrs[:password],
    role:                  attrs[:role]
  )
  user.save! if user.new_record? || user.changed?
  puts "  #{user.role}: #{user.email}"
end

puts "Seeds complete."
