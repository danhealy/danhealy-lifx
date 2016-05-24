require 'bundler'
Bundler.require

include Colorable

# By default Colorable uses saturation and brightness values in a range 0-100
# Lightsd requires a float 0.0 - 1.0
# Not really necessary in the following code since I've hard coded saturation
# and brightness values
class Color
  def hsb
    h, s, b = _hsb.to_a
    return h, s / 100.0, b / 100.0
  end
end

$client = RJR::Nodes::Unix.new(node_id: "client")

# You may need to override this path:
$s = "/usr/local/var/run/lightsd/socket"

# Saturation and brightness for all random colors are hard coded
# Saturation value of 0.35 is pretty nice also, I don't recommend changing the
# others
$saturation = 1.0
$brightness = 1.0
$kelvin = 3500

def _call(*params)
  $client.invoke($s, *params)
end

# Ensure we stay within the 0..359 range
def wrap_hue(angle)
  h = angle.to_i
  h = h + 360 if h < 0
  h = h - 360 if h > 359
  return h
end

# Create a random value somewhere within +/- the variance from the starting hue
def vary_hue(hue, variance)
  return wrap_hue(hue - variance + 2*rand(variance))
end

# Debug command to print light info
def get_light_state(target = "*")
  x = _call "get_light_state", target
  ap x
end

# Sets the color of a specific target.  Target "*" to apply to all.
def set_light(target = "*", h = 1.0, duration = 2)
  puts "#{target} -> #{h} in #{duration}"
  _call "set_light_from_hsbk", target, h, $saturation, $brightness, $kelvin, (duration*1000).round
end

# Unused waveform example
def set_waveform(target = "*", waveform = :saw, hue, duration, speed)
  _call "set_waveform", target, waveform, hue, $saturation, $brightness, $kelvin, duration, speed, 0.5, true
end

# The following methods are specific to my light configuration

# Method to change the color of my three lights in my tree lamp
# Basically it spreads the hue value passed in across the "internal_variance"
# value, and it can give them slightly different blend times
def set_tree(hue, duration, sleepy = 0.0, variance = 10)
  # These must be the exact light labels
  labels = ["Tree Short", "Tree Mid", "Tree Long"]
  h = wrap_hue(hue - variance)
  labels = labels.reverse if [true, false].sample
  slippy = 0
  labels.each do |label|
    set_light(label, h, duration - (2*sleepy) + slippy)
    h = wrap_hue(h + variance)
    slippy = slippy + sleepy
  end
end

# I have 6 lights, two in a bedroom, one in a regular lamp, and three in
# a tree lamp.  I choose to set the "UFO" regular lamp to the current step hue
# without any variance.  The two nightstands are set directly with variance,
# and the tree lamp is set with the special set_tree method above
# Change this to fit your configuration
def set_all(hue, duration, sleepy, variance)
  puts "set_all to #{hue} (#{duration}, #{sleepy}, #{variance})"
  set_light("UFO", hue, ((4*duration) / 5.0)) # Get there a little faster
  ["NightstandL", "NightstandR"].each do |label|
    set_light(label, vary_hue(hue, variance), duration)
  end
  # Use half the internal_variance range for the tree lamp:
  set_tree(vary_hue(hue, variance), duration, sleepy, (variance / 2.0).round)
end

# Print out all light info to start
get_light_state

################################################################################
# Now you can set colors directly:
#
# color = Color.new 'red'
# set_light("UFO", color.hue)

# Uncomment the next line to play with the above code in the pry REPL:
# binding.pry

################################################################################
# The following is my color blending routine
#
# Pick a random base hue to begin with
hue = rand(360)

# The base hue will increment or decrement by this amount in degrees every step
step_variance = 15

# At each step, the maximum hue distance between bulbs will vary by this amount
internal_variance = 25

# How long, in seconds, it takes for colors to blend to the new value
duration = 10

# For the 3 bulb tree lamp, how much time passes between each bulb finishing its
# blend.  For example if this value is 2, and duration is 10, the first bulb
# will finish blending in 6 seconds, the second in 8 seconds and the last in 10
sleepy = 0

# How long it waits after reaching the new values before the next step
waiting = 2

# Start by incrementing (instead of decrementing) hue values on each step
direction = 1

# Runs until the process is terminated
loop do
  set_all(hue, duration, sleepy, internal_variance)
  puts "-"*20
  sleep duration+(2*sleepy)+waiting

  # For fun, random chance we start decrementing hue values on each step instead
  if rand(10) == 9
    puts "Changing direction"
    direction = direction * -1
  end

  hue = wrap_hue(hue + direction*step_variance)
end
