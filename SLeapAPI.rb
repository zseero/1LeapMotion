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

require 'LeapSDK/lib/LeapJava.jar'

java_import com.leapmotion.leap.Listener
java_import com.leapmotion.leap.Controller
java_import com.leapmotion.leap.Vector
java_import com.leapmotion.leap.Hand
java_import com.leapmotion.leap.Finger
java_import com.leapmotion.leap.Pointable

class SListener < Listener
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

class Hand
	def getFingers
		fingers.to_a
	end

	def getPointables
		pointables.to_a
	end
end

class Array
	def getFarthest(dir)
		most = nil
		each do |obj|
			left = false
			right = false
			if !most.nil?
				if obj.is_a?(Pointable)
					left = (dir == :left && obj.tipPosition.x < most.tipPosition.x)
					right = (dir == :right && obj.tipPosition.x > most.tipPosition.x)
				elsif obj.is_a?(Hand)
					left = (dir == :left && obj.palmPosition.x < most.palmPosition.x)
					right = (dir == :right && obj.palmPosition.x > most.palmPosition.x)
				else
					raise "Must be an array of Hands, or Pointables"
				end
			end
			bool = (left || right)
			most = obj if bool || most.nil?
		end
		most
	end
end

@listener = SListener.new
@controller = Controller.new
@controller.addListener @listener

def getHands
	hands = @listener.hands.to_a
end