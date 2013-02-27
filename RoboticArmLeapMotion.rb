################################################################################
# Copyright (C) 2012 Leap Motion, Inc. All rights reserved.                    #
# NOTICE: This developer release of Leap Motion, Inc. software is confidential #
# and intended for very limited distribution. Parties using this software must #
# accept the SDK Agreement prior to obtaining this software and related tools. #
# This software is subject to copyright.                                       #
################################################################################

# NOTE: this is a version of the Leap Sample.* files in JRuby
#C:\jruby-1.7.2\bin\jruby -J-classpath "Leap_SDK/lib/LeapJava.jar" -J-Djava.library.path=Leap_SDK/lib/x86 RubyLeapMouse.rb

if RUBY_PLATFORM != "java"
	raise "Run this script with JRuby: http://jruby.org/getting-started"
end

require 'socket'
require 'LeapJava.jar'

java_import java.lang.Math;
java_import com.leapmotion.leap.Listener
java_import com.leapmotion.leap.Controller
java_import com.leapmotion.leap.Vector
java_import java.awt.Robot
java_import java.awt.Toolkit
java_import java.awt.Dimension
java_import java.awt.event.InputEvent
java_import java.awt.event.KeyEvent

class SampleListener < Listener
	attr_reader :hands
	def onInit(controller)
		puts "Initialized"
		@hands = []
	end

	def onConnect(controller)
		puts "Connected to the Leap"
	end

	def onDisconnect(controller)
		puts "Disconnected from the Leap"
	end

	def onExit(controller)
		puts "Exiting"
	end

	def onFrame(controller)
		frame = controller.frame
    @hands = frame.hands
	end
end

class RobotArmLeapMotion
	def initialize
		@listener = SampleListener.new
		@controller = Controller.new
		@controller.addListener @listener
		@centerX = nil
		@centerY = nil
		@handClosedCounterMax = 20
		@handClosedCounter = (@handClosedCounterMax) / 2
		@noHandCounter = 0
	end

	def scale(num)
		maxX = 100
		num = num.to_i
		return 0 if num == 0
		sign = num.abs / num
		num = num.abs
		thresh = 10
		if num > thresh
			num -= thresh
			num = num.to_f
			num *= (100.0 / maxX.to_f)
			num = num.round
			num = 100 if num > 100
			return num * sign
		else
			return 0
		end
	end

	def getLatest
		hands = @listener.hands
		half = @handClosedCounterMax / 2
		handClosed = true
		handClosed = false if @handClosedCounter < half
		xPow = nil
		yPow = nil

		if hand = hands.first
			@noHandCounter = 0
			r = hand.sphereRadius
			if r > 70
				@handClosedCounter -= 1 if @handClosedCounter > 0
			else
				@handClosedCounter += 1 if @handClosedCounter < @handClosedCounterMax
			end
			pos = hand.palmPosition
			if @centerX.nil? || @centerY.nil?
				@centerX = 0#pos.x
				@centerY = pos.y
			else
				xDif = pos.x - @centerX
				yDif = pos.y - @centerY
				xPow = scale(xDif)
				yPow = scale(yDif)
			end
		else
			@noHandCounter += 1
			if @noHandCounter >= 500
				@centerX = nil
				@centerY = nil
			end
		end
		if !xPow.nil? && !yPow.nil?
			tf = "0"
			tf = "1" if handClosed
			data = [tf, xPow, yPow]
			data = data.join(':')
			return data
		else
			return nil
		end
	end
end

robotArmLeapMotion = RobotArmLeapMotion.new

puts "Creating Server..."
ip = '172.22.5.113'
ip = 'localhost'
server = TCPServer.open(8081)
puts "Done"
$clients = []
Thread.new do
	while true
		client = server.accept
		puts "Connected"
		$clients << client
		puts "Robot total: #{$clients.length}"
	end
end

puts "Waiting for connection..."
while $clients.length == 0
end
puts "Beginning information transfer..."

reason = while true
	data = robotArmLeapMotion.getLatest
	if !data.nil?
		closed = nil
		for i in 0...$clients.length
			client = $clients[i]
			client.syswrite(data + "\n")
			client.gets
		end
		$clients.delete_at(closed) if !closed.nil?
		puts data if $clients.length > 0
	end
end

puts reason
client.close