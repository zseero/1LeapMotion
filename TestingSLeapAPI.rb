require 'SLeapAPI'

while true
	hands = getHands
	hand = hands[0]
	if !hand.nil?
		fingers = hand.getFingers
		finger = fingers[0]
		if !finger.nil?
			pos = finger.tipPosition
			puts "x:#{pos.x} y:#{pos.y}, z:#{pos.z}"
		end
	end
end