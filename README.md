# KBEngine Godot Demo

KBE godot demo

## Plugin & Demo explanation:

	Plug-in: Responsible for the handling of the network, establishing 
	connection to the server, and sending/receiving binary data through 
	TCP packets. Handles login/logout process. Creates/destroys entities
	upon notification from the server, synchronizes their attributes,
	and allows for calling methods on equivalent base/cell entities on
	the server and allows the server to call methods on client entities.
	Provides an Event class for asynchronous communication with the
	plugin and KBE entities across multiple threads. Resides in the
	kbe_plugin directory, and has KBEngine.gd set as a Singleton in 
	Godot project settings.
	
	Godot demo: Responsible for handling the rendering and user 
	interaction layer. Defines entity client parts in the kbe_scripts 
	directory (or its subdirectories), which is where the plugin looks
	when creating entities via the servers command. __init__() and 
	onDestroy() are called for notifications about entities' lifecycles.
	When defining client entities, events are registered with the 
	KBEngine.Event Singleton class in __init__(), and fired out from
	entity methods to be received by the render layer.
	
	Directory structure:
	kbe_plugin/: KBE plugin script files, KBEngine.gd set as Singleton
	kbe_scripts/: Contains all client entity definitions. Place all yours here
	kbe_scripts/Account.gd: Account client entity definition. Created on login
	kbe_scripts/Account.gd: Avatar client entity definition.
	kbe_scripts/Monster.gd: Monster client entity definition.
	kbe_scripts/GameObject.gd: GameObject interface, fires events on property change
	
	UI.gd: UI script, catches events thrown by kbe_scripts and built-in 
		protocol events to display login success/fail notifications, 
		allow avatar creation/selection
	World.gd: Manages 3D world, catches events and creates and destroys
		rendering objects(mesh etc) for each kbe_script entity
	GameEntity.gd: Attached to rendering objects and handles movement, 
		HP/name labels above 3D characters, etc

## Screenshots

![alt text](https://raw.githubusercontent.com/krogank9/kbe_godot_demo/master/screenshot1.png)
![alt text](https://raw.githubusercontent.com/krogank9/kbe_godot_demo/master/screenshot2.png)
![alt text](https://raw.githubusercontent.com/krogank9/kbe_godot_demo/master/screenshot3.png)
![alt text](https://raw.githubusercontent.com/krogank9/kbe_godot_demo/master/screenshot4.png)
