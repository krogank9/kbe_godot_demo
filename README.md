KBEngine Godot demo
=============

## This client-project is written for KBEngine (MMOG server engine)

http://www.kbengine.org


## Start:
	1. Download KBEngine (MMOG server engine):
		Download(KBEngine):
			https://github.com/kbengine/kbengine/releases/latest

		Build(KBEngine):
			http://www.kbengine.org/docs/build.html

		Installation(KBEngine):
			http://www.kbengine.org/docs/installation.html

	2. Use git to get the demo-assets(server):

		In the kbe_godot_demo directory:

		* Git command: git submodule update --init --remote

		* Or use TortoiseGit(menu): TortoiseGit -> Submodule Update:

		* Or manually get the demo-assets(server)

			Download demo-assets(server):
				https://github.com/kbengine/kbengine_demos_assets/releases/latest
				unzip and copy to "kbengine/"  (The root directory server engine, such as $KBE_ROOT)

	3. Copy "kbengine_demos_assets" to "kbengine\" root directory
![demo_configure](http://www.kbengine.org/assets/img/screenshots/demo_copy_kbengine.jpg)


## Start the Servers:

	Ensure that the "kbengine_demos_assets" has been copied to the "kbengine\" directory

	Check the startup status:
		If successful will find log "Components::process(): Found all the components!".
		Otherwise, please search the "ERROR" keyword in logs, according to the error description to try to solve.
		(More: http://www.kbengine.org/docs/startup_shutdown.html)

	Start server:
		Windows:
			kbengine\kbengine_demos_assets\start_server.bat

		Linux:
			kbengine\kbengine_demos_assets\start_server.sh

		(More: http://www.kbengine.org/docs/startup_shutdown.html)


## Start the Client:

	Directly start from Godot editor or executable
	(To build the client： Godot -> Project -> Export Linux/Mac/Windows.)
	

# Plugin & Demo explanation:

### Plug-in:
	
Responsible for the handling of the network, establishing connection to 
the server, and sending/receiving binary data through TCP stream. 
Handles login/logout process. Creates/destroys entities upon
notification from the server, synchronizes their attributes, and allows 
for calling methods on equivalent base/cell entities on the server and 
allows the server to call methods on client entities. Provides an Event 
class for asynchronous communication with the plugin and KBE entities across multiple threads.
All plugin files reside in the kbe_plugin directory, and KBEngine.gd is
set as a Singleton in Godot project settings.

### Godot demo:

Responsible for handling the rendering and user 
interaction layer. Defines entity client parts in the kbe_scripts 
directory (or its subdirectories), which is where the plugin looks
when creating entities via the servers command. `__init__()` and 
`onDestroy()` are called for notifications about entities lifecycles.
When defining client entities, "in" events (render -> plugin) are 
registered using the KBEngine.Event object in `__init__()`, and
fired "out" (plugin -> render) from entity methods to be received by the
render layer. 
	
### Directory structure:

	kbe_plugin/: KBE plugin script files
	kbe_plugin/KBEngine.gd: Set as Singleton which starts/manages plugin
	kbe_plugin/Args.gd: Modify to change KBE client settings
	
	kbe_scripts/: Contains all client entity definitions. Place all yours here
	kbe_scripts/Account.gd: Account client entity definition. Created on login
	kbe_scripts/Avatar.gd: Avatar client entity definition.
	kbe_scripts/Gate.gd: Gate client entity definition.
	kbe_scripts/Monster.gd: Monster client entity definition.
	kbe_scripts/GameObject.gd: GameObject interface, fires events on property change

	UI.gd:
	UI script, catches events thrown "out" by kbe_scripts and built-in 
	protocol events to display login success/fail notifications, allow 
	avatar creation/selection

	World.gd:
	Manages 3D world, catches events and creates and destroys rendering 
	objects(mesh etc) for each kbe_script entity

	GameEntity.gd:
	Attached to rendering objects and handles smooth movement, HP/name 
	labels above 3D characters, etc

# Screenshots

![alt text](https://raw.githubusercontent.com/krogank9/kbe_godot_demo/master/screenshot1.png)
![alt text](https://raw.githubusercontent.com/krogank9/kbe_godot_demo/master/screenshot2.png)
![alt text](https://raw.githubusercontent.com/krogank9/kbe_godot_demo/master/screenshot3.png)
![alt text](https://raw.githubusercontent.com/krogank9/kbe_godot_demo/master/screenshot4.png)
