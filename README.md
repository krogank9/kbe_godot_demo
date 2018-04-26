KBEngine Godot demo
=============

## This client-project is written for KBEngine (MMOG server engine)

http://www.kbengine.org

## Releases

	sources		: https://github.com/krogank9/kbe_godot_demo/releases/latest


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
![submodule_update1](http://www.kbengine.org/assets/img/screenshots/gitbash_submodule.png)

		* Or use TortoiseGit(menu): TortoiseGit -> Submodule Update:
![submodule_update2](http://www.kbengine.org/assets/img/screenshots/unity3d_plugins_submodule_update.jpg)

		* Or manually get the demo-assets(server)

			Download demo-assets(server):
				https://github.com/kbengine/kbengine_demos_assets/releases/latest
				unzip and copy to "kbengine/"  (The root directory server engine, such as $KBE_ROOT)

	3. Copy "kbengine_demos_assets" to "kbengine\" root directory
![demo_configure](http://www.kbengine.org/assets/img/screenshots/demo_copy_kbengine.jpg)


## Start the Servers:

	Ensure that the "kbengine_demos_assets" has been copied to the "kbengine\" directory
		Reference：Start

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
	(Build the client： Godot -> Project -> Export Linux/Mac/Windows.)


## Navmesh-navigation(Optional):
	
	The server to use recastnavigation navigation.
	Recastnavigation generated navigation mesh (Navmeshs) placed on the:
		kbengine\kbengine_demos_assets\res\spaces\*

	Generation Navmeshs:
		https://github.com/kbengine/unity3d_nav_critterai

# Plugin & Demo explanation:

### Plug-in:
	
Responsible for the handling of the network, establishing connection to 
the server, and sending/receiving binary data through TCP stream. 
Handles login/logout process. Creates/destroys entities upon
notification from the server, synchronizes their attributes, and allows 
for calling methods on equivalent base/cell entities on the server and 
allows the server to call methods on client entities. Provides an Event 
class for asynchronous communication with the plugin and KBE entities across multiple threads. Resides in the
kbe_plugin directory, and has KBEngine.gd set as a Singleton in 
Godot project settings.

### Godot demo:

Responsible for handling the rendering and user 
interaction layer. Defines entity client parts in the kbe_scripts 
directory (or its subdirectories), which is where the plugin looks
when creating entities via the servers command. `__init__()` and 
`onDestroy()` are called for notifications about entities lifecycles.
When defining client entities, "in" events (render -> plugin) are 
registered with the KBEngine.Event Singleton class in `__init__()`, and
fired "out" (plugin -> render) from entity methods to be received by the
render layer. 
	
### Directory structure:

	kbe_plugin/: KBE plugin script files
	kbe_plugin/KBEngine.gd: Set as Singleton which starts/manages plugin
	kbe_plugin/Args.gd: Modify to change KBE client settings
	
	kbe_scripts/: Contains all client entity definitions. Place all yours here
	kbe_scripts/Account.gd: Account client entity definition. Created on login
	kbe_scripts/Account.gd: Avatar client entity definition.
	kbe_scripts/Monster.gd: Monster client entity definition.
	kbe_scripts/GameObject.gd: GameObject interface, fires events on property change

	UI.gd:
	UI script, catches events thrown by kbe_scripts and built-in 
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
