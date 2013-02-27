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

class RubyLeapMouse
	def initialize
		@listener = SampleListener.new
		@controller = Controller.new
		@controller.addListener @listener

		@robot = Robot.new
		@toolkit = Toolkit.getDefaultToolkit

		@notPressed = true
		@not2Fingers = true
		@gesture1debounce = 0
		@gesture2debounce = 0

		@arySize = 99
		@xAry = []
		@yAry = []
		@x = 0
		@y = 0
		
		@mousePress = false
	end

	def main
		hands = @listener.hands

		#MOUSE CONTROL
		mouseMoved = false
		if hand = hands.first
			if fingers = hand.fingers
				if finger = getMost(:right, fingers.to_a, :finger)
					#main mouse control
					mainMouseControl(finger)
					mouseMoved = true
					if fingers.to_a.length >= 2 && thumb = getMost(:left, fingers.to_a, :finger)
						#click detect
						clickDetect(finger, thumb)
					end
				end
			end
		end
		if !mouseMoved
			(@xAry.length - 1).times {@xAry.delete_at(0)}
			(@yAry.length - 1).times {@yAry.delete_at(0)}
		end
	
		#GESTURE DETECTION
		if hands.to_a.length > 1
			hand = getMost(:left, hands.to_a, :hand)
			amt = hand.fingers.count
	
			#click and hold
			thresh = 100
			if amt == 1
				@gesture1debounce += 1 if @gesture1debounce < thresh
			else
				@gesture1debounce -= 1 if @gesture1debounce > 0
			end
			if @gesture1debounce >= thresh / 2
				puts "Holding click..."
				@mousePress = true
				@robot.mousePress(InputEvent::BUTTON1_MASK)
			else
				@mousePress = false
				@robot.mouseRelease(InputEvent::BUTTON1_MASK)
			end
	
			#undo
			thresh = 40
			if amt == 2
				@gesture2debounce += 1 if @gesture2debounce < thresh
			else
				@gesture2debounce -= 1 if @gesture2debounce > 0
			end
			bool = (@gesture2debounce >= thresh / 2)
			if bool && @not2Fingers
				puts "Undo"
				@robot.keyPress(KeyEvent::VK_CONTROL)
				@robot.keyPress(KeyEvent::VK_Z)
				@robot.keyRelease(KeyEvent::VK_Z)
				@robot.keyRelease(KeyEvent::VK_CONTROL)
				@not2Fingers = false
			end
			if !bool
				@not2Fingers = true
			end
	
			#exit
			if amt >= 4
				@controller.removeListener @listener
				exit
			end
		else
			if @mousePress
				@mousePress = false
				@robot.mouseRelease(InputEvent::BUTTON1_MASK)
			end
		end
	end

	def getMost(dir, list, handFinger)
		most = nil
		if list.length > 1
			for obj in list
				left = false
				right = false
				if !most.nil?
					if handFinger == :finger
						left = (dir == :left && obj.tipPosition.x < most.tipPosition.x)
						right = (dir == :right && obj.tipPosition.x > most.tipPosition.x)
					elsif handFinger == :hand
						left = (dir == :left && obj.palmPosition.x < most.palmPosition.x)
						right = (dir == :right && obj.palmPosition.x > most.palmPosition.x)
					end
				end
				bool = (left || right)
				most = obj if bool || most.nil?
			end
			most
		elsif list.length == 1
			list.first
		else
			nil
		end
	end
	
	def toScreen(v, s)
		screenX = v.x * s.widthPixels
		screenY = s.heightPixels - v.y * s.heightPixels
		Vector.new(screenX, screenY, 0)
	end
	
	def mainMouseControl(finger)
		screens = []
		for screen in @controller.calibratedScreens
			screens << screen
		end
		screen = screens[1]
		screen = screens[0] if screen.nil?
		intersect = screen.intersect(finger, true)
		screenPos = toScreen(intersect, screen)
		@xAry << screenPos.x
		@yAry << screenPos.y
		@xAry.delete_at(0) if @xAry.length > @arySize
		@yAry.delete_at(0) if @yAry.length > @arySize
		xSum = 0
		@xAry.each {|x| xSum += x}
		ySum = 0
		@yAry.each {|y| ySum += y}
		xAvg = xSum / @xAry.length
		yAvg = ySum / @yAry.length
		@robot.mouseMove(xAvg, yAvg)
	end
	
	def alternateMouseControl(finger)
		size = @toolkit.getScreenSize
		oldx = @x
		oldy = @y
		@x += finger.direction.x
		@y += (finger.direction.y * -1)
		@x = oldx if @x < 0 || @x > size.width
		@y = oldy if @y < 0 || @y > size.height
		@robot.mouseMove(@x.round, @y.round)
	end
	
	def clickDetect(finger, thumb)
		thumbVel = thumb.tipVelocity.x
		fingerVel = finger.tipVelocity.x
		comparison = 30
		comparison += (fingerVel + 30) if fingerVel > 0
		bool = (thumbVel > comparison)
		if bool && @notPressed
			puts "Click! thumbVel: #{thumbVel.round}, fingerVel: #{fingerVel.round}"
			if !@mousePress
				@robot.mousePress(InputEvent::BUTTON1_MASK)
				@robot.mouseRelease(InputEvent::BUTTON1_MASK)
			end
			@notPressed = false
		end
		if !bool
			@notPressed = true
		end
	end
end

rubyLeapMouse = RubyLeapMouse.new

while true
	rubyLeapMouse.main
end