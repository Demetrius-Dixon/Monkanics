**The name's Demetrius Dixon. I'm the creator of the PvP arena shooter, Monkanics.**

I wanted to give out this quick tip for any shooter game developer (Or Monkanics contributors) looking for a way to convert their weapon fire rate to RPM (Rounds Per Minute), instead of Seconds Per Round (SPR) ***within the actual codebase itself***.

For context, RPM is the standard unit of measurement for most shooter game fire rates. As it gives a large, readable number instead of a really small decimal *(i.e. 0.00032 SPR)*. Seconds Per Round is also really cumbersome to work with in my opinion.

But the solution and formula are actually really simple to implement.

---

To calculate RPM (Rounds Per Minute), use the following formula:

```
60 / Your_Desired_RPM
```
For example, if I wanted a fire rate of **500 RPM**, you can save a fire rate variable like this:

```
var Fire_Rate = 60 / 500

await get_tree().create_timer(Fire_Rate).timeout
```
This equals to `0.12` Seconds Per Round, but it's in a much more readable format for the developer.

If you wanted a crazy fire rate like 10,000 RPM in SPR, you'd have to type `0.006`.

That sounds pretty simple, but making changes is very inefficient. As unless you're a math prodigy, you'll have to use a calculator **EVERY SINGLE TIME** you want to make a change to a fire rate value, no matter how big or small.

So if you wanted to update `0.006` fire rate to be faster, you have to subtract `0.001` or `0.0005`. Decreasing the fire rate? Add `0.00001` or `0.002`. It's backwards!

You get the picture! the logic is very unintuitive and is a hassle to maintain. RPM is simply easier to develop day-to-day.

---

**But there's an even better way to calculate RPM!**

Simply create your own formula function that returns your fire rate like so:
```
func calculate_fire_rate_delay(Rounds_Per_Minute) -> float:
	
	# Formula for calculating RPM for easy fire rate implementation
	return 60 / Rounds_Per_Minute
```
Then, put this into your fire rate delay timer like so (The example I'm using is **500 RPM**):

```
await get_tree().create_timer(calculate_fire_rate_delay(500)).timeout
```
You can change that float value all you like, then Godot will handle the all the annoying decimal math for you. *Work smarter, not harder.*

---

For those of you who prefer Rounds Per Second (RPS), the formula is the following:

```
1.0 / Your_Desired_RPS
```
```
func calculate_fire_rate_delay(Rounds_Per_Second) -> float:
	
	# Formula for calculating RPS for easy fire rate implementation
	return 1.0 / Rounds_Per_Second
```
```
await get_tree().create_timer(calculate_fire_rate_delay(10)).timeout
```
This was for **10 rounds per second**. Which equates to 60 RPM.

I still find RPS annoying to work with, so I stick with RPM.

---

I hope this small guide helps a least 1 fellow Google searcher, game developer, or Monkanics contributor with implementing fire rates easier.

Also, you can just use the `math_formulas` global script to do it for you. That's a lot easier.

**-- Demetrius Dixon**