extends RigidBody2D

var initial_player_position

# Max speed of the player (pixels/sec)
export var speed = 400

# The direction the player wants to jump in
var desired_jump_direction = false

# The joint holding the player to something
var player_holding_joint = false

# The max crawl speed (ie. if the player is crawling on a wall)
var max_abs_crawl_speed = 100

# The current crawl speed
var current_crawl_speed = 0

# Called when the node enters the scene tree for the first time.
func _ready():
    initial_player_position = position

    $LaserPointer.laser_ignore.append(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    # Perform a jump if one is set
    if desired_jump_direction:
        linear_velocity = desired_jump_direction.normalized() * speed
        angular_velocity = 0
        if linear_velocity.x < 0:
            rotation = linear_velocity.angle() + PI
        else:
            rotation = fmod(linear_velocity.angle(), PI)
        desired_jump_direction = false
        
    # Crawl if we're on a wall 
    if player_holding_joint and abs(current_crawl_speed) > 0:
        # We need to remove the joint to update the position
        var joint_player_path = player_holding_joint.node_a
        player_holding_joint.node_a = ""
        var wall_to_crawl_along = player_holding_joint.get_node(player_holding_joint.node_b)
        var wall_rotation = wall_to_crawl_along.rotation
        var position_update_vector = Vector2(cos(wall_rotation), sin(wall_rotation))
        position += position_update_vector.normalized() * current_crawl_speed * delta
        player_holding_joint.node_a = joint_player_path
        
    # Determine sprite to draw
    if linear_velocity.x < 0:
        $Sprite.frame = 9
    else:
        $Sprite.frame = 8
    
# This is called on mouse/keyboard events
func _input(event):
    if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
        # If we're on a wall, remove the joint holding us there and jump!
        if player_holding_joint:
            player_holding_joint.free()
            player_holding_joint = false
            # Let the player jump in the direction of the click
        # TODO: indent this line by 1
        desired_jump_direction = get_global_mouse_position() - position
        
    # Handle crawling if we're on a wall
    if player_holding_joint:
        if Input.is_action_pressed("ui_up"):
            current_crawl_speed = max_abs_crawl_speed
        elif Input.is_action_pressed("ui_down"):
            current_crawl_speed = -max_abs_crawl_speed
        else:
            current_crawl_speed = 0
    else:
        current_crawl_speed = 0
        
        
func _integrate_forces(state): 
    for i in range(get_colliding_bodies().size()):
        var collision_position = state.get_contact_local_position(i)
        var colliding_body = get_colliding_bodies()[i]
        
        if colliding_body is Ladder && !player_holding_joint:
            player_holding_joint = PinJoint2D.new()
            player_holding_joint.disable_collision = false
            player_holding_joint.position = position
            player_holding_joint.set_name("player_holding_joint")
            player_holding_joint.softness = 0
            player_holding_joint.set_node_a("../" + get_parent().get_path_to(self))
            player_holding_joint.set_node_b("../" + get_parent().get_path_to(colliding_body))
            get_parent().call_deferred("add_child", player_holding_joint)

func _on_kill_player():
    position = initial_player_position
    linear_velocity = Vector2()
    angular_velocity = 0
    rotation = 0
    desired_jump_direction = false
