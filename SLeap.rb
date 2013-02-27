filename = ARGV[0]
boolWait = false
if filename.nil?
	printf "Filename: "
	filename = gets.chomp
	boolWait = true
end
system("jruby -J-classpath LeapSDK/lib/LeapJava.jar -J-Djava.library.path=LeapSDK/lib/x86 #{filename}")
puts "Program has ended"
while boolWait
end