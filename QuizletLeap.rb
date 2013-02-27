################################################################################
# Copyright (C) 2012 Leap Motion, Inc. All rights reserved.                    #
# NOTICE: This developer release of Leap Motion, Inc. software is confidential #
# and intended for very limited distribution. Parties using this software must #
# accept the SDK Agreement prior to obtaining this software and related tools. #
# This software is subject to copyright.                                       #
################################################################################

# NOTE: this is a version of the Leap Sample.* files in JRuby
#C:\jruby-1.7.2\bin\jruby -J-classpath "Leap_SDK/lib/LeapJava.jar" -J-Djava.library.path=Leap_SDK/lib/x86 QuizletLeap.rb

if RUBY_PLATFORM != "java"
	raise "Run this script with JRuby: http://jruby.org/getting-started"
end

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
		puts "Connected"
	end

	def onDisconnect(controller)
		puts "Disconnected"
	end

	def onExit(controller)
		puts "Exiting"
	end

	def onFrame(controller)
		frame = controller.frame
    @hands = frame.hands
	end
end

listener = SampleListener.new
controller = Controller.new
controller.addListener listener
robot = Robot.new
canControl = true
while true
	hands = listener.hands
	if hands.to_a.length == 2
		controller.removeListener listener
		exit
	end
	if hand = hands.first
		vel = hand.palmVelocity
		thresh = 500
		fbool = (vel.y > thresh)
		rbool = (vel.x > thresh)
		lbool = (vel.x < thresh * -1)
		if canControl && vel.z < 0
			if fbool || rbool || lbool
				puts vel.x.round
				canControl = false
			end
			if fbool
				robot.keyPress(KeyEvent::VK_DOWN)
				robot.keyRelease(KeyEvent::VK_DOWN)
			elsif rbool
				robot.keyPress(KeyEvent::VK_RIGHT)
				robot.keyRelease(KeyEvent::VK_RIGHT)
			elsif lbool
				robot.keyPress(KeyEvent::VK_LEFT)
				robot.keyRelease(KeyEvent::VK_LEFT)
			end
		end
		#if vel.x.abs < 100 && vel.y.abs < 100
		#	canControl = true
		#end
	else
		canControl = true
	end
end