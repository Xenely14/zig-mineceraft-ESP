# Zig-mineceraft-ESP
Open-source minecraft simple ESP created with `OpenGL` and `Detours` library.</br>

### Explanation
Minecraft uses `OpenGL` to render objects. Function `glTranslatef` and `glScalef` always calls with specific parameters before object will be rendered.
Using function interceptors (hooks) we can catch function call and modify it's behaviour (logic and input arguments).
Then filtering objects by function input parameters we can identify objects and save it's info into list, after all of this we can call `OpenGL` functions to render ESP-box above the object. 

### Building
- Download this repository
- Run `zig build` in root repository folder

### Usage
- Dowload and open dll-injector
- Find minecraft process and attach to it
- Inject `esp.dll` into game process

### Screenshots
![Alt image](https://cdn.discordapp.com/attachments/770327730570133524/1160191363980197949/image.png?ex=6533c368&is=65214e68&hm=b41c2eca0649dd708ee70edd1952d515074d34c596c7a978c854a36d24e66238&)
![Alt image](https://cdn.discordapp.com/attachments/770327730570133524/1160192241403428984/image.png?ex=6533c439&is=65214f39&hm=d7acb141e376649b12239d26269255a0d217a4dfbd4be72ec971502b755a89bf&)
- - -
Tested on x64 windows 10, 11</br>
Tested minecraft versions: 1.6.4, 1.7.10, 1.8.8</br>
Zig version: 0.12.0-dev.706+62a0fbdae

- - - 
P.S. WORKS ONLY IN x64 MODE.<br/>
Enspired by: https://github.com/Aurenex/Simple-ESP
